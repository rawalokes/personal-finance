import 'dart:math' as math;

import 'budgets.dart';
import 'calendar.dart';
import 'catalog.dart';
import 'dates.dart';
import 'models.dart';
import 'money.dart';
import 'payoff.dart';
import 'reports.dart';
import 'totals.dart';

/// Declaration order is priority: the first kinds show first (spec §4.1).
enum NudgeKind {
  emiDue('emi_due', 'EMI reminders'),
  budgetPace('budget_pace', 'Budget pace'),
  categorySpike('category_spike', 'Spending spikes'),
  loanExtra('loan_extra', 'Pay loans off sooner'),
  payeeRepeat('payee_repeat', 'Repeat payments'),
  surplusToGoal('surplus_to_goal', 'Save last month’s surplus'),
  emergencyFund('emergency_fund', 'Emergency fund'),
  praise('praise', 'Praise');

  const NudgeKind(this.wire, this.label);
  final String wire;
  final String label;
  static NudgeKind? fromWire(String w) => values.where((k) => k.wire == w).firstOrNull;
}

class Nudge {
  const Nudge({
    required this.id,
    required this.kind,
    required this.topic,
    required this.title,
    required this.body,
    this.actionLabel,
    this.route,
  });

  /// Stable for one topic in one month (or one due date), so a dismissal sticks.
  final String id;
  final NudgeKind kind;

  /// What it is about: 'cat:food', 'loan:L1', 'party:p1', 'goal:g1', 'emergency', 'praise'.
  final String topic;
  final String title;
  final String body;
  final String? actionLabel;
  final String? route;
}

class NudgeInput {
  const NudgeInput({
    required this.today,
    required this.txs,
    required this.accounts,
    required this.categories,
    required this.loans,
    required this.goals,
    this.parties = const {},
    this.challengeDoneThisMonth = false,
  });

  final IsoDate today;
  final Iterable<Txn> txs;
  final Iterable<Account> accounts;
  final Iterable<ExpenseCategory> categories;
  final Iterable<Loan> loans;
  final Iterable<Goal> goals;

  /// Party id → name (Settings → Parties).
  final Map<String, String> parties;
  final bool challengeDoneThisMonth;
}

/// What a goal has saved: its linked account's balance, else contributions.
Paisa goalSaved(Goal g, Iterable<Account> accounts) =>
    accounts.where((a) => a.id == g.linkedAccountId).firstOrNull?.balance ?? g.current;

String _q(String s) => Uri.encodeQueryComponent(s);

/// Every nudge that applies today, highest priority first, at most one per
/// topic, without dismissed (until ≥ today) or disabled kinds.
List<Nudge> buildNudges(
  NudgeInput i,
  MoneyFormat money, {
  Map<String, IsoDate> dismissed = const {},
  Set<NudgeKind> disabled = const {},
  MonthCalendar cal = const AdCalendar(),
}) {
  final today = i.today;
  final month = cal.key(today);
  final day = cal.dayOf(today);
  final dim = cal.daysIn(month);
  final daysLeft = dim - day;
  final posted = [for (final t in i.txs) if (t.isPosted) t];
  final thisMonth = monthlyTotals(posted, month, cal: cal);
  final lastKey = cal.shift(month, -1);
  final last = monthlyTotals(posted, lastKey, cal: cal);
  final names = {for (final c in i.categories) c.id: c.name};
  final all = <Nudge>[];

  // EMI due within 3 days.
  for (final l in i.loans) {
    final due = l.nextDueDate;
    if (l.closed || l.outstanding <= 0 || due == null) continue;
    final d = daysBetween(due, today);
    if (d < 0 || d > 3) continue;
    final when = d == 0 ? 'today' : d == 1 ? 'tomorrow' : 'in $d days';
    final acct = i.accounts.where((a) => a.id == l.repaymentAccountId).firstOrNull;
    final body = acct == null
        ? 'Keep ${money.npr(l.installment)} ready.'
        : acct.balance >= l.installment
            ? '${acct.shortName} has enough to cover it.'
            : '${acct.shortName} is short by ${money.npr(l.installment - acct.balance)}.';
    all.add(Nudge(
      id: 'emi_due:${l.id}:$due',
      kind: NudgeKind.emiDue,
      topic: 'loan:${l.id}',
      title: '${l.name} EMI of ${money.npr(l.installment)} due $when',
      body: body,
      actionLabel: 'Open loan',
      route: '/loans/${l.id}',
    ));
  }

  // Budget pace.
  for (final b in budgetPerformance(posted, i.categories, month, cal: cal)) {
    final projected = (b.spent * dim / day).round();
    if (b.ratio < kBudgetWarnRatio && projected <= b.limit) continue;
    final name = names[b.categoryId] ?? 'Budget';
    final body = b.remaining <= 0
        ? 'Over budget by ${money.npr(-b.remaining)}.'
        : daysLeft == 0
            ? '${money.npr(b.remaining)} left for today.'
            : '$daysLeft days left — ${money.npr(b.remaining ~/ daysLeft)} a day keeps you on budget.';
    all.add(Nudge(
      id: 'budget_pace:${b.categoryId}:$month',
      kind: NudgeKind.budgetPace,
      topic: 'cat:${b.categoryId}',
      title: b.ratio >= kBudgetWarnRatio ? '$name: ${(b.ratio * 100).round()}% of budget used' : '$name is on pace to go over budget',
      body: body,
      actionLabel: 'Open budget',
      route: '/plans?seg=budgets',
    ));
  }

  // Category spike vs the pro-rated 3-month average.
  final previous = [for (var k = 1; k <= 3; k++) monthlyTotals(posted, cal.shift(month, -k), cal: cal)];
  for (final c in i.categories) {
    if (!c.active || !c.isTopLevel || c.isAutomatic) continue;
    // Average the months that have spending, so a new user isn't compared
    // with empty months.
    final months = [for (final t in previous) if ((t.byCategory[c.id] ?? 0) > 0) t.byCategory[c.id]!];
    if (months.isEmpty) continue;
    final avg = months.reduce((a, b) => a + b) / months.length;
    final now = thisMonth.byCategory[c.id] ?? 0;
    final expected = avg * day / dim;
    final diff = now - expected;
    if (diff < 0.25 * expected || diff < 100000) continue;
    all.add(Nudge(
      id: 'category_spike:${c.id}:$month',
      kind: NudgeKind.categorySpike,
      topic: 'cat:${c.id}',
      title: '${c.name} is ${money.npr(diff.round())} above your 3-month average',
      body: 'So far this month: ${money.npr(now)}. You usually spend about ${money.npr(expected.round())} by now.',
      actionLabel: 'See transactions',
      route: '/search?q=${_q(c.name)}',
    ));
  }

  // Pay a loan off sooner with part of last month's surplus.
  if (last.surplus > 0) {
    final extra = math.max(50000, (last.surplus / 10 / 50000).round() * 50000);
    for (final l in i.loans) {
      if (l.closed || l.outstanding <= 0 || l.method == InterestMethod.none || (l.ratePct ?? 0) <= 0) continue;
      final cmp = comparePayoff([l], extraMonthly: extra);
      if (cmp.plan.hitLimit || cmp.monthsSaved < 1) continue;
      all.add(Nudge(
        id: 'loan_extra:${l.id}:$month',
        kind: NudgeKind.loanExtra,
        topic: 'loan:${l.id}',
        title: 'Pay ${money.npr(extra)} extra a month on ${l.name}',
        body: 'Done ${cmp.monthsSaved} ${cmp.monthsSaved == 1 ? 'month' : 'months'} sooner, '
            '${money.npr(cmp.interestSaved)} less interest.',
        actionLabel: 'Plan payoff',
        route: '/loans/planner?extra=${toWholeRupees(extra)}',
      ));
    }
  }

  // Three or more payments to one party in 7 days.
  final weekStart = toIsoDate(parseIsoDate(today).subtract(const Duration(days: 6)));
  final byParty = <String, List<Txn>>{};
  for (final t in posted) {
    final p = t.partyId;
    if (t.type != TxType.expense || p == null || t.date.compareTo(weekStart) < 0 || t.date.compareTo(today) > 0) continue;
    (byParty[p] ??= []).add(t);
  }
  byParty.forEach((p, list) {
    if (list.length < 3) return;
    final name = i.parties[p] ?? 'one payee';
    all.add(Nudge(
      id: 'payee_repeat:$p:$month',
      kind: NudgeKind.payeeRepeat,
      topic: 'party:$p',
      title: '${list.length} payments to $name this week',
      body: '${money.npr(list.fold<Paisa>(0, (s, t) => s + t.amount))} in the last 7 days.',
      actionLabel: 'See payments',
      route: '/search?q=${_q(name)}',
    ));
  });

  // Last month's surplus → an unfinished goal.
  if (last.surplus > 0) {
    final goal = i.goals.where((g) => goalSaved(g, i.accounts) < g.target).firstOrNull;
    if (goal != null) {
      all.add(Nudge(
        id: 'surplus_to_goal:${goal.id}:$month',
        kind: NudgeKind.surplusToGoal,
        topic: 'goal:${goal.id}',
        title: 'You kept ${money.npr(last.surplus)} last month',
        body: 'Move some of it to ${goal.name} before it gets spent.',
        actionLabel: 'Open goals',
        route: '/plans?seg=goals',
      ));
    }
  }

  // Emergency fund below 6 months of essential budgets.
  final essential = i.categories
      .where((c) => c.active && c.essential && c.isTopLevel)
      .fold<Paisa>(0, (s, c) => s + (c.monthlyBudget ?? 0));
  if (essential > 0) {
    final saved = i.accounts.where((a) => !a.archived && a.group == AccountGroup.reserved).fold<Paisa>(0, (s, a) => s + a.balance);
    final months = emergencyFundMonths(essentialMonthly: essential, saved: saved);
    if (months < kEmergencyFundMonths) {
      all.add(Nudge(
        id: 'emergency_fund:$month',
        kind: NudgeKind.emergencyFund,
        topic: 'emergency',
        title: 'Your emergency fund covers ${months.toStringAsFixed(1)} of $kEmergencyFundMonths months',
        body: 'Aim for ${money.npr(emergencyFundTarget(essential))} in savings accounts.',
        actionLabel: 'Open goals',
        route: '/plans?seg=goals',
      ));
    }
  }

  // Praise.
  final lastSamePoint = monthlyTotals([for (final t in posted) if (cal.dayOf(t.date) <= day) t], lastKey, cal: cal).expenses;
  if (lastSamePoint > 0 && thisMonth.expenses <= lastSamePoint * 0.9) {
    final pct = ((1 - thisMonth.expenses / lastSamePoint) * 100).round();
    all.add(Nudge(
      id: 'praise:spend:$month',
      kind: NudgeKind.praise,
      topic: 'praise',
      title: 'You’ve spent $pct% less than last month 🎉',
      body: 'Same point last month: ${money.npr(lastSamePoint)}. Keep it going.',
    ));
  } else if (i.challengeDoneThisMonth) {
    all.add(Nudge(
      id: 'praise:challenge:$month',
      kind: NudgeKind.praise,
      topic: 'praise',
      title: 'Challenge complete 🎉',
      body: 'Nice work — see your streak in Plans → Challenges.',
      actionLabel: 'See challenges',
      route: '/plans?seg=challenges',
    ));
  }

  final out = <Nudge>[];
  final topics = <String>{};
  for (final kind in NudgeKind.values) {
    for (final n in all.where((n) => n.kind == kind)) {
      if (disabled.contains(n.kind)) continue;
      final until = dismissed[n.id];
      if (until != null && until.compareTo(today) >= 0) continue;
      if (!topics.add(n.topic)) continue;
      out.add(n);
    }
  }
  return out;
}
