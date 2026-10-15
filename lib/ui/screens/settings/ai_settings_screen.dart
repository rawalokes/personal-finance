import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings_models.dart';
import '../../../finance/finance.dart';
import '../../../integrations/gemini/client.dart';
import '../../../store/ai.dart';
import '../../../store/data_providers.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

const _limits = [25, 50, 100, 250, 500];

String _modelLabel(String m) => m.startsWith('models/') ? m.substring(7) : m;

/// Settings → AI assistant (spec §9.2): off by default; uses the user's own
/// Google AI key, kept only in secure storage.
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _key = TextEditingController();
  bool _replacing = false;
  bool _show = false;
  bool _testing = false;
  String? _status;
  bool _ok = false;
  List<String> _models = const [];

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save(AiSettings s) => ref.read(settingsRepoProvider).saveAi(s);

  /// Tests [candidate] (a new key) or the saved one; a new key is saved only
  /// once Google accepts it.
  Future<void> _test(String? saved) async {
    final candidate = _key.text.trim().isNotEmpty ? _key.text.trim() : saved;
    if (candidate == null || candidate.isEmpty) {
      setState(() {
        _ok = false;
        _status = 'Paste your key from Google AI Studio first.';
      });
      return;
    }
    setState(() => _testing = true);
    final ai = ref.read(aiServiceProvider);
    try {
      final models = await runAi(() => ai.testKey(candidate));
      if (candidate != saved) await ai.saveKey(candidate);
      _key.clear();
      ref.invalidate(aiKeyProvider);
      if (mounted) {
        setState(() {
          _ok = true;
          _status = '✓ Connected';
          _models = models;
          _replacing = false;
        });
      }
    } on AiError catch (e) {
      if (mounted) {
        setState(() {
          _ok = false;
          _status = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _remove() async {
    await ref.read(aiServiceProvider).removeKey();
    ref.invalidate(aiKeyProvider);
    if (!mounted) return;
    setState(() {
      _status = null;
      _models = const [];
      _show = false;
    });
    ref.read(toastProvider.notifier).show('AI key removed from this phone');
  }

  Future<void> _preview() async {
    final json = await ref.read(aiServiceProvider).previewPayload();
    if (!mounted) return;
    final c = context.colors;
    await showPaisaSheet<void>(
      context,
      title: 'What will be sent',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'This summary goes with every request, in whole rupees. Account names and numbers are never included.',
          style: PaisaText.sub.copyWith(color: c.ink3),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(json, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.ink2, height: 1.35)),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final key = ref.watch(aiKeyProvider).value;
    final hasKey = (key ?? '').isNotEmpty;
    final month = monthKey(ref.watch(clockProvider).today());
    return DetailPage(
      title: 'AI assistant',
      body: AsyncView(
        value: ref.watch(aiSettingsProvider),
        data: (s) {
          final models = {..._models, ?s.model}.toList();
          final used = s.usedIn(month);
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            PaisaCard(
              child: ToggleRow(
                title: 'Use AI to analyse my finances',
                subtitle: 'Google Gemini, with your own key. Off by default.',
                value: s.enabled,
                onChanged: (on) => _save(s.copyWith(enabled: on)),
              ),
            ),
            const SizedBox(height: 14),
            const Note(
              'Your data is sent to Google using your own key. Check Google’s terms for how your plan treats submitted data.',
              tone: Tone.blue,
            ),
            const SectionHeader(title: 'Your key', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (hasKey && !_replacing) ...[
                  Text(_show ? key! : maskKey(key!), style: PaisaText.h3.copyWith(color: c.ink, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  Wrap(spacing: 4, children: [
                    PaisaLink(label: _show ? 'Hide' : 'Show', onPressed: () => setState(() => _show = !_show)),
                    PaisaLink(label: 'Replace', onPressed: () => setState(() => _replacing = true)),
                    PaisaLink(label: 'Remove', onPressed: _remove),
                  ]),
                ] else ...[
                  PaisaTextField(
                    label: 'Google AI key',
                    controller: _key,
                    hint: 'AIza…',
                    obscure: true,
                    helper: 'Create one free at aistudio.google.com. It is kept only in this phone’s secure storage.',
                  ),
                ],
                const SizedBox(height: 12),
                PaisaButton(
                  label: _testing ? 'Testing…' : 'Test key',
                  variant: ButtonVariant.secondary,
                  onPressed: _testing ? null : () => _test(key),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 10),
                  Text(_status!, style: PaisaText.sub.copyWith(color: _ok ? c.positive : c.red)),
                ],
              ]),
            ),
            if (models.isNotEmpty) ...[
              const SectionHeader(title: 'Model', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
              ChipWrap(children: [
                for (final m in models)
                  PaisaChip(label: _modelLabel(m), selected: m == s.model, onTap: () => _save(s.copyWith(model: m))),
              ]),
            ],
            const SectionHeader(title: 'What AI may see', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            Segmented<AiPrivacy>(
              segments: const [
                (AiPrivacy.summaries, 'Summaries'),
                (AiPrivacy.merchants, '+ Merchants'),
                (AiPrivacy.sms, '+ SMS text'),
              ],
              selected: s.privacy,
              onChanged: (p) => _save(s.copyWith(privacy: p)),
            ),
            const SizedBox(height: 8),
            Text(switch (s.privacy) {
              AiPrivacy.summaries => 'Totals, category sums, loan balances and rates. No merchant names, SMS text or account numbers.',
              AiPrivacy.merchants => 'Adds merchant names and transaction titles of recent transactions.',
              AiPrivacy.sms => 'Also allows masked SMS text for help with unclear bank messages.',
            }, style: PaisaText.sub.copyWith(color: c.ink3)),
            const SizedBox(height: 12),
            PaisaButton(label: 'Preview what will be sent', variant: ButtonVariant.outline, onPressed: _preview),
            const SectionHeader(title: 'Usage', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
            PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                KeyValueRow('Requests this month', value: '$used of ${s.monthlyLimit}'),
                const SizedBox(height: 8),
                ProgressBar(value: s.monthlyLimit == 0 ? 1 : used / s.monthlyLimit, semanticLabel: 'AI requests used'),
                const SizedBox(height: 12),
                Text('Monthly limit', style: PaisaText.sub.copyWith(color: c.ink3)),
                ChipWrap(children: [
                  for (final l in _limits)
                    PaisaChip(label: '$l', selected: s.monthlyLimit == l, onTap: () => _save(s.copyWith(monthlyLimit: l))),
                ]),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
