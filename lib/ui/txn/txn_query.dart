import '../../finance/finance.dart';
import 'txn_presentation.dart';

/// Type filter chips shared by History and Search.
enum TxnFilter {
  all('All'),
  income('Income'),
  expense('Expenses'),
  transfer('Transfers'),
  loan('Loans');

  const TxnFilter(this.label);
  final String label;

  bool matches(Txn t) => switch (this) {
        TxnFilter.all => true,
        TxnFilter.income => t.type == TxType.income || t.type == TxType.refund,
        TxnFilter.expense => t.type == TxType.expense,
        TxnFilter.transfer => const {TxType.transfer, TxType.cashWithdrawal, TxType.ccPayment, TxType.adjustment}
            .contains(t.type),
        TxnFilter.loan => t.type == TxType.loanRepayment || t.type == TxType.loanDisbursement,
      };
}

enum TxnRange {
  month,
  last30,
  all;

  /// The month chip reads 'October 2026' (or 'Asoj 2083').
  String label(IsoDate today, {MonthCalendar cal = const AdCalendar()}) => switch (this) {
        TxnRange.month => cal.monthYear(cal.key(today)),
        TxnRange.last30 => 'Last 30 days',
        TxnRange.all => 'All time',
      };

  bool contains(Txn t, IsoDate today, {MonthCalendar cal = const AdCalendar()}) => switch (this) {
        TxnRange.month => cal.key(t.date) == cal.key(today),
        TxnRange.last30 => daysBetween(today, t.date) <= 30,
        TxnRange.all => true,
      };
}

class DayGroup {
  const DayGroup({required this.date, required this.label, required this.items, required this.net});
  final IsoDate date;

  /// 'Today · 14 Oct 2026' or 'Sat · 10 Oct 2026' (shown upper-case).
  final String label;
  final List<Txn> items;

  /// Income and refunds minus spending (loan repayments: interest only).
  final Paisa net;
}

/// What a posted transaction adds to (+) or takes from (−) the day's net.
Paisa _netEffect(Txn t) {
  if (!t.isPosted) return 0;
  return switch (t.type) {
    TxType.income || TxType.refund => t.amount,
    TxType.expense => -t.amount,
    TxType.loanRepayment => -(t.interest ?? 0),
    _ => 0,
  };
}

String dayLabel(IsoDate date, IsoDate today, {MonthCalendar cal = const AdCalendar()}) {
  final rel = cal.relativeDay(date, today);
  final lead = rel == 'Today' || rel == 'Yesterday' ? rel : weekdayName(date);
  return '$lead · ${cal.longDate(date)}';
}

/// Groups newest-first transactions into consecutive days.
List<DayGroup> groupByDay(List<Txn> newestFirst, IsoDate today, {MonthCalendar cal = const AdCalendar()}) {
  final groups = <DayGroup>[];
  for (final t in newestFirst) {
    if (groups.isEmpty || groups.last.date != t.date) {
      groups.add(DayGroup(date: t.date, label: dayLabel(t.date, today, cal: cal), items: [t], net: _netEffect(t)));
    } else {
      final g = groups.removeLast();
      groups.add(DayGroup(date: g.date, label: g.label, items: [...g.items, t], net: g.net + _netEffect(t)));
    }
  }
  return groups;
}

/// "Money in" / "Money out" tiles. Out counts whole loan repayments, as
/// the mockup does: it is cash that left, even though only interest is spending.
(Paisa moneyIn, Paisa moneyOut) inOutTotals(Iterable<Txn> txns) {
  Paisa moneyIn = 0, moneyOut = 0;
  for (final t in txns.where((t) => t.isPosted)) {
    switch (t.type) {
      case TxType.income || TxType.refund:
        moneyIn += t.amount;
      case TxType.expense || TxType.loanRepayment:
        moneyOut += t.amount;
      default:
        break;
    }
  }
  return (moneyIn, moneyOut);
}

/// Search across title, category or income type, account, amount (whole
/// rupees, commas ignored) and type name. Empty query matches everything.
bool matchesQuery(Txn t, String query, TxnLookup lookup) {
  final q = query.trim().toLowerCase().replaceAll(',', '');
  if (q.isEmpty) return true;
  final hay = [
    t.title,
    if (t.categoryId != null) lookup.categoryName(t.categoryId),
    if (t.incomeTypeId != null) lookup.incomeTypeName(t.incomeTypeId),
    lookup.accountShort(t.accountId),
    if (t.counterAccountId != null) lookup.accountShort(t.counterAccountId),
    '${toWholeRupees(t.amount).abs()}',
    kTxTypeInfo[t.type]!.name,
  ].join(' ').toLowerCase();
  return hay.contains(q);
}
