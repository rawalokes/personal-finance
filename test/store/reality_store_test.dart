import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/store/learn.dart';
import 'package:paisa/store/reality.dart';
import 'package:paisa/store/reports.dart';

import 'data_providers_test.dart' show keepAlive, seededContainer;

void main() {
  test('habits, goals and the month reviews load from the sample data', () async {
    final c = await seededContainer();
    keepAlive(c, [habitReportProvider, goalChecksProvider, monthReviewProvider(0), monthReviewProvider(-1)]);
    final h = await c.read(habitReportProvider.future);
    expect(h.metrics, hasLength(HabitKind.values.length));
    expect(h.monthlyEmi, greaterThan(0), reason: 'the sample has loans');
    final goals = await c.read(goalChecksProvider.future);
    expect(goals, isA<List<GoalCheck>>(), reason: 'the sample has no goals yet');
    final now = await c.read(monthReviewProvider(0).future);
    expect((now.month, now.complete), ('2026-10', false));
    final last = await c.read(monthReviewProvider(-1).future);
    expect((last.month, last.complete), ('2026-09', true));
  });

  test('facts sent to the AI are in whole rupees with the verdicts', () async {
    final c = await seededContainer();
    keepAlive(c, [habitReportProvider, monthPlanProvider]);
    final h = await c.read(habitReportProvider.future);
    final f = habitFacts(h);
    expect(f['monthlyEmiNpr'], toWholeRupees(h.monthlyEmi));
    expect((f['metrics'] as List).first, containsPair('level', isA<String>()));
    final plan = await c.read(monthPlanProvider.future);
    final check = canAfford(price: fromRupees(6500), plan: plan, averages: h.averages, goals: const [], accounts: const [], today: '2026-10-14');
    final a = affordFacts('Perfume', check);
    expect(a, containsPair('item', 'Perfume'));
    expect(a, containsPair('priceNpr', 6500));
    expect(a, containsPair('verdict', check.verdict.name));
  });

  test('applying a budget plan sets every line as the category budget', () async {
    final c = await seededContainer();
    keepAlive(c, [budgetPlanProvider(BudgetMethod.fiftyThirtyTwenty), categoriesProvider]);
    final plan = await c.read(budgetPlanProvider(BudgetMethod.fiftyThirtyTwenty).future);
    expect(plan.lines, isNotEmpty);
    final n = await applyBudgetPlan(c.read(catalogRepoProvider), plan);
    expect(n, plan.lines.length);
    await pumpEventQueue();
    final cats = {for (final x in await c.read(categoriesProvider.future)) x.id: x};
    for (final l in plan.lines) {
      expect(cats[l.categoryId]!.monthlyBudget, l.suggested);
    }
  });

  test('wishes are added with a priority, and the priority can change', () async {
    final c = await seededContainer();
    keepAlive(c, [waitListProvider]);
    final ctl = c.read(waitListControllerProvider);
    await ctl.addWish(title: 'Perfume', amount: fromRupees(6500), priority: 1);
    var w = await c.read(settingsRepoProvider).waitList();
    expect((w.wishes.single.title, w.wishes.single.priority), ('Perfume', 1));
    expect(w.waiting, isEmpty);
    await ctl.setPriority(w.wishes.single.id, 3);
    w = await c.read(settingsRepoProvider).waitList();
    expect(w.wishes.single.priority, 3);
  });
}
