import 'package:flutter/widgets.dart';

import '../../../finance/finance.dart';

/// "Check with AI" on the salary screen; shown only when the AI assistant
/// is on. Built in the AI milestone.
class AiSalaryCheck extends StatelessWidget {
  const AiSalaryCheck({super.key, required this.breakdown, required this.rules});
  final SalaryBreakdown? breakdown;
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
