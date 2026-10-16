import 'dart:math' as math;

import 'budgets.dart';
import 'calendar.dart';
import 'catalog.dart';
import 'dates.dart';
import 'models.dart';
import 'money.dart';
import 'score.dart';
import 'totals.dart';

enum ChallengeTemplate {
  saveAmount('save_amount', 'Save an amount'),
  categoryCap('category_cap', 'Keep a category under'),
  noSpendDays('no_spend_days', 'No-spend days'),
  loanExtra('loan_extra', 'Pay extra on a loan'),
  categoryCut('category_cut', 'Cut a category vs last month');

  const ChallengeTemplate(this.wire, this.label);
  final String wire;
  final String label;
  static ChallengeTemplate fromWire(String w) => values.firstWhere((t) => t.wire == w);
}

enum ChallengeSource { user, suggested }

const kMaxActiveChallenges = 5;

/// One month's challenge (spec §4.3). [target] is paisa for amounts, a day
/// count for no-spend days, and a whole percent for a category cut.
class Challenge {
  const Challenge({
    required this.id,
    required this.template,
    required this.month,
    required this.target,
    this.categoryId,
    this.loanId,
    this.accepted = true,
    this.source = ChallengeSource.user,
  });

  final String id;
  final ChallengeTemplate template;
  final String month;
  final int target;
  final String? categoryId;
  final String? loanId;

  /// False while it is only a suggestion.
  final bool accepted;
  final ChallengeSource source;

  Challenge copyWith({int? target, bool? accepted, String? categoryId, String? loanId}) => Challenge(
        id: id,
        template: template,
        month: month,
        target: target ?? this.target,
        categoryId: categoryId ?? this.categoryId,
        loanId: loanId ?? this.loanId,
        accepted: accepted ?? this.accepted,
        source: source,
      );
}

class ChallengeProgress {
  const ChallengeProgress({required this.current, required this.target, required this.met});
  final int current;
  final int target;

  /// For a cap: still at or under the limit. Otherwise: reached the target.
  final bool met;
  double get ratio => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();
}

ChallengeProgress challengeProgress(Challenge c, Iterable<Txn> txs, Iterable<Loan> loans, IsoDate today) {
  final cal = calendarOf(c.month);
  final end = cal.key(today) == c.month ? today : cal.end(c.month);
  final inMonth = [for (final t in txs) if (t.isPosted && cal.key(t.date) == c.month && t.date.compareTo(end) <= 0) t];
  final totals = monthlyTotals(inMonth, c.month, cal: cal);
  switch (c.template) {
    case ChallengeTemplate.saveAmount:
      return ChallengeProgress(current: totals.surplus, target: c.target, met: totals.surplus >= c.target);
    case ChallengeTemplate.categoryCap:
      final spent = totals.byCategory[c.categoryId] ?? 0;
      return ChallengeProgress(current: spent, target: c.target, met: spent <= c.target);
    case ChallengeTemplate.noSpendDays:
      final spendDays = {for (final t in inMonth) if (t.type == TxType.expense) t.date};
      final free = cal.dayOf(end) - spendDays.length;
      return ChallengeProgress(current: free, target: c.target, met: free >= c.target);
    case ChallengeTemplate.loanExtra:
      final installment = loans.where((l) => l.id == c.loanId).firstOrNull?.installment ?? 0;
      final extra = inMonth
          .where((t) => t.type == TxType.loanRepayment && t.loanId == c.loanId)
          .fold<int>(0, (s, t) => s + math.max(0, t.amount - installment));
      return ChallengeProgress(current: extra, target: c.target, met: extra >= c.target);
    case ChallengeTemplate.categoryCut:
      final prev = monthlyTotals(txs.where((t) => t.isPosted), cal.shift(c.month, -1), cal: cal).byCategory[c.categoryId] ?? 0;
      final now = totals.byCategory[c.categoryId] ?? 0;
      final pct = prev <= 0 ? 0 : ((prev - now) * 100 / prev).floor();
      return ChallengeProgress(current: pct, target: c.target, met: prev > 0 && pct >= c.target);
  }
}

class ChallengeResult {
  const ChallengeResult(this.challenge, this.done);
  final Challenge challenge;
  final bool done;
}

enum BadgeId {
  firstChallenge('first_challenge', 'First challenge done'),
  streak3('streak_3', '3-month streak'),
  streak6('streak_6', '6-month streak'),
  firstLoanClosed('first_loan_closed', 'First loan closed'),
  emergencyFundFull('emergency_fund_full', 'Emergency fund full'),
  savingsRate3('savings_rate_3', 'Saved 20%+ for 3 months');

  const BadgeId(this.wire, this.label);
  final String wire;
  final String label;
  static BadgeId? fromWire(String w) => values.where((b) => b.wire == w).firstOrNull;
}

class ChallengeState {
  const ChallengeState({this.active = const [], this.history = const [], this.badges = const {}, this.lastSuggestedMonth});

  final List<Challenge> active;
  final List<ChallengeResult> history;
  final Set<BadgeId> badges;

  /// The month suggestions were last made for; they are made once a month.
  final String? lastSuggestedMonth;

  List<Challenge> acceptedIn(String month) => [for (final c in active) if (c.accepted && c.month == month) c];
  List<Challenge> suggestionsIn(String month) => [for (final c in active) if (!c.accepted && c.month == month) c];

  ChallengeState copyWith({
    List<Challenge>? active,
    List<ChallengeResult>? history,
    Set<BadgeId>? badges,
    String? lastSuggestedMonth,
  }) =>
      ChallengeState(
        active: active ?? this.active,
        history: history ?? this.history,
        badges: badges ?? this.badges,
        lastSuggestedMonth: lastSuggestedMonth ?? this.lastSuggestedMonth,
      );
}

/// Months in a row, ending last month, with at least one finished challenge.
/// A month finished in the other calendar counts for the month of [cal]
/// it ended in, so switching calendars keeps the streak.
int challengeStreak(List<ChallengeResult> history, String currentMonth) {
  final cal = calendarOf(currentMonth);
  final done = {
    for (final r in history)
      if (r.done) cal.key(calendarOf(r.challenge.month).end(r.challenge.month)),
  };
  var m = cal.shift(currentMonth, -1);
  var n = 0;
  while (done.contains(m)) {
    n++;
    m = cal.shift(m, -1);
  }
  return n;
}

/// Two suggestions for [today]'s month (spec §4.3).
List<Challenge> suggestChallenges(Iterable<Txn> txs, Iterable<ExpenseCategory> categories, IsoDate today, {MonthCalendar cal = const AdCalendar()}) {
  final month = cal.key(today);
  final posted = [for (final t in txs) if (t.isPosted) t];
  final last = monthlyTotals(posted, cal.shift(month, -1), cal: cal);
  final saveTarget = math.max(100000, (last.surplus * 1.1 / 10000).round() * 10000);
  final out = [
    Challenge(id: 'sugg-save-$month', template: ChallengeTemplate.saveAmount, month: month, target: saveTarget,
        accepted: false, source: ChallengeSource.suggested),
  ];
  final before = [
    monthlyTotals(posted, cal.shift(month, -2), cal: cal),
    monthlyTotals(posted, cal.shift(month, -3), cal: cal),
  ];
  ExpenseCategory? fastest;
  var growth = 0.0;
  for (final c in categories) {
    if (!c.active || !c.isTopLevel || c.isAutomatic) continue;
    final now = last.byCategory[c.id] ?? 0;
    if (now <= 0) continue;
    final g = now - before.fold<int>(0, (s, t) => s + (t.byCategory[c.id] ?? 0)) / 2;
    if (g > growth) {
      growth = g;
      fastest = c;
    }
  }
  if (fastest != null) {
    final budget = fastest.monthlyBudget ?? 0;
    out.add(Challenge(
      id: 'sugg-cat-$month',
      template: budget > 0 ? ChallengeTemplate.categoryCap : ChallengeTemplate.categoryCut,
      month: month,
      target: budget > 0 ? budget : 10,
      categoryId: fastest.id,
      accepted: false,
      source: ChallengeSource.suggested,
    ));
  }
  return out;
}

/// False when the challenge's category or loan has been deleted.
bool challengeTracked(Challenge c, Iterable<ExpenseCategory> categories, Iterable<Loan> loans) =>
    (c.categoryId == null || categories.any((x) => x.id == c.categoryId)) && (c.loanId == null || loans.any((l) => l.id == c.loanId));

/// Run on first open each day: finishes past months (unaccepted suggestions
/// and challenges whose category or loan was deleted are dropped, never
/// "missed"), adds this month's suggestions once, and awards badges.
ChallengeState rollOverChallenges(
  ChallengeState s, {
  required Iterable<Txn> txs,
  required Iterable<Loan> loans,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Account> accounts,
  required IsoDate today,
  MonthCalendar cal = const AdCalendar(),
}) {
  final month = cal.key(today);
  final keep = <Challenge>[];
  final finished = <ChallengeResult>[];
  for (final c in s.active) {
    if (!isMonthOf(c.month, cal)) {
      continue; // left over from the other calendar: dropped, never "missed"
    } else if (c.month.compareTo(month) >= 0) {
      keep.add(c);
    } else if (c.accepted && challengeTracked(c, categories, loans)) {
      finished.add(ChallengeResult(c, challengeProgress(c, txs, loans, cal.end(c.month)).met));
    }
  }
  var next = s.copyWith(active: keep, history: [...s.history, ...finished]);
  if (s.lastSuggestedMonth != month) {
    final have = {for (final c in keep) c.id};
    next = next.copyWith(
      active: [...keep, for (final c in suggestChallenges(txs, categories, today, cal: cal)) if (!have.contains(c.id)) c],
      lastSuggestedMonth: month,
    );
  }
  return next.copyWith(badges: _badges(next, txs: txs, loans: loans, categories: categories, accounts: accounts, today: today, cal: cal));
}

Set<BadgeId> _badges(
  ChallengeState s, {
  required Iterable<Txn> txs,
  required Iterable<Loan> loans,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Account> accounts,
  required IsoDate today,
  required MonthCalendar cal,
}) {
  final b = {...s.badges};
  if (s.history.any((r) => r.done)) b.add(BadgeId.firstChallenge);
  final streak = challengeStreak(s.history, cal.key(today));
  if (streak >= 3) b.add(BadgeId.streak3);
  if (streak >= 6) b.add(BadgeId.streak6);
  if (loans.any((l) => l.closed)) b.add(BadgeId.firstLoanClosed);
  final essential = categories.where((c) => c.active && c.essential && c.isTopLevel).fold<Paisa>(0, (t, c) => t + (c.monthlyBudget ?? 0));
  final saved = accounts.where((a) => !a.archived && a.group == AccountGroup.reserved).fold<Paisa>(0, (t, a) => t + a.balance);
  if (essential > 0 && emergencyFundMonths(essentialMonthly: essential, saved: saved) >= kEmergencyFundMonths) {
    b.add(BadgeId.emergencyFundFull);
  }
  final posted = [for (final t in txs) if (t.isPosted) t];
  final rates = [for (var k = 1; k <= 3; k++) monthlyTotals(posted, cal.shift(cal.key(today), -k), cal: cal)];
  if (rates.every((t) => t.income > 0 && t.savingsRate >= kTargetSavingsRate)) b.add(BadgeId.savingsRate3);
  return b;
}

/// True when an accepted save, no-spend or loan-extra challenge is already met.
bool challengeDoneThisMonth(ChallengeState s, Iterable<Txn> txs, Iterable<Loan> loans, IsoDate today,
        {MonthCalendar cal = const AdCalendar()}) =>
    s.acceptedIn(cal.key(today)).any((c) =>
        c.template != ChallengeTemplate.categoryCap &&
        c.template != ChallengeTemplate.categoryCut &&
        challengeProgress(c, txs, loans, today).met);
