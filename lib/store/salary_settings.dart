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

/// A clean install knows no employer or salary yet; the FY 2083/84 sample
/// deductions and tax rules (labelled as samples in the UI) let gross-salary
/// entry work. Plan 4 (Salary & deductions) replaces this body with the
/// saved salary profile.
final salarySettingsProvider = Provider<SalarySettings>(
  (ref) => SalarySettings(
    employer: '',
    grossMonthly: 0,
    basicPct: 60,
    taxCategory: 'individual',
    deductions: sampleDeductions(),
    rules: sampleTaxRules(),
  ),
);
