import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/finance/finance.dart';

void main() {
  test('preferences round-trip and default to lakh, Bikram Sambat, Night, balances shown', () {
    const d = AppPrefs();
    expect(d.grouping, Grouping.lakh);
    expect(d.calendar, CalendarPref.bs);
    expect(d.theme, ThemePref.dark);
    expect(d.hideBalances, isFalse);
    const p = AppPrefs(grouping: Grouping.international, calendar: CalendarPref.bs, theme: ThemePref.light, hideBalances: true);
    final back = AppPrefs.fromJson(p.toJson());
    expect(back.grouping, Grouping.international);
    expect(back.calendar, CalendarPref.bs);
    expect(back.theme, ThemePref.light);
    expect(back.hideBalances, isTrue);
  });

  test('salary profile round-trips; a clean profile has no employer or gross', () {
    expect(const SalaryProfile().grossMonthly, 0);
    final p = SalaryProfile(employer: 'Himal Tech', grossMonthly: fromRupees(120000), basicPct: 60, taxCategory: 'couple');
    final back = SalaryProfile.fromJson(p.toJson());
    expect(back.employer, 'Himal Tech');
    expect(back.grossMonthly, fromRupees(120000));
    expect(back.basicPct, 60);
    expect(back.taxCategory, 'couple');
  });

  test('deductions round-trip with every field the engine uses', () {
    final list = sampleDeductions();
    final back = deductionsFromJson(deductionsToJson(list));
    expect(back, hasLength(list.length));
    final ssf = back.firstWhere((d) => d.id == 'ssf');
    expect(ssf.method, CalcMethod.percent);
    expect(ssf.rate, 11);
    expect(ssf.base, SalaryBase.basic);
    expect(ssf.retirementDeductible, isTrue);
    expect(ssf.scheme, DeductionScheme.ssf);
    expect(back.firstWhere((d) => d.id == 'pf').active, isFalse);
    expect(back.firstWhere((d) => d.id == 'cit').amount, fromRupees(5000));
  });

  test('tax rules round-trip, open-ended last bracket included, and still compute 92,789', () {
    final rules = taxRulesFromJson(taxRulesToJson(sampleTaxRules()));
    expect(rules.isSampleDefault, isTrue);
    expect(rules.categories['individual']!.last.max, isNull);
    expect(rules.categories['individual']!.first.condition, 'Social security tax');
    final s = computeSalary(
      grossMonthly: fromRupees(120000), basicPct: 60, deductions: sampleDeductions(), rules: rules,
      taxCategory: 'individual', asOf: '2026-10-14',
    );
    expect(toWholeRupees(s.takeHome), 92789);
  });

  test('security, AI settings and payoff plan round-trip with safe defaults', () {
    expect(const SecuritySettings().appLock, isFalse);
    final sec = SecuritySettings.fromJson(const SecuritySettings(appLock: true, blockScreenshots: true).toJson());
    expect(sec.appLock, isTrue);
    expect(sec.autoLock, isTrue);
    expect(sec.blockScreenshots, isTrue);

    const ai = AiSettings();
    expect(ai.enabled, isFalse, reason: 'AI is off by default (spec §9.2)');
    expect(ai.privacy, AiPrivacy.summaries);
    final aiBack = AiSettings.fromJson(
      const AiSettings(enabled: true, model: 'models/x-flash', privacy: AiPrivacy.merchants, monthlyLimit: 50).toJson(),
    );
    expect(aiBack.model, 'models/x-flash');
    expect(aiBack.privacy, AiPrivacy.merchants);
    expect(aiBack.monthlyLimit, 50);

    final plan = PayoffPlanSettings.fromJson(
      PayoffPlanSettings(extraMonthly: fromRupees(5000), strategy: PayoffStrategy.snowball, savedAt: '2026-10-14').toJson(),
    );
    expect(plan.extraMonthly, fromRupees(5000));
    expect(plan.strategy, PayoffStrategy.snowball);
  });

  test('corrupt settings fail loudly instead of silently resetting', () {
    expect(() => AppPrefs.fromJson({'grouping': 'weird'}), throwsFormatException);
    expect(() => taxRulesFromJson({'id': 'x'}), throwsFormatException);
  });
}
