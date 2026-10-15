import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../integrations/gemini/client.dart';
import '../../integrations/gemini/schemas.dart';
import '../../store/ai.dart';
import '../../store/data_providers.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/layout.dart';
import '../components/surfaces.dart';
import '../components/tone.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'ai_panel.dart';

/// AI Insights (spec §9.4): this month's analysis, cached per month and
/// regenerated only on demand.
class AiInsightsScreen extends ConsumerStatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen> {
  AiAnalysis? _analysis;
  AiError? _error;
  bool _busy = false;
  bool _lastForced = false;

  @override
  void initState() {
    super.initState();
    _load(force: false);
  }

  Future<void> _load({required bool force}) async {
    setState(() {
      _busy = true;
      _error = null;
      _lastForced = force;
    });
    // Read before the await: the user may leave while the AI is answering,
    // and the Home card must still pick up the new analysis.
    final ai = ref.read(aiServiceProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final a = await runAi(() => ai.analyse(force: force));
      container.invalidate(aiCachedAnalysisProvider);
      if (mounted) setState(() => _analysis = a);
    } on AiError catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = _analysis;
    final money = ref.watch(moneyFormatProvider);
    final month = monthNameYear(ref.watch(clockProvider).today());
    return DetailPage(
      title: 'AI insights',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
        if (_error != null) ...[
          Note(_error!.message, tone: Tone.amber),
          const SizedBox(height: 10),
          PaisaButton(label: 'Try again', variant: ButtonVariant.secondary, onPressed: _busy ? null : () => _load(force: _lastForced)),
          const SizedBox(height: 14),
        ],
        if (a == null && _busy)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text('Analysing $month…', style: PaisaText.sub.copyWith(color: c.ink3)),
            ]),
          ),
        if (a != null) ...[
          PaisaCard(
            child: Row(children: [
              SizedBox(
                width: 64,
                child: Column(children: [
                  Text('${a.healthScore}', style: PaisaText.h1.copyWith(fontSize: 34, color: _scoreColor(c, a.healthScore))),
                  Text('of 100', style: PaisaText.hint.copyWith(color: c.ink3)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Health score · $month', style: PaisaText.hint.copyWith(color: c.ink3)),
                  const SizedBox(height: 2),
                  Text(a.headline, style: PaisaText.body.copyWith(color: c.ink)),
                ]),
              ),
            ]),
          ),
          if (a.findings.isNotEmpty) ...[
            const SectionHeader(title: 'What stands out', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            PaisaListCard(children: [
              for (final f in a.findings)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(f.title, style: PaisaText.h3.copyWith(color: c.ink))),
                      const SizedBox(width: 8),
                      Tag(_severityLabel(f.severity), tone: _severityTone(f.severity)),
                    ]),
                    const SizedBox(height: 4),
                    Text(f.detail, style: PaisaText.sub.copyWith(color: c.ink2)),
                  ]),
                ),
            ]),
          ],
          if (a.actions.isNotEmpty) ...[
            const SectionHeader(title: 'Do this month', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            PaisaListCard(children: [
              for (final x in a.actions)
                ListRow(
                  title: x.title,
                  subtitle: [
                    x.why,
                    if (x.monthlyImpact != null && x.monthlyImpact! > 0) 'About ${money.npr(fromRupees(x.monthlyImpact!))} a month',
                  ].join(' · '),
                  leading: const IconWell(icon: PaisaIcons.target, tone: Tone.positive, size: 38),
                  trailing: x.deepLink == 'none' ? null : PaisaIcon(PaisaIcons.chevR, size: 19, color: c.ink3),
                  onTap: x.deepLink == 'none' ? null : () => openAiLink(context, x.deepLink),
                ),
            ]),
          ],
          if (a.risks.isNotEmpty) ...[
            const SectionHeader(title: 'Watch out for', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            PaisaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final r in a.risks) AiBullet(r)])),
          ],
          const SizedBox(height: 14),
          AiLabel(date: a.generatedAt == null ? null : longDate(a.generatedAt!.substring(0, 10))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: PaisaButton(
                label: _busy ? 'Analysing…' : 'Regenerate',
                icon: PaisaIcons.refresh,
                variant: ButtonVariant.outline,
                onPressed: _busy ? null : () => _load(force: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: PaisaButton(label: 'Ask Paisa', icon: PaisaIcons.bolt, onPressed: () => context.push('/ai/chat'))),
          ]),
        ],
      ]),
    );
  }
}

Color _scoreColor(PaisaColors c, int score) => score >= 70
    ? c.positive
    : score >= 40
        ? c.amber
        : c.red;

String _severityLabel(String s) => switch (s) {
      'good' => 'Good',
      'warning' => 'Watch',
      'critical' => 'Urgent',
      _ => 'Info',
    };

Tone _severityTone(String s) => switch (s) {
      'good' => Tone.positive,
      'warning' => Tone.amber,
      'critical' => Tone.red,
      _ => Tone.blue,
    };
