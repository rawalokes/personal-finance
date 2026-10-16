import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../store/reports.dart';
import '../components/buttons.dart';
import '../components/surfaces.dart';
import '../components/toast.dart';
import '../components/tone.dart';
import '../icons/paisa_icons.dart';
import '../shell/tabs.dart';
import '../theme.dart';
import '../typography.dart';

/// Tab roots switch tabs; everything else opens on top.
void openAppRoute(BuildContext context, String route) {
  final path = Uri.parse(route).path;
  if (kTabs.any((t) => t.path == path)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

class NudgeCard extends ConsumerWidget {
  const NudgeCard(this.nudge, {super.key});
  final Nudge nudge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final (icon, tone) = switch (nudge.kind) {
      NudgeKind.emiDue => (PaisaIcons.calendar, Tone.amber),
      NudgeKind.payYourselfFirst => (PaisaIcons.moneyIn, Tone.positive),
      NudgeKind.budgetPace => (PaisaIcons.pie, Tone.amber),
      NudgeKind.categorySpike => (PaisaIcons.trend, Tone.red),
      NudgeKind.payeeRepeat => (PaisaIcons.repeat, Tone.red),
      NudgeKind.loanExtra => (PaisaIcons.rupee, Tone.blue),
      NudgeKind.surplusToGoal || NudgeKind.emergencyFund => (PaisaIcons.target, Tone.blue),
      NudgeKind.praise => (PaisaIcons.check, Tone.positive),
    };
    final route = nudge.route;
    final action = nudge.actionLabel;
    return PaisaCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconWell(icon: icon, tone: tone, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nudge.title, style: PaisaText.h3.copyWith(color: c.ink)),
            const SizedBox(height: 3),
            Text(nudge.body, style: PaisaText.sub.copyWith(color: c.ink3)),
            if (route != null && action != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: PaisaLink(label: action, onPressed: () => openAppRoute(context, route)),
              ),
          ]),
        ),
        PaisaIconButton(
          icon: PaisaIcons.close,
          label: 'Dismiss: ${nudge.title}',
          iconSize: 18,
          onPressed: () async {
            await ref.read(nudgeControllerProvider).dismiss(nudge.id);
            ref.read(toastProvider.notifier).show('Hidden for 7 days');
          },
        ),
      ]),
    );
  }
}
