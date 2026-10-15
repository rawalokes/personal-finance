import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finance.dart';

/// What Add income needs to turn a gross salary into take-home.
class SalarySettings {
  const SalarySettings({
    required this.employer,
    required this.grossMonthly,
    required this.basicPct,
    required this.taxCategory,
    required this.deductions,
    required this.rules,
  });

  final String employer;
  final Paisa grossMonthly;
  final double basicPct;
  final String taxCategory;
  final List<Deduction> deductions;
  final TaxRuleSet rules;

  SalaryBreakdown breakdown(Paisa gross, {IsoDate? asOf}) => computeSalary(
        grossMonthly: gross,
        basicPct: basicPct,
        deductions: deductions,
        rules: rules,
        taxCategory: taxCategory,
        asOf: asOf,
      );
}

/// Spec §12 salary with the sample deductions and FY 2083/84 sample tax
/// rules. Plan 4 (Salary & deductions) replaces this body with the saved
/// salary profile.
final salarySettingsProvider = Provider<SalarySettings>(
  (ref) => SalarySettings(
    employer: 'Himal Tech Pvt. Ltd.',
    grossMonthly: fromRupees(120000),
    basicPct: 60,
    taxCategory: 'individual',
    deductions: sampleDeductions(),
    rules: sampleTaxRules(),
  ),
);
