import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/money.dart';
import 'package:paisa/finance/salary.dart';
import 'package:paisa/finance/sample_defaults.dart';
import 'package:paisa/finance/tax.dart';

SalaryBreakdown calc({List<Deduction>? deductions, TaxRuleSet? rules, String category = 'individual'}) =>
    computeSalary(
      grossMonthly: fromRupees(120000),
      basicPct: 60,
      deductions: deductions ?? sampleDeductions(),
      rules: rules ?? sampleTaxRules(),
      taxCategory: category,
    );

List<Deduction> toggled(String id, bool active) =>
    [for (final d in sampleDeductions()) d.id == id ? d.copyWith(active: active) : d];

void main() {
  test('golden: gross 1,20,000 → tax 13,791, take-home 92,789, employer SSF 14,400 (acceptance 8)', () {
    final b = calc();
    expect(b.basic, fromRupees(72000));
    expect(b.employeeTotal, fromRupees(7920 + 5000 + 500));
    expect(b.retirementMonthly, fromRupees(12920));
    expect(b.taxableAnnual, fromRupees(1284960));
    expect(toWholeRupees(b.monthlyTax), 13791);
    expect(toWholeRupees(b.takeHome), 92789);
    expect(b.employerLines.single.amount, fromRupees(14400));
    expect(b.costToCompany, fromRupees(120000 + 14400));
  });

  test('take-home entry applies no deductions (acceptance 8)', () {
    final b = SalaryBreakdown.fromTakeHome(fromRupees(92789));
    expect(b.enteredAsTakeHome, isTrue);
    expect(b.takeHome, fromRupees(92789));
    expect(b.employeeLines, isEmpty);
    expect(b.monthlyTax, 0);
  });

  test('turning income tax off removes only the tax', () {
    final b = calc(deductions: toggled('tax', false));
    expect(b.monthlyTax, 0);
    expect(b.takeHome, fromRupees(120000 - 13420));
  });

  test('without SSF the first slab is charged', () {
    final b = calc(deductions: toggled('ssf', false));
    expect(b.employeeLines.map((l) => l.deductionId), isNot(contains('ssf')));
    expect(toWholeRupees(b.monthlyTax), 16583);
    expect(toWholeRupees(b.takeHome), 97917);
  });

  test('editing a bracket rate recalculates the result (acceptance 9)', () {
    final rules = sampleTaxRules();
    final b = [...rules.categories['individual']!];
    b[3] = TaxBracket(min: b[3].min, max: b[3].max, ratePct: 25);
    expect(calc(rules: rules.withBrackets('individual', b)).takeHome, greaterThan(calc().takeHome));
  });

  test('couple brackets are used for the couple category', () {
    expect(toWholeRupees(calc(category: 'couple').monthlyTax), 11291);
  });

  test('an annual limit caps the monthly deduction', () {
    final deds = [
      for (final d in sampleDeductions()) d.id == 'cit' ? d.copyWith(annualLimit: fromRupees(36000)) : d,
    ];
    final cit = calc(deductions: deds).employeeLines.firstWhere((l) => l.deductionId == 'cit');
    expect(cit.amount, fromRupees(3000));
  });

  test('deductions outside their effective dates are skipped when asOf is given', () {
    final b = computeSalary(
      grossMonthly: fromRupees(120000), basicPct: 60, deductions: sampleDeductions(),
      rules: sampleTaxRules(), taxCategory: 'individual', asOf: '2026-07-01',
    );
    expect(b.employeeLines.map((l) => l.deductionId), isNot(contains('ssf')));
  });

  test('unknown taxpayer category is an argument error', () {
    expect(() => calc(category: 'company'), throwsArgumentError);
  });
}
