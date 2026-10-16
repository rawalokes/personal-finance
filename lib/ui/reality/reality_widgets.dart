import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/finance.dart';
import '../../integrations/gemini/client.dart';
import '../../integrations/gemini/schemas.dart';
import '../../store/ai.dart';
import '../../store/data_providers.dart';
import '../../store/reality.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/surfaces.dart';
import '../components/tone.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../typography.dart';

Tone levelTone(Level l) => switch (l) {
      Level.good => Tone.positive,
      Level.watch => Tone.amber,
      Level.bad => Tone.red,
    };

Color levelColor(BuildContext context, Level l) => switch (l) {
      Level.good => context.colors.positive,
      Level.watch => context.colors.amber,
      Level.bad => context.colors.red,
    };

class LevelDot extends StatelessWidget {
  const LevelDot(this.level, {super.key, this.size = 10});
  final Level level;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: levelColor(context, level), shape: BoxShape.circle),
      );
}

/// Section header padding inside an already padded list.
const kInsetSection = EdgeInsets.fromLTRB(0, 24, 0, 10);

String percent(double v) => v.isFinite ? '${(v * 100).round()}%' : '—';

/// "≈ 11 hours of work" (one decimal under 10 hours).
String workHoursText(double hours) => '≈ ${hours < 10 ? hours.toStringAsFixed(1) : hours.round()} hours of work';

/// The AI's honest take on facts Paisa computed. Shows this month's cached
/// answer when there is one (unless [showCached] is false), or a button to
/// ask. Never sends anything until the user taps.
class RealityAiCard extends ConsumerStatefulWidget {
  const RealityAiCard({
    super.key,
    required this.topic,
    required this.facts,
    required this.blurb,
    this.question,
    this.scope,
    this.showCached = true,
    this.askLabel = 'Ask AI for a reality check',
  });

  final RealityTopic topic;
  final Map<String, Object?> Function() facts;
  final String blurb;
  final String? question;
  final String? scope;
  final bool showCached;
  final String askLabel;

  @override
  ConsumerState<RealityAiCard> createState() => _RealityAiCardState();
}

class _RealityAiCardState extends ConsumerState<RealityAiCard> {
  bool _busy = false;
  String? _error;
  RealityAnswer? _fresh;

  Future<void> _ask({bool force = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await ref.read(aiServiceProvider).reality(widget.topic, widget.facts(), question: widget.question, scope: widget.scope, force: force);
      if (mounted) setState(() => _fresh = a);
    } on AiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object {
      if (mounted) setState(() => _error = 'Couldn’t reach the AI. Try again later.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ai = ref.watch(aiSettingsProvider).value;
    if (ai == null || !ai.enabled) {
      return Note('Turn on the AI assistant in Settings for an honest, plain-words take on these numbers.', tone: Tone.blue);
    }
    final answer = _fresh ?? (widget.showCached ? ref.watch(cachedRealityProvider((widget.topic, widget.scope))).value : null);
    final tone = switch (answer?.verdict) {
      'yes' || 'good' => Tone.positive,
      'wait' || 'watch' => Tone.amber,
      'no' || 'bad' => Tone.red,
      _ => Tone.neutral,
    };
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Honest take', style: PaisaText.h3.copyWith(color: c.ink))),
          const Tag('AI', tone: Tone.blue),
        ]),
        const SizedBox(height: 8),
        if (answer != null) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 6), child: Tag(answer.verdict.toUpperCase(), tone: tone)),
            const SizedBox(width: 8),
            Expanded(child: Text(answer.headline, style: PaisaText.h3.copyWith(color: c.ink))),
          ]),
          const SizedBox(height: 6),
          for (final p in answer.points)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $p', style: PaisaText.sub.copyWith(color: c.ink2)),
            ),
          if (answer.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Do this', style: PaisaText.sub.copyWith(color: c.ink3)),
            for (final a in answer.actions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PaisaIcon(PaisaIcons.check, size: 16, color: c.positive),
                  const SizedBox(width: 6),
                  Expanded(child: Text(a, style: PaisaText.sub.copyWith(color: c.ink))),
                ]),
              ),
          ],
          if (widget.topic != RealityTopic.afford) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: PaisaButton(label: _busy ? 'Asking…' : 'Ask again', small: true, variant: ButtonVariant.ghost, onPressed: _busy ? null : () => _ask(force: true)),
            ),
          ],
        ] else ...[
          Text(widget.blurb, style: PaisaText.sub.copyWith(color: c.ink3)),
          const SizedBox(height: 10),
          PaisaButton(
            label: _busy ? 'Thinking…' : widget.askLabel,
            icon: PaisaIcons.bolt,
            variant: ButtonVariant.outline,
            onPressed: _busy ? null : _ask,
          ),
        ],
        if (_error != null) ...[const SizedBox(height: 8), Note(_error!, tone: Tone.amber)],
      ]),
    );
  }
}
