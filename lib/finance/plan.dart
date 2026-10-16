import 'dart:math' as math;

import 'budgets.dart';
import 'calendar.dart';
import 'catalog.dart';
import 'loans.dart';
import 'dates.dart';
import 'models.dart';
import 'money.dart';
import 'networth.dart';
import 'nudges.dart';
import 'reports.dart';
import 'score.dart';
import 'totals.dart';

/// This month at a glance for Home: what to save, what to repay, how the
/// budgets are doing, and what is really free to spend.
class MonthPlan {
  const MonthPlan({
    required this.month,
    required this.daysLeft,
    required this.saveTarget,
    required this.saved,
    required this.behindBy,
    required this.emiLeft,
    required this.emisPaid,
    required this.emisDue,
    required this.nextDue,
    required this.budgetsSet,
    required this.budgetsOver,
    required this.closestBudget,
    required this.youHave,
    required this.netWorth,
    required this.interestThisMonth,
  });

  /// Month key in the chosen calendar.
  final String month;
  final int daysLeft;

  /// 0 = no target (no income and no goals).
  final Paisa saveTarget;

  /// Kept so far this month (income − spending), never below 0.
  final Paisa saved;

  /// How far short of where you should be by today; negative = ahead.
  final Paisa behindBy;

  /// EMIs still to pay this month (including overdue ones).
  final Paisa emiLeft;
  final int emisPaid;
  final int emisDue;

  /// Earliest unpaid due date (may be overdue), or null.
  final IsoDate? nextDue;

  final int budgetsSet;
  final int budgetsOver;

  /// The budget nearest its limit that isn't over yet: (category id, ratio).
  final (String, double)? closestBudget;

  /// Money in spendable accounts.
  final Paisa youHave;
  final Paisa netWorth;

  /// What the open loans cost in interest this month (spec: loss framing).
  final Paisa interestThisMonth;

  Paisa get saveLeft => math.max(0, saveTarget - saved);

  /// What you have after setting aside the rest of the savings target and
  /// the EMIs still due. Negative = short.
  Paisa get freeToSpend => youHave - saveLeft - emiLeft;
}

MonthPlan monthPlan({
  required Iterable<Txn> txs,
  required Iterable<Account> accounts,
  required Iterable<Loan> loans,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Goal> goals,
  required IsoDate today,
  MonthCalendar cal = const AdCalendar(),
}) {
  final month = cal.key(today);
  final dim = cal.daysIn(month);
  final day = cal.dayOf(today);
  final posted = [for (final t in txs) if (t.isPosted) t];
  final now = monthlyTotals(posted, month, cal: cal);
  final last = monthlyTotals(posted, cal.shift(month, -1), cal: cal);

  // Savings: 20% of income, or what the goals need, whichever is more.
  final income = math.max(now.income, last.income);
  final rateTarget = (income * kTargetSavingsRate).round();
  final goalsNeed = goals.fold<Paisa>(0, (s, g) {
    final need = recommendedMonthlySaving(target: g.target, current: goalSaved(g, accounts), today: today, targetDate: g.targetDate);
    return s + (need ?? 0);
  });
  final target = math.max(rateTarget, goalsNeed);
  final saved = math.max(0, now.surplus);
  final behind = target == 0 ? 0 : (target * day / dim).round() - saved;

  // EMIs: paid this month, or due this month / overdue and not paid yet.
  final open = [for (final l in loans) if (!l.closed && l.outstanding > 0 && l.installment > 0) l];
  bool paid(Loan l) => posted.any((t) => t.type == TxType.loanRepayment && t.loanId == l.id && cal.key(t.date) == month);
  final paidLoans = open.where(paid).toList();
  final dueUnpaid = [
    for (final l in open)
      if (!paid(l) && l.nextDueDate != null && l.nextDueDate!.compareTo(cal.end(month)) <= 0) l,
  ]..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));

  // Budgets.
  final lines = budgetPerformance(posted, categories, month, cal: cal);
  final under = [for (final b in lines) if (b.spent <= b.limit && b.limit > 0) b]..sort((a, b) => b.ratio.compareTo(a.ratio));

  final balances = summarizeBalances(accounts, loans);
  return MonthPlan(
    month: month,
    daysLeft: dim - day,
    saveTarget: target,
    saved: saved,
    behindBy: behind,
    emiLeft: dueUnpaid.fold<Paisa>(0, (s, l) => s + l.installment),
    emisPaid: paidLoans.length,
    emisDue: paidLoans.length + dueUnpaid.length,
    nextDue: dueUnpaid.firstOrNull?.nextDueDate,
    budgetsSet: lines.length,
    budgetsOver: lines.where((b) => b.spent > b.limit).length,
    closestBudget: under.isEmpty ? null : (under.first.categoryId, under.first.ratio),
    youHave: balances.availableToSpend,
    netWorth: balances.netWorth,
    interestThisMonth: open.fold<Paisa>(0, (s, l) => s + (periodInterest(l) / l.frequency.monthsPerPeriod).round()),
  );
}

/// What saving [monthly] every month for [years] grows to at [annualRate]
/// (compounded monthly) — "future you".
Paisa futureValue({required Paisa monthly, required int years, double annualRate = 0.08}) {
  if (monthly <= 0 || years <= 0) return 0;
  final r = annualRate / 12;
  final n = years * 12;
  return (monthly * (math.pow(1 + r, n) - 1) / r).round();
}
