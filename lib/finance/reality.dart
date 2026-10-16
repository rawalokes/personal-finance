import 'dart:math' as math;

import 'budgets.dart';
import 'calendar.dart';
import 'catalog.dart';
import 'dates.dart';
import 'loans.dart';
import 'models.dart';
import 'money.dart';
import 'networth.dart';
import 'nudges.dart';
import 'plan.dart';
import 'reports.dart';
import 'score.dart';
import 'totals.dart';
import 'waitlist.dart';

/// Honest money checks: habits, goals, "can I afford it?", budget plans
/// built from proven rules, and plan vs reality. Every number is computed
/// here; the AI only explains.

enum Level { good, watch, bad }

/// 22 working days × 8 hours: turns a price into hours of your work.
const kWorkHoursPerMonth = 176;

/// What a typical month looks like lately.
class Averages {
  const Averages({required this.income, required this.spending, required this.principal, required this.months, required this.byCategory});

  final Paisa income;

  /// Expenses + loan interest − refunds.
  final Paisa spending;

  /// Loan principal repaid: not spending, but not free cash either.
  final Paisa principal;

  /// How many months the average covers (0 = no data at all).
  final int months;
  final Map<String, Paisa> byCategory;

  Paisa get surplus => income - spending;

  /// What is really left to put aside after spending and loan principal.
  Paisa get cashLeft => income - spending - principal;
  double get savingsRate => income <= 0 ? 0 : surplus / income;

  /// What one hour of work earns; null without income.
  Paisa? get hourlyIncome => income <= 0 ? null : (income / kWorkHoursPerMonth).round();
}

/// The average of the last [months] complete months that have any income
/// or spending. With no history, this month so far stands in.
Averages monthlyAverages(Iterable<Txn> txs, IsoDate today, {MonthCalendar cal = const AdCalendar(), int months = 3}) {
  final posted = [for (final t in txs) if (t.isPosted) t];
  final current = cal.key(today);
  final earliest = posted.isEmpty ? current : posted.map((t) => cal.key(t.date)).reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  final picked = <String>[];
  bool hasData(MonthlyTotals m) => m.income != 0 || m.expenses != 0;
  for (var k = cal.shift(current, -1); picked.length < months && cal.start(k).compareTo(cal.start(earliest)) >= 0; k = cal.shift(k, -1)) {
    if (hasData(monthlyTotals(posted, k, cal: cal))) picked.add(k);
  }
  if (picked.isEmpty && hasData(monthlyTotals(posted, current, cal: cal))) picked.add(current);
  if (picked.isEmpty) return const Averages(income: 0, spending: 0, principal: 0, months: 0, byCategory: {});

  Paisa income = 0, spending = 0, principal = 0;
  final byCategory = <String, Paisa>{};
  for (final m in picked) {
    final t = monthlyTotals(posted, m, cal: cal);
    income += t.income;
    spending += t.expenses;
    t.byCategory.forEach((k, v) => byCategory[k] = (byCategory[k] ?? 0) + v);
  }
  for (final t in posted) {
    if (t.type == TxType.loanRepayment && picked.contains(cal.key(t.date))) {
      principal += t.principal ?? (t.amount - (t.interest ?? 0));
    }
  }
  final n = picked.length;
  return Averages(
    income: (income / n).round(),
    spending: (spending / n).round(),
    principal: (principal / n).round(),
    months: n,
    byCategory: {for (final e in byCategory.entries) e.key: (e.value / n).round()},
  );
}

// ─── Habits ──────────────────────────────────────────────────────────────

enum HabitKind {
  /// EMIs as a share of income (healthy ≤ 30%).
  emiLoad,

  /// All debt in months of income.
  debtSize,

  /// Kept from income (aim ≥ 20%).
  savingsRate,

  /// Cash left after spending and loan principal, as a share of income.
  afterEmis,

  /// Reserved savings in months of spending (aim 6).
  emergencyFund,

  /// Loan interest each month as a share of income.
  interest,
}

class HabitMetric {
  const HabitMetric(this.kind, this.value, this.level);
  final HabitKind kind;

  /// A ratio (0.3 = 30%) or months, depending on [kind].
  final double value;
  final Level level;
}

class HabitReport {
  const HabitReport({
    required this.averages,
    required this.metrics,
    required this.monthlyEmi,
    required this.totalDebt,
    required this.interestPerMonth,
    required this.debtFreeDate,
    required this.leaks,
    required this.overall,
  });

  final Averages averages;
  final List<HabitMetric> metrics;
  final Paisa monthlyEmi;

  /// Loans outstanding + credit card balances.
  final Paisa totalDebt;
  final Paisa interestPerMonth;

  /// When the last open loan is paid off at today's instalments; null with
  /// no loans or a loan that never gets repaid.
  final IsoDate? debtFreeDate;

  /// The biggest non-essential categories: (top-level category id, monthly).
  final List<(String, Paisa)> leaks;
  final Level overall;

  HabitMetric metric(HabitKind k) => metrics.firstWhere((m) => m.kind == k);
}

Level _upTo(double v, double good, double watch) => v <= good ? Level.good : v <= watch ? Level.watch : Level.bad;
Level _atLeast(double v, double good, double watch) => v >= good ? Level.good : v >= watch ? Level.watch : Level.bad;

List<Loan> _openLoans(Iterable<Loan> loans) => [for (final l in loans) if (!l.closed && l.outstanding > 0) l];

Paisa monthlyEmi(Iterable<Loan> loans) =>
    _openLoans(loans).fold<Paisa>(0, (s, l) => s + (l.installment / l.frequency.monthsPerPeriod).round());

String _topLevel(String id, Map<String, ExpenseCategory> byId) => byId[id]?.parentId ?? id;

HabitReport habitCheck({
  required Iterable<Txn> txs,
  required Iterable<Account> accounts,
  required Iterable<Loan> loans,
  required Iterable<ExpenseCategory> categories,
  required IsoDate today,
  MonthCalendar cal = const AdCalendar(),
}) {
  final a = monthlyAverages(txs, today, cal: cal);
  final open = _openLoans(loans);
  final emi = monthlyEmi(open);
  final balances = summarizeBalances(accounts, loans);
  final debt = balances.liabilities;
  final interest = open.fold<Paisa>(0, (s, l) => s + (periodInterest(l) / l.frequency.monthsPerPeriod).round());
  final income = a.income.toDouble();
  double share(Paisa v) => income <= 0 ? (v > 0 ? double.infinity : 0) : v / income;

  final fund = a.spending <= 0 ? (balances.reserved > 0 ? kEmergencyFundMonths.toDouble() : 0.0) : balances.reserved / a.spending;
  final metrics = [
    HabitMetric(HabitKind.emiLoad, share(emi), _upTo(share(emi), 0.30, 0.40)),
    HabitMetric(HabitKind.debtSize, share(debt), _upTo(share(debt), 6, 12)),
    HabitMetric(HabitKind.savingsRate, a.savingsRate, _atLeast(a.savingsRate, kTargetSavingsRate, 0.10)),
    HabitMetric(HabitKind.afterEmis, income <= 0 ? 0 : a.cashLeft / income, income <= 0 ? Level.watch : _atLeast(a.cashLeft / income, 0.10, 0)),
    HabitMetric(HabitKind.emergencyFund, fund, _atLeast(fund, kEmergencyFundMonths.toDouble(), 3)),
    HabitMetric(HabitKind.interest, share(interest), _upTo(share(interest), 0.05, 0.10)),
  ];

  IsoDate? debtFree;
  var never = false;
  for (final l in open) {
    if (l.installment <= 0) continue;
    final s = buildSchedule(l, maxRows: 0);
    if (s.neverRepaid || s.payoffDate == null) {
      never = true;
    } else if (debtFree == null || s.payoffDate!.compareTo(debtFree) > 0) {
      debtFree = s.payoffDate;
    }
  }

  final byId = {for (final c in categories) c.id: c};
  final rolled = <String, Paisa>{};
  a.byCategory.forEach((id, v) {
    final top = _topLevel(id, byId);
    rolled[top] = (rolled[top] ?? 0) + v;
  });
  final leaks = [
    for (final e in rolled.entries)
      if (e.value > 0 && byId[e.key] != null && !byId[e.key]!.essential && !byId[e.key]!.isAutomatic) (e.key, e.value),
  ]..sort((x, y) => y.$2.compareTo(x.$2));

  final bad = metrics.where((m) => m.level == Level.bad).length;
  final watch = metrics.where((m) => m.level == Level.watch).length;
  return HabitReport(
    averages: a,
    metrics: metrics,
    monthlyEmi: emi,
    totalDebt: debt,
    interestPerMonth: interest,
    debtFreeDate: never ? null : debtFree,
    leaks: leaks.take(3).toList(),
    overall: bad >= 2 ? Level.bad : (bad == 1 || watch >= 2) ? Level.watch : Level.good,
  );
}

// ─── Goals ───────────────────────────────────────────────────────────────

enum GoalVerdict { done, realistic, stretch, notRealistic, noDate }

class GoalCheck {
  const GoalCheck({
    required this.goal,
    required this.saved,
    required this.need,
    required this.available,
    required this.verdict,
    required this.monthsAtPace,
    required this.paceDate,
  });

  final Goal goal;
  final Paisa saved;

  /// Monthly saving the date asks for; null without a date.
  final Paisa? need;

  /// What is left each month for this goal after earlier goals.
  final Paisa available;
  final GoalVerdict verdict;

  /// Months to reach it at [available] a month; null when nothing is left.
  final int? monthsAtPace;
  final IsoDate? paceDate;

  Paisa get remaining => math.max(0, goal.target - saved);

  /// How much more a month the date needs than you can put aside.
  Paisa get shortBy => need == null ? 0 : math.max(0, need! - available);
}

/// Each goal against what you really put aside a month. Goals with the
/// nearest date take their share first.
List<GoalCheck> goalChecks({
  required Iterable<Goal> goals,
  required Iterable<Account> accounts,
  required Averages averages,
  required IsoDate today,
}) {
  final list = goals.toList();
  final order = [for (var k = 0; k < list.length; k++) k]..sort((x, y) {
      final a = list[x].targetDate, b = list[y].targetDate;
      if (a != b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      }
      return x.compareTo(y);
    });
  var pool = math.max(0, averages.cashLeft);
  final out = <int, GoalCheck>{};
  for (final k in order) {
    final g = list[k];
    final saved = goalSaved(g, accounts);
    final remaining = g.target - saved;
    final available = pool;
    int? months;
    if (remaining > 0 && available > 0) months = (remaining / available).ceil();
    final pace = months == null ? null : addMonths(today, months);
    if (remaining <= 0) {
      out[k] = GoalCheck(goal: g, saved: saved, need: 0, available: available, verdict: GoalVerdict.done, monthsAtPace: 0, paceDate: today);
      continue;
    }
    final need = recommendedMonthlySaving(target: g.target, current: saved, today: today, targetDate: g.targetDate);
    final GoalVerdict verdict;
    if (need == null) {
      verdict = GoalVerdict.noDate;
    } else {
      verdict = need <= available * 0.8
          ? GoalVerdict.realistic
          : need <= available
              ? GoalVerdict.stretch
              : GoalVerdict.notRealistic;
      pool -= math.min(need, pool);
    }
    out[k] = GoalCheck(goal: g, saved: saved, need: need, available: available, verdict: verdict, monthsAtPace: months, paceDate: pace);
  }
  return [for (var k = 0; k < list.length; k++) out[k]!];
}

// ─── Can I afford it? ────────────────────────────────────────────────────

enum AffordVerdict { yes, wait, no }

enum AffordReason {
  /// Under half of what is free to spend.
  fitsEasily,

  /// A need that fits in what is free.
  needFits,

  /// More than half of what is free this month.
  eatsMostOfFree,

  /// Would use money set aside for saving or EMIs.
  needsSavingsOrEmi,

  /// More than you have in spendable accounts.
  moreThanYouHave,
}

class AffordCheck {
  const AffordCheck({
    required this.price,
    required this.verdict,
    required this.reason,
    required this.freeToSpend,
    required this.youHave,
    required this.workHours,
    required this.futureValue10y,
    required this.goalName,
    required this.goalDelayDays,
    required this.monthsToSave,
    required this.suggestWaiting,
  });

  final Paisa price;
  final AffordVerdict verdict;
  final AffordReason reason;
  final Paisa freeToSpend;
  final Paisa youHave;

  /// Hours of work it costs; null without income history.
  final double? workHours;

  /// What the money grows to in 10 years at 8% if kept instead.
  final Paisa futureValue10y;

  /// The nearest unfinished goal and how many days this pushes it back.
  final String? goalName;
  final int? goalDelayDays;

  /// Months of saving it takes when it doesn't fit now; null if never.
  final int? monthsToSave;

  /// A want big enough for the 24-hour rule.
  final bool suggestWaiting;

  double get shareOfFree => freeToSpend <= 0 ? double.infinity : price / freeToSpend;
}

AffordCheck canAfford({
  required Paisa price,
  required MonthPlan plan,
  required Averages averages,
  required Iterable<Goal> goals,
  required Iterable<Account> accounts,
  required IsoDate today,
  bool essential = false,
}) {
  final free = plan.freeToSpend;
  final (verdict, reason) = price > plan.youHave
      ? (AffordVerdict.no, AffordReason.moreThanYouHave)
      : price > free
          ? (AffordVerdict.no, AffordReason.needsSavingsOrEmi)
          : essential
              ? (AffordVerdict.yes, AffordReason.needFits)
              : price > free / 2
                  ? (AffordVerdict.wait, AffordReason.eatsMostOfFree)
                  : (AffordVerdict.yes, AffordReason.fitsEasily);

  final hourly = averages.hourlyIncome;
  final open = [for (final g in goals) if (goalSaved(g, accounts) < g.target) g]
    ..sort((a, b) => (a.targetDate ?? '9999').compareTo(b.targetDate ?? '9999'));
  final goal = open.firstOrNull;
  final perDay = averages.cashLeft / 30;
  return AffordCheck(
    price: price,
    verdict: verdict,
    reason: reason,
    freeToSpend: free,
    youHave: plan.youHave,
    workHours: hourly == null || hourly <= 0 ? null : price / hourly,
    futureValue10y: (price * math.pow(1.08, 10)).round(),
    goalName: goal?.name,
    goalDelayDays: goal == null || perDay <= 0 ? null : (price / perDay).round(),
    monthsToSave: verdict == AffordVerdict.yes || averages.cashLeft <= 0 ? null : (price / averages.cashLeft).ceil(),
    suggestWaiting: verdict != AffordVerdict.no && shouldSuggestWaiting(amount: price, essential: essential),
  );
}

// ─── Budget plans ────────────────────────────────────────────────────────

enum BudgetMethod {
  /// 50% needs (EMIs included), 30% wants, 20% saved.
  fiftyThirtyTwenty,

  /// Every rupee gets a job: needs as they are, wants −15%, the rest saved
  /// (30% of it to costly debt when there is any).
  zeroBased,

  /// Avalanche: needs as they are, wants −30%, 10% saved, everything else
  /// to the loan with the highest rate.
  debtFirst,
}

class PlanLine {
  const PlanLine({required this.categoryId, required this.essential, required this.current, required this.suggested});
  final String categoryId;
  final bool essential;

  /// Average monthly spending lately.
  final Paisa current;
  final Paisa suggested;
}

class BudgetPlan {
  const BudgetPlan({
    required this.method,
    required this.income,
    required this.emis,
    required this.save,
    required this.extraDebt,
    required this.extraDebtLoanId,
    required this.lines,
  });

  final BudgetMethod method;
  final Paisa income;
  final Paisa emis;
  final Paisa save;
  final Paisa extraDebt;
  final String? extraDebtLoanId;
  final List<PlanLine> lines;

  Paisa get needs => lines.where((l) => l.essential).fold(0, (s, l) => s + l.suggested);
  Paisa get wants => lines.where((l) => !l.essential).fold(0, (s, l) => s + l.suggested);
}

const _hundred = 10000; // NPR 100 in paisa
Paisa _roundUp(num v) => (v / _hundred).ceil() * _hundred;
Paisa _roundDown(num v) => (v / _hundred).floor() * _hundred;

/// Interest at or above this is "costly debt" worth paying off early.
const double kCostlyRatePct = 12;

BudgetPlan buildBudgetPlan({
  required BudgetMethod method,
  required Averages averages,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Loan> loans,
}) {
  final income = averages.income;
  final open = _openLoans(loans);
  final emis = monthlyEmi(open);
  if (income <= 0) {
    return BudgetPlan(method: method, income: 0, emis: emis, save: 0, extraDebt: 0, extraDebtLoanId: null, lines: const []);
  }
  final byId = {for (final c in categories) c.id: c};
  final spent = <String, Paisa>{};
  averages.byCategory.forEach((id, v) {
    final top = _topLevel(id, byId);
    final c = byId[top];
    if (c == null || c.isAutomatic || !c.active) return;
    spent[top] = (spent[top] ?? 0) + v;
  });
  for (final c in categories) {
    if (c.isTopLevel && c.active && !c.isAutomatic && (c.monthlyBudget ?? 0) > 0) spent.putIfAbsent(c.id, () => 0);
  }
  final ids = spent.keys.toList()..sort((a, b) => spent[b]!.compareTo(spent[a]!));
  final needsNow = ids.where((id) => byId[id]!.essential).fold<Paisa>(0, (s, id) => s + spent[id]!);
  final wantsNow = ids.where((id) => !byId[id]!.essential).fold<Paisa>(0, (s, id) => s + spent[id]!);

  final wantsScale = switch (method) {
    BudgetMethod.fiftyThirtyTwenty => wantsNow <= 0 ? 1.0 : math.min(1.0, income * 0.3 / wantsNow),
    BudgetMethod.zeroBased => 0.85,
    BudgetMethod.debtFirst => 0.70,
  };
  // 50/30/20 trims needs too when they and the EMIs pass half of income,
  // but never below 90% of what they really cost.
  final needsScale = method == BudgetMethod.fiftyThirtyTwenty && needsNow > 0
      ? math.max(0.9, math.min(1.0, (income * 0.5 - emis) / needsNow))
      : 1.0;
  final lines = [
    for (final id in ids)
      PlanLine(
        categoryId: id,
        essential: byId[id]!.essential,
        current: spent[id]!,
        suggested: byId[id]!.essential ? _roundUp(spent[id]! * needsScale) : _roundDown(spent[id]! * wantsScale),
      ),
  ];
  final left = income - emis - lines.fold<Paisa>(0, (s, l) => s + l.suggested);
  final costly = [for (final l in open) if ((l.ratePct ?? 0) >= kCostlyRatePct) l]..sort((a, b) => (b.ratePct ?? 0).compareTo(a.ratePct ?? 0));
  final highest = [...open]..sort((a, b) => (b.ratePct ?? 0).compareTo(a.ratePct ?? 0));

  Paisa save, extra;
  String? loanId;
  switch (method) {
    case BudgetMethod.fiftyThirtyTwenty:
      save = math.max(0, left);
      extra = 0;
    case BudgetMethod.zeroBased:
      if (costly.isNotEmpty && left > 0) {
        extra = _roundDown(left * 0.3);
        loanId = costly.first.id;
      } else {
        extra = 0;
      }
      save = math.max(0, left - extra);
    case BudgetMethod.debtFirst:
      save = math.max(0, math.min(_roundDown(income * 0.1), left));
      extra = math.max(0, left - save);
      if (highest.isEmpty) {
        save += extra;
        extra = 0;
      } else if (extra > 0) {
        loanId = highest.first.id;
      }
  }
  return BudgetPlan(method: method, income: income, emis: emis, save: save, extraDebt: extra, extraDebtLoanId: loanId, lines: lines);
}

/// Debt first when EMIs, debt or interest are a problem; 50/30/20 when
/// saving is under 20%; otherwise zero-based to put the surplus to work.
BudgetMethod recommendedMethod(HabitReport h) {
  if (h.metric(HabitKind.emiLoad).value > 0.30 || h.metric(HabitKind.debtSize).level == Level.bad || h.metric(HabitKind.interest).level == Level.bad) {
    return BudgetMethod.debtFirst;
  }
  if (h.averages.savingsRate < kTargetSavingsRate) return BudgetMethod.fiftyThirtyTwenty;
  return BudgetMethod.zeroBased;
}

// ─── Plan vs reality ─────────────────────────────────────────────────────

enum FixKind { cutCategory, saveFirst, payEmi, setBudgets }

class ReviewFix {
  const ReviewFix(this.kind, {this.categoryId, this.amount = 0});
  final FixKind kind;
  final String? categoryId;
  final Paisa amount;
}

class MonthReview {
  const MonthReview({
    required this.month,
    required this.complete,
    required this.fraction,
    required this.income,
    required this.spent,
    required this.saveTarget,
    required this.budgets,
    required this.emisPaid,
    required this.emisExpected,
    required this.verdict,
    required this.fixes,
  });

  final String month;
  final bool complete;

  /// Share of the month gone (1 for a finished month).
  final double fraction;
  final Paisa income;
  final Paisa spent;
  final Paisa saveTarget;
  final List<BudgetLine> budgets;
  final int emisPaid;
  final int emisExpected;
  final Level verdict;
  final List<ReviewFix> fixes;

  Paisa get saved => income - spent;

  /// Where saving should be by now.
  Paisa get expectedSaved => (saveTarget * fraction).round();
  int get budgetsOver => budgets.where((b) => b.spent > b.limit).length;
  int get emisMissed => complete ? math.max(0, emisExpected - emisPaid) : 0;
}

MonthReview monthReview({
  required Iterable<Txn> txs,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Loan> loans,
  required Iterable<Goal> goals,
  required Iterable<Account> accounts,
  required String month,
  required IsoDate today,
  MonthCalendar cal = const AdCalendar(),
}) {
  final posted = [for (final t in txs) if (t.isPosted) t];
  final complete = cal.end(month).compareTo(today) < 0;
  final fraction = complete ? 1.0 : (cal.dayOf(today) / cal.daysIn(month)).clamp(0.0, 1.0);
  final now = monthlyTotals(posted, month, cal: cal);
  final last = monthlyTotals(posted, cal.shift(month, -1), cal: cal);
  final income = complete ? now.income : math.max(now.income, last.income);
  final goalsNeed = goals.fold<Paisa>(0, (s, g) {
    final need = recommendedMonthlySaving(target: g.target, current: goalSaved(g, accounts), today: today, targetDate: g.targetDate);
    return s + (need ?? 0);
  });
  final target = math.max((income * kTargetSavingsRate).round(), goalsNeed);

  final monthly = [for (final l in _openLoans(loans)) if (l.installment > 0 && l.frequency.monthsPerPeriod == 1) l];
  final paidIds = {
    for (final t in posted)
      if (t.type == TxType.loanRepayment && t.loanId != null && cal.key(t.date) == month) t.loanId!,
  };
  final paid = monthly.where((l) => paidIds.contains(l.id)).length;
  final budgets = budgetPerformance(posted, categories, month, cal: cal);

  final saved = now.surplus;
  final expected = (target * fraction).round();
  final over = [for (final b in budgets) if (b.spent > b.limit) b]..sort((a, b) => (b.spent - b.limit).compareTo(a.spent - a.limit));
  final missed = complete ? monthly.length - paid : 0;

  final fixes = <ReviewFix>[
    for (final b in over.take(3)) ReviewFix(FixKind.cutCategory, categoryId: b.categoryId, amount: b.spent - b.limit),
    if (target > 0 && saved < expected) ReviewFix(FixKind.saveFirst, amount: target - math.max(0, saved)),
    if (missed > 0) ReviewFix(FixKind.payEmi, amount: missed),
    if (budgets.isEmpty) const ReviewFix(FixKind.setBudgets),
  ];
  final Level verdict;
  if (saved < expected * 0.5 || over.length >= 2 || missed > 0) {
    verdict = Level.bad;
  } else if (saved < expected || over.isNotEmpty) {
    verdict = Level.watch;
  } else {
    verdict = Level.good;
  }
  return MonthReview(
    month: month,
    complete: complete,
    fraction: fraction,
    income: now.income,
    spent: now.expenses,
    saveTarget: target,
    budgets: budgets,
    emisPaid: paid,
    emisExpected: monthly.length,
    verdict: verdict,
    fixes: fixes,
  );
}
