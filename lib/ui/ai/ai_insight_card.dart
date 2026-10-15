import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../store/ai.dart';
import '../../store/data_providers.dart';
import '../components/surfaces.dart';
import '../components/tone.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../typography.dart';

/// Home's AI insight card (spec §9.4). Not shown while the AI assistant is
/// off; never sends anything by itself.
class AiInsightCard extends ConsumerWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(aiSettingsProvider).value?.enabled ?? false;
    if (!on) return const SizedBox.shrink();
    final key = ref.watch(aiKeyProvider);
    if (!key.hasValue) return const SizedBox.shrink();
    final c = context.colors;
    final hasKey = (key.value ?? '').isNotEmpty;
    final analysis = hasKey ? ref.watch(aiCachedAnalysisProvider).value : null;
    final (String title, String body, String route) = !hasKey
        ? ('Add your Google AI key to get insights', 'Paisa uses your own key; nothing is sent until you ask.', '/settings/ai')
        : analysis == null
            ? ('Get this month’s analysis', 'A health score, what stands out and what to do next.', '/ai/insights')
            : ('Health score ${analysis.healthScore}', analysis.headline, '/ai/insights');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: PaisaCard(
        onTap: () => context.push(route),
        child: Row(children: [
          const IconWell(icon: PaisaIcons.bolt, tone: Tone.blue, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI insight', style: PaisaText.hint.copyWith(color: c.ink3)),
              Text(title, style: PaisaText.h3.copyWith(color: c.ink)),
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: PaisaText.sub.copyWith(color: c.ink3)),
            ]),
          ),
          PaisaIcon(PaisaIcons.chevR, size: 19, color: c.ink3),
        ]),
      ),
    );
  }
}
