import 'package:flutter/material.dart';

import '../../components/inputs.dart';
import '../../components/top_bar.dart';
import 'budgets_view.dart';
import 'goals_view.dart';
import 'loans_view.dart';

enum PlansSegment { budgets, loans, goals }

/// Plans tab (spec §7): Budgets | Loans | Goals. [initial] comes from the
/// route (`/plans?seg=loans`), so Home's "Loans" opens the right segment.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, this.initial});

  final String? initial;

  static PlansSegment parse(String? seg) => PlansSegment.values.firstWhere(
        (s) => s.name == seg,
        orElse: () => PlansSegment.budgets,
      );

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late PlansSegment _seg = PlansScreen.parse(widget.initial);

  @override
  void didUpdateWidget(PlansScreen old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && widget.initial != null) _seg = PlansScreen.parse(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PaisaTopBar(title: 'Plans'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Segmented<PlansSegment>(
          segments: const [
            (PlansSegment.budgets, 'Budgets'),
            (PlansSegment.loans, 'Loans'),
            (PlansSegment.goals, 'Goals'),
          ],
          selected: _seg,
          onChanged: (s) => setState(() => _seg = s),
        ),
      ),
      Expanded(
        child: switch (_seg) {
          PlansSegment.budgets => const BudgetsView(),
          PlansSegment.loans => const LoansView(),
          PlansSegment.goals => const GoalsView(),
        },
      ),
    ]);
  }
}
