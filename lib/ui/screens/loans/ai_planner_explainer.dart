import 'package:flutter/widgets.dart';

import '../../../finance/finance.dart';

/// "Explain with AI" on the payoff planner; shown only when the AI assistant
/// is on. Built in the AI milestone.
class AiPlannerExplainer extends StatelessWidget {
  const AiPlannerExplainer({
    super.key,
    required this.loans,
    required this.comparison,
    required this.extraMonthly,
    required this.strategy,
    required this.surplus,
  });

  final List<Loan> loans;
  final PayoffComparison comparison;
  final Paisa extraMonthly;
  final PayoffStrategy strategy;
  final Paisa? surplus;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
