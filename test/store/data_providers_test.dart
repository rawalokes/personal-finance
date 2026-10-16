import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/store/salary_settings.dart';

import '../data/data_fixtures.dart';
import '../data/sample_data.dart';
import '../data/test_db.dart';

/// Riverpod 3 pauses providers nobody listens to, so a test listens before
/// awaiting a provider's future.
void keepAlive(ProviderContainer c, List<ProviderListenable<Object?>> providers) {
  for (final p in providers) {
    final sub = c.listen(p, (_, _) {});
    addTearDown(sub.close);
  }
}

Future<ProviderContainer> seededContainer() async {
  final db = openTestDb();
  await seedWithSampleData(db);
  return ProviderContainer.test(overrides: [
    initialPrefsProvider.overrideWithValue(const AppPrefs(calendar: CalendarPref.ad)),
    databaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(testClock),
    idGenProvider.overrideWithValue(counterIds()),
  ]);
}

void main() {
  test('balance summary and month totals come from the seeded database', () async {
    final c = await seededContainer();
    keepAlive(c, [balanceSummaryProvider, monthTotalsProvider]);
    final summary = await c.read(balanceSummaryProvider.future);
    expect(summary.availableToSpend, fromRupees(184020));
    final oct = await c.read(monthTotalsProvider.future);
    expect(oct.income, fromRupees(26240));
  });

  test('a repository write flows through to the derived providers', () async {
    final c = await seededContainer();
    keepAlive(c, [balanceSummaryProvider, monthTotalsProvider]);
    await c.read(balanceSummaryProvider.future);
    await c.read(transactionRepoProvider).add(
          const Txn(
            id: 'n1', date: '2026-10-14', time: '10:30', title: 'Tea', type: TxType.expense,
            accountId: 'cash', categoryId: 'other', amount: 50000,
          ),
          summary: 'x',
        );
    await pumpEventQueue();
    expect((await c.read(balanceSummaryProvider.future)).availableToSpend, fromRupees(184020 - 500));
    expect((await c.read(monthTotalsProvider.future)).byCategory['other'], fromRupees(500));
  });

  test('sample salary settings give spec §13 test 8 take-home of 92,789', () async {
    final c = await seededContainer();
    keepAlive(c, [salarySettingsProvider]);
    final s = await c.read(salarySettingsProvider.future);
    expect(toWholeRupees(s.breakdown(s.grossMonthly, asOf: '2026-10-14').takeHome), 92789);
  });
}
