import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../integrations/gemini/schemas.dart';
import '../../../store/ui_state.dart';
import '../../ai/ai_panel.dart';
import '../../theme.dart';
import '../../typography.dart';

/// "Explain with AI" on the payoff planner (spec §9.4). The engine's numbers
/// are sent as they are; the AI only explains them.
class AiPlannerExplainer extends ConsumerWidget {
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

  Map<String, Object?> _plan() {
    Map<String, Object?> result(PayoffResult r) => {
          'months': r.hitLimit ? 'never' : r.months,
          'totalInterest': toWholeRupees(r.totalInterest),
        };
    return {
      'strategy': strategy.name,
      'extraMonthly': toWholeRupees(extraMonthly),
      if (surplus != null) 'averageMonthlySurplus': toWholeRupees(surplus!),
      'withoutExtra': result(comparison.baseline),
      'withPlan': result(comparison.plan),
      'monthsSaved': comparison.monthsSaved,
      'interestSaved': toWholeRupees(comparison.interestSaved),
      'order': [
        for (final l in comparison.plan.loans) {'loan': l.name, 'paidOffInMonth': l.payoffMonth ?? 'never'},
      ],
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    return AiPanel<PlanExplanation>(
      label: 'Explain with AI',
      run: (ai) => ai.explainPlan(_plan()),
      result: (context, e) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.explanation, style: PaisaText.body.copyWith(color: c.ink)),
        if (e.tradeoffs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Trade-offs', style: PaisaText.h3.copyWith(color: c.ink)),
          for (final t in e.tradeoffs) AiBullet(t),
        ],
        if (e.sustainableExtra != null && e.sustainableExtra! > 0) ...[
          const SizedBox(height: 10),
          Text('A sustainable extra: ${money.npr(e.sustainableExtra!)} a month', style: PaisaText.h3.copyWith(color: c.primary)),
        ],
      ]),
    );
  }
}
