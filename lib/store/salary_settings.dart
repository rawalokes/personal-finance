import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finance.dart';
import 'data_providers.dart';

/// What Add income and the salary screens need to turn gross into take-home.
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
        taxCategory: rules.categories.containsKey(taxCategory) ? taxCategory : rules.categories.keys.first,
        asOf: asOf,
      );
}

/// The saved salary profile, deductions and tax rules. A clean install has
/// no employer or gross, the sample deductions and the sample tax rules
/// (labelled as samples wherever they are shown).
final salarySettingsProvider = FutureProvider<SalarySettings>((ref) async {
  final profile = await ref.watch(salaryProfileProvider.future);
  return SalarySettings(
    employer: profile.employer,
    grossMonthly: profile.grossMonthly,
    basicPct: profile.basicPct,
    taxCategory: profile.taxCategory,
    deductions: await ref.watch(deductionsProvider.future),
    rules: await ref.watch(taxRulesProvider.future),
  );
});
