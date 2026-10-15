import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/finance/finance.dart';

import 'data_fixtures.dart';
import 'test_db.dart';

void main() {
  late SettingsRepository repo;

  setUp(() {
    final db = openTestDb();
    repo = SettingsRepository(db, testAudit(db));
  });

  test('defaults when nothing is saved: lakh/AD/Night, no salary, sample deductions and tax rules, AI off', () async {
    expect((await repo.prefs()).grouping, Grouping.lakh);
    expect((await repo.salaryProfile()).grossMonthly, 0);
    expect((await repo.deductions()).map((d) => d.id), contains('ssf'));
    expect((await repo.taxRules()).isSampleDefault, isTrue);
    expect((await repo.security()).appLock, isFalse);
    expect((await repo.ai()).enabled, isFalse);
    expect((await repo.payoffPlan()).extraMonthly, 0);
  });

  test('saved settings are read back and streamed', () async {
    final stream = repo.watchPrefs();
    await repo.savePrefs(const AppPrefs(grouping: Grouping.international, calendar: CalendarPref.bs));
    expect((await repo.prefs()).calendar, CalendarPref.bs);
    expect((await stream.first).grouping, Grouping.international);
  });

  test('salary profile and deductions save and are audited', () async {
    await repo.saveSalaryProfile(SalaryProfile(employer: 'Acme', grossMonthly: fromRupees(80000)));
    final deds = await repo.deductions();
    await repo.saveDeductions([for (final d in deds) d.id == 'pf' ? d.copyWith(active: true) : d]);
    expect((await repo.salaryProfile()).employer, 'Acme');
    expect((await repo.deductions()).firstWhere((d) => d.id == 'pf').active, isTrue);
    expect(await auditSummaries(repo.db), containsAll(['Updated salary settings', 'Updated payroll deductions']));
  });

  test('tax rules with overlapping brackets are refused and nothing is saved', () async {
    final rules = sampleTaxRules();
    final bad = rules.withBrackets('individual', [
      TaxBracket(min: 0, max: fromRupees(500000), ratePct: 1),
      TaxBracket(min: fromRupees(400000), ratePct: 10),
    ]);
    await expectLater(repo.saveTaxRules(bad), throwsA(isA<TaxRulesInvalid>()));
    expect((await repo.taxRules()).categories['individual'], hasLength(6));
  });

  test('valid edited tax rules save and stop being sample defaults only when marked verified', () async {
    final rules = sampleTaxRules().withBrackets('individual', [
      TaxBracket(min: 0, max: fromRupees(600000), ratePct: 1),
      TaxBracket(min: fromRupees(600000), ratePct: 20),
    ]);
    await repo.saveTaxRules(rules);
    expect((await repo.taxRules()).categories['individual'], hasLength(2));
    expect((await repo.taxRules()).isSampleDefault, isTrue);
  });

  test('AI cache stores one analysis per month', () async {
    await repo.saveAiCache('2026-10', {'headline': 'Spending is up'});
    expect((await repo.aiCache('2026-10'))!['headline'], 'Spending is up');
    expect(await repo.aiCache('2026-09'), isNull);
  });
}
