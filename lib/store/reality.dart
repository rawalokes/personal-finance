import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/records.dart';
import '../data/repos/catalog_repo.dart';
import '../finance/finance.dart';
import '../integrations/gemini/schemas.dart';
import 'ai.dart';
import 'data_providers.dart';
import 'reports.dart';
import 'ui_state.dart';

/// Reality checks (habits, goals, plan vs reality, budget plans) computed
/// from the same inputs as Reports.

final averagesProvider = FutureProvider<Averages>((ref) async {
  final i = await ref.watch(reportInputsProvider.future);
  return monthlyAverages(i.txs, ref.watch(clockProvider).today(), cal: ref.watch(monthCalendarProvider));
});

final habitReportProvider = FutureProvider<HabitReport>((ref) async {
  final i = await ref.watch(reportInputsProvider.future);
  return habitCheck(
    txs: i.txs,
    accounts: i.accounts,
    loans: i.loans,
    categories: i.categories,
    today: ref.watch(clockProvider).today(),
    cal: ref.watch(monthCalendarProvider),
  );
});

final goalChecksProvider = FutureProvider<List<GoalCheck>>((ref) async {
  final i = await ref.watch(reportInputsProvider.future);
  return goalChecks(goals: i.goals, accounts: i.accounts, averages: await ref.watch(averagesProvider.future), today: ref.watch(clockProvider).today());
});

/// Plan vs reality for this month (0) or an earlier one (-1 = last month).
final monthReviewProvider = FutureProvider.family<MonthReview, int>((ref, offset) async {
  final i = await ref.watch(reportInputsProvider.future);
  final today = ref.watch(clockProvider).today();
  final cal = ref.watch(monthCalendarProvider);
  return monthReview(
    txs: i.txs,
    categories: i.categories,
    loans: i.loans,
    goals: i.goals,
    accounts: i.accounts,
    month: cal.shift(cal.key(today), offset),
    today: today,
    cal: cal,
  );
});

final recommendedMethodProvider = FutureProvider<BudgetMethod>((ref) async => recommendedMethod(await ref.watch(habitReportProvider.future)));

final budgetPlanProvider = FutureProvider.family<BudgetPlan, BudgetMethod>((ref, method) async {
  final i = await ref.watch(reportInputsProvider.future);
  return buildBudgetPlan(method: method, averages: await ref.watch(averagesProvider.future), categories: i.categories, loans: i.loans);
});

/// This month's cached AI answer for a topic (never makes a request).
/// Keyed by (topic, scope); see [AiService.reality].
final cachedRealityProvider = FutureProvider.family<RealityAnswer?, (RealityTopic, String?)>((ref, key) async {
  ref.watch(aiSettingsProvider);
  return ref.watch(aiServiceProvider).cachedReality(key.$1, scope: key.$2);
});

/// Sets each line of [plan] as its category's monthly budget. Returns how
/// many budgets were set.
Future<int> applyBudgetPlan(CatalogRepository repo, BudgetPlan plan) async {
  for (final l in plan.lines) {
    await repo.setBudget(l.categoryId, l.suggested, actor: AuditActor.user);
  }
  return plan.lines.length;
}

// ─── Facts for the AI (whole rupees, verdicts as words) ─────────────────

int _npr(Paisa p) => toWholeRupees(p);
double _pct(double v) => v.isFinite ? (v * 1000).round() / 10 : -1;

Map<String, Object?> averagesFacts(Averages a) => {
      'monthsAveraged': a.months,
      'incomeNpr': _npr(a.income),
      'spendingNpr': _npr(a.spending),
      'loanPrincipalNpr': _npr(a.principal),
      'cashLeftNpr': _npr(a.cashLeft),
      'savingsRatePct': _pct(a.savingsRate),
    };

Map<String, Object?> habitFacts(HabitReport h, {Map<String, String> names = const {}}) => {
      'overall': h.overall.name,
      'monthlyAverage': averagesFacts(h.averages),
      'monthlyEmiNpr': _npr(h.monthlyEmi),
      'totalDebtNpr': _npr(h.totalDebt),
      'interestPerMonthNpr': _npr(h.interestPerMonth),
      'debtFreeDate': h.debtFreeDate,
      'metrics': [
        for (final m in h.metrics)
          {'kind': m.kind.name, 'value': m.kind == HabitKind.debtSize || m.kind == HabitKind.emergencyFund ? m.value : _pct(m.value), 'level': m.level.name},
      ],
      'biggestLeaks': [for (final l in h.leaks) {'category': names[l.$1] ?? l.$1, 'monthlyNpr': _npr(l.$2)}],
    };

Map<String, Object?> goalFacts(List<GoalCheck> goals, Averages a) => {
      'monthlyAverage': averagesFacts(a),
      'goals': [
        for (final g in goals)
          {
            'name': g.goal.name,
            'verdict': g.verdict.name,
            'targetNpr': _npr(g.goal.target),
            'savedNpr': _npr(g.saved),
            'targetDate': g.goal.targetDate,
            'needPerMonthNpr': g.need == null ? null : _npr(g.need!),
            'availablePerMonthNpr': _npr(g.available),
            'shortByPerMonthNpr': _npr(g.shortBy),
            'dateAtCurrentPace': g.paceDate,
          },
      ],
    };

Map<String, Object?> reviewFacts(MonthReview r, {Map<String, String> names = const {}}) => {
      'month': r.month,
      'finished': r.complete,
      'shareOfMonthGonePct': _pct(r.fraction),
      'verdict': r.verdict.name,
      'incomeNpr': _npr(r.income),
      'spentNpr': _npr(r.spent),
      'savedNpr': _npr(r.saved),
      'saveTargetNpr': _npr(r.saveTarget),
      'shouldHaveSavedByNowNpr': _npr(r.expectedSaved),
      'emisPaid': r.emisPaid,
      'emisExpected': r.emisExpected,
      'budgets': [
        for (final b in r.budgets) {'category': names[b.categoryId] ?? b.categoryId, 'limitNpr': _npr(b.limit), 'spentNpr': _npr(b.spent)},
      ],
      'suggestedFixes': [
        for (final f in r.fixes)
          {'kind': f.kind.name, 'category': f.categoryId == null ? null : names[f.categoryId] ?? f.categoryId, 'amountNpr': f.kind == FixKind.payEmi ? null : _npr(f.amount)},
      ],
    };

Map<String, Object?> budgetFacts(BudgetPlan p, {Map<String, String> names = const {}}) => {
      'method': p.method.name,
      'incomeNpr': _npr(p.income),
      'emisNpr': _npr(p.emis),
      'saveNpr': _npr(p.save),
      'extraDebtNpr': _npr(p.extraDebt),
      'lines': [
        for (final l in p.lines)
          {'category': names[l.categoryId] ?? l.categoryId, 'essential': l.essential, 'nowNpr': _npr(l.current), 'planNpr': _npr(l.suggested)},
      ],
    };

Map<String, Object?> affordFacts(String item, AffordCheck c, {bool essential = false}) => {
      'item': item,
      'need': essential,
      'priceNpr': _npr(c.price),
      'verdict': c.verdict.name,
      'reason': c.reason.name,
      'freeToSpendThisMonthNpr': _npr(c.freeToSpend),
      'inSpendableAccountsNpr': _npr(c.youHave),
      'hoursOfWork': c.workHours == null ? null : (c.workHours! * 10).round() / 10,
      'worthIn10YearsAt8PctNpr': _npr(c.futureValue10y),
      'nearestGoal': c.goalName,
      'delaysGoalByDays': c.goalDelayDays,
      'monthsToSaveForIt': c.monthsToSave,
    };
