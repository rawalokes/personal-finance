import 'package:flutter/material.dart';

import '../../../finance/finance.dart';
import '../../../integrations/gemini/schemas.dart';
import '../../ai/ai_panel.dart';
import '../../theme.dart';
import '../../typography.dart';

/// "Check with AI" on the salary screen (spec §9.4): flags anything unusual,
/// never changes the rules.
class AiSalaryCheck extends StatelessWidget {
  const AiSalaryCheck({super.key, required this.breakdown, required this.rules});
  final SalaryBreakdown? breakdown;
  final TaxRuleSet rules;

  Map<String, Object?> _salary(SalaryBreakdown b) {
    int r(Paisa p) => toWholeRupees(p);
    return {
      'fiscalYear': rules.fiscalYear,
      'taxRatesAreUnverifiedSamples': rules.isSampleDefault,
      'grossMonthly': r(b.gross),
      'basicMonthly': r(b.basic),
      'employeeDeductions': [for (final l in b.employeeLines) {'name': l.name, 'monthly': r(l.amount)}],
      'employerContributions': [for (final l in b.employerLines) {'name': l.name, 'monthly': r(l.amount)}],
      'allowableDeductionsAnnual': r(b.allowableAnnual),
      'taxableIncomeAnnual': r(b.taxableAnnual),
      'incomeTaxMonthly': r(b.monthlyTax),
      'takeHomeMonthly': r(b.takeHome),
    };
  }

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    final c = context.colors;
    return AiPanel<SalaryCheck>(
      label: 'Check with AI',
      enabled: b != null && !b.enteredAsTakeHome,
      run: (ai) => ai.checkSalary(_salary(b!)),
      result: (context, s) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.summary, style: PaisaText.body.copyWith(color: c.ink)),
        for (final f in s.flags) AiBullet(f),
      ]),
    );
  }
}
