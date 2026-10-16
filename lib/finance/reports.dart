import 'budgets.dart';
import 'catalog.dart';
import 'dates.dart';
import 'loans.dart';
import 'models.dart';
import 'money.dart';
import 'networth.dart';
import 'payoff.dart';
import 'totals.dart';

/// Periods a dashboard widget can show (spec §3.2).
enum ReportPeriod {
  thisMonth('this_month', 'This month'),
  lastMonth('last_month', 'Last month'),
  last3m('last_3m', '3 months'),
  last6m('last_6m', '6 months'),
  last12m('last_12m', '12 months'),
  thisFy('this_fy', 'This fiscal year');

  const ReportPeriod(this.wire, this.label);
  final String wire;
  final String label;
  static ReportPeriod fromWire(String w) => values.firstWhere((p) => p.wire == w, orElse: () => thisMonth);
}

/// An inclusive range of calendar days.
class DateRange {
  const DateRange(this.start, this.end);
  final IsoDate start;
  final IsoDate end;

  bool contains(IsoDate d) => d.compareTo(start) >= 0 && d.compareTo(end) <= 0;

  /// 'YYYY-MM' keys from [start]'s month to [end]'s month.
  List<String> get months {
    final out = <String>[];
    var m = firstOfMonth(start);
    while (monthKey(m).compareTo(monthKey(end)) <= 0) {
      out.add(monthKey(m));
      m = addMonths(m, 1);
    }
    return out;
  }

  @override
  bool operator ==(Object other) => other is DateRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => 'DateRange($start, $end)';
}

IsoDate firstOfMonth(IsoDate d) => '${monthKey(d)}-01';

IsoDate lastOfMonth(String month) =>
    toIsoDate(DateTime.utc(int.parse(month.substring(0, 4)), int.parse(month.substring(5, 7)) + 1, 0));

int daysInMonthOf(IsoDate d) => parseIsoDate(lastOfMonth(monthKey(d))).day;

/// [fyStart] is the first day of the current Nepali fiscal year (1 Shrawan).
DateRange resolvePeriod(ReportPeriod p, IsoDate today, {required IsoDate fyStart}) {
  final first = firstOfMonth(today);
  final prev = addMonths(first, -1);
  return switch (p) {
    ReportPeriod.thisMonth => DateRange(first, today),
    ReportPeriod.lastMonth => DateRange(prev, lastOfMonth(monthKey(prev))),
    ReportPeriod.last3m => DateRange(addMonths(first, -2), today),
    ReportPeriod.last6m => DateRange(addMonths(first, -5), today),
    ReportPeriod.last12m => DateRange(addMonths(first, -11), today),
    ReportPeriod.thisFy => DateRange(fyStart, today),
  };
}

/// The range with the same number of months just before [r] ("compare").
DateRange previousRange(DateRange r) => DateRange(
      addMonths(firstOfMonth(r.start), -r.months.length),
      toIsoDate(parseIsoDate(r.start).subtract(const Duration(days: 1))),
    );

enum PointKind { actual, forecast }

class ReportPoint {
  const ReportPoint(this.label, this.value, this.kind);
  final String label;
  final Paisa value;
  final PointKind kind;
}

class ReportSlice {
  const ReportSlice(this.id, this.label, this.value);
  final String id;
  final String label;
  final Paisa value;
}

class CashFlowPoint {
  const CashFlowPoint(this.month, this.income, this.expenses, this.kind);
  final String month;
  final Paisa income;
  final Paisa expenses;
  final PointKind kind;
  Paisa get net => income - expenses;
}

/// Posted transactions in [r], on [accountIds] (empty = all).
List<Txn> _inRange(Iterable<Txn> txs, DateRange r, Set<String> accountIds) => [
      for (final t in txs)
        if (t.isPosted && r.contains(t.date) && (accountIds.isEmpty || accountIds.contains(t.accountId))) t,
    ];

int _perMonth(Paisa amount, RecurringFrequency f) => switch (f) {
      RecurringFrequency.monthly => amount,
      RecurringFrequency.quarterly => (amount / 3).round(),
      RecurringFrequency.yearly => (amount / 12).round(),
    };

/// A typical future month: active recurring rules plus loan interest
/// (principal is not spending, spec §5).
({Paisa income, Paisa expenses}) monthlyForecast(Iterable<RecurringRule> recurring, Iterable<Loan> loans) {
  Paisa income = 0;
  Paisa expenses = 0;
  for (final r in recurring) {
    if (!r.active) continue;
    if (r.kind == RecurringKind.income) {
      income += _perMonth(r.amount, r.frequency);
    } else {
      expenses += _perMonth(r.amount, r.frequency);
    }
  }
  for (final l in loans) {
    if (l.closed || l.outstanding <= 0) continue;
    expenses += (periodInterest(l) / l.frequency.monthsPerPeriod).round();
  }
  return (income: income, expenses: expenses);
}

/// Money in and out per month; when [r] ends in [today]'s month, the next
/// [forecastMonths] are added as forecast (Ruling R1).
List<CashFlowPoint> cashFlow(
  Iterable<Txn> txs,
  DateRange r, {
  Set<String> accountIds = const {},
  Iterable<RecurringRule> recurring = const [],
  Iterable<Loan> loans = const [],
  IsoDate? today,
  int forecastMonths = 3,
}) {
  final inRange = _inRange(txs, r, accountIds);
  final out = <CashFlowPoint>[];
  for (final m in r.months) {
    final t = monthlyTotals(inRange, m);
    out.add(CashFlowPoint(m, t.income, t.expenses, PointKind.actual));
  }
  if (today != null && monthKey(r.end) == monthKey(today)) {
    final f = monthlyForecast(recurring, loans);
    for (var i = 1; i <= forecastMonths; i++) {
      out.add(CashFlowPoint(monthKey(addMonths(firstOfMonth(today), i)), f.income, f.expenses, PointKind.forecast));
    }
  }
  return out;
}

List<ReportSlice> _sorted(List<ReportSlice> s) => s..sort((a, b) => b.value.compareTo(a.value));

List<ReportSlice> spendingByCategory(
  Iterable<Txn> txs,
  DateRange r,
  Iterable<ExpenseCategory> categories, {
  Set<String> accountIds = const {},
  Set<String> categoryIds = const {},
}) {
  final byId = {for (final c in categories) c.id: c};
  String top(String id) {
    var c = byId[id];
    while (c != null && c.parentId != null && byId[c.parentId] != null) {
      c = byId[c.parentId];
    }
    return c?.id ?? id;
  }

  final inRange = _inRange(txs, r, accountIds);
  final sums = <String, Paisa>{};
  for (final m in r.months) {
    monthlyTotals(inRange, m).byCategory.forEach((id, v) => sums[top(id)] = (sums[top(id)] ?? 0) + v);
  }
  String label(String id) => byId[id]?.name ?? (id == kLoanInterestCategoryId ? 'Loan interest' : 'Uncategorised');
  return _sorted([
    for (final e in sums.entries)
      if (e.value > 0 && (categoryIds.isEmpty || categoryIds.contains(e.key))) ReportSlice(e.key, label(e.key), e.value),
  ]);
}

enum IncomeGrouping { type, party }

/// Slice id for income with no party set.
const kNoParty = 'no_party';

List<ReportSlice> incomeBySource(
  Iterable<Txn> txs,
  DateRange r, {
  required IncomeGrouping groupBy,
  Iterable<IncomeType> incomeTypes = const [],
  Map<String, String> parties = const {},
  Set<String> accountIds = const {},
}) {
  final names = {for (final t in incomeTypes) t.id: t.name};
  final sums = <String, Paisa>{};
  for (final t in _inRange(txs, r, accountIds)) {
    if (t.type != TxType.income) continue;
    final key = groupBy == IncomeGrouping.type ? (t.incomeTypeId ?? kUncategorised) : (t.partyId ?? kNoParty);
    sums[key] = (sums[key] ?? 0) + t.amount;
  }
  String label(String k) => groupBy == IncomeGrouping.type ? (names[k] ?? 'Other income') : (parties[k] ?? 'No party set');
  return _sorted([for (final e in sums.entries) ReportSlice(e.key, label(e.key), e.value)]);
}

/// How one posted transaction changed net worth (Ruling R4).
Paisa netWorthEffect(Txn t) => switch (t.type) {
      TxType.income => t.amount,
      TxType.expense => -t.amount,
      TxType.refund => t.amount,
      TxType.loanRepayment => -(t.interest ?? 0),
      TxType.adjustment => t.amount,
      _ => 0,
    };

/// Net worth at each month end in [r] (today for the current month).
List<ReportPoint> netWorthSeries(
  Iterable<Account> accounts,
  Iterable<Loan> loans,
  Iterable<Txn> txs,
  DateRange r,
  IsoDate today,
) {
  final now = summarizeBalances(accounts, loans).netWorth;
  final posted = [for (final t in txs) if (t.isPosted) t];
  final out = <ReportPoint>[];
  for (final m in r.months) {
    final end = monthKey(today) == m ? today : lastOfMonth(m);
    final later = posted.where((t) => t.date.compareTo(end) > 0).fold<Paisa>(0, (s, t) => s + netWorthEffect(t));
    out.add(ReportPoint(m, now - later, PointKind.actual));
  }
  return out;
}

/// Budgeted top-level categories for [month], as the Budgets screen counts them.
List<BudgetLine> budgetPerformance(
  Iterable<Txn> txs,
  Iterable<ExpenseCategory> categories,
  String month, {
  Set<String> categoryIds = const {},
}) {
  final totals = monthlyTotals(txs, month);
  return [
    for (final c in categories)
      if (c.active && c.isTopLevel && (c.monthlyBudget ?? 0) > 0 && (categoryIds.isEmpty || categoryIds.contains(c.id)))
        BudgetLine(categoryId: c.id, limit: c.monthlyBudget!, spent: totals.byCategory[c.id] ?? 0),
  ];
}

class LoanProgress {
  const LoanProgress({required this.loan, required this.repaidRatio, required this.monthsLeft});
  final Loan loan;
  final double repaidRatio;

  /// Null when the installment never repays it.
  final int? monthsLeft;
}

List<LoanProgress> loanProgress(Iterable<Loan> loans, {Set<String> loanIds = const {}}) => [
      for (final l in loans)
        if (!l.closed && l.outstanding > 0 && (loanIds.isEmpty || loanIds.contains(l.id)))
          () {
            final sim = simulatePayoff([l]);
            return LoanProgress(
              loan: l,
              repaidRatio: l.principal > 0 ? ((l.principal - l.outstanding) / l.principal).clamp(0.0, 1.0).toDouble() : 0,
              monthsLeft: sim.hitLimit ? null : sim.months,
            );
          }(),
    ];

List<ReportPoint> interestPaid(Iterable<Txn> txs, DateRange r, {Set<String> loanIds = const {}}) {
  final sums = {for (final m in r.months) m: 0};
  for (final t in txs) {
    if (!t.isPosted || t.type != TxType.loanRepayment || !r.contains(t.date)) continue;
    if (loanIds.isNotEmpty && !loanIds.contains(t.loanId)) continue;
    final m = monthKey(t.date);
    sums[m] = (sums[m] ?? 0) + (t.interest ?? 0);
  }
  return [for (final e in sums.entries) ReportPoint(e.key, e.value, PointKind.actual)];
}

class SavingsPoint {
  const SavingsPoint(this.month, this.rate, this.saved, this.cumulative);
  final String month;
  final double rate;
  final Paisa saved;
  final Paisa cumulative;
}

List<SavingsPoint> savingsSeries(Iterable<Txn> txs, DateRange r, {Set<String> accountIds = const {}}) {
  final inRange = _inRange(txs, r, accountIds);
  var cumulative = 0;
  final out = <SavingsPoint>[];
  for (final m in r.months) {
    final t = monthlyTotals(inRange, m);
    cumulative += t.surplus;
    out.add(SavingsPoint(m, t.savingsRate, t.surplus, cumulative));
  }
  return out;
}

/// Parties you paid the most (expenses with a party set).
List<ReportSlice> topPayees(
  Iterable<Txn> txs,
  DateRange r,
  Map<String, String> parties, {
  Set<String> accountIds = const {},
  int limit = 5,
}) {
  final sums = <String, Paisa>{};
  for (final t in _inRange(txs, r, accountIds)) {
    final p = t.partyId;
    if (t.type != TxType.expense || p == null) continue;
    sums[p] = (sums[p] ?? 0) + t.amount;
  }
  return _sorted([for (final e in sums.entries) ReportSlice(e.key, parties[e.key] ?? 'Removed party', e.value)]).take(limit).toList();
}
