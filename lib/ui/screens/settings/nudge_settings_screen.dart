import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/report_settings.dart';
import '../../../finance/finance.dart';
import '../../../store/reports.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

const _help = {
  NudgeKind.emiDue: 'Loan installments due within 3 days',
  NudgeKind.budgetPace: '85% of a budget used, or on pace to go over',
  NudgeKind.categorySpike: 'A category well above your usual',
  NudgeKind.loanExtra: 'How much sooner an extra payment clears a loan',
  NudgeKind.payeeRepeat: '3 or more payments to one party in a week',
  NudgeKind.surplusToGoal: 'Move last month’s surplus to a goal',
  NudgeKind.emergencyFund: 'Months of essential spending you have saved',
  NudgeKind.praise: 'When you spend less or finish a challenge',
};

/// Settings → Nudges: turn each kind on or off (spec §4.1).
class NudgeSettingsScreen extends ConsumerWidget {
  const NudgeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(nudgeStateProvider).value ?? const NudgeState();
    return DetailPage(
      title: 'Nudges',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
        Text(
          'Paisa suggests ways to spend less, save more and clear loans, on Home and Reports. Turn off the kinds you don’t want.',
          style: PaisaText.sub.copyWith(color: c.ink3),
        ),
        const SizedBox(height: 12),
        PaisaListCard(children: [
          for (final k in NudgeKind.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ToggleRow(
                title: k.label,
                subtitle: _help[k],
                value: !state.disabled.contains(k),
                onChanged: (on) => ref.read(nudgeControllerProvider).setEnabled(k, on),
              ),
            ),
        ]),
      ]),
    );
  }
}
