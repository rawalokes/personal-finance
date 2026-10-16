import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings_models.dart';
import '../../../finance/finance.dart';
import '../../../integrations/gemini/client.dart';
import '../../../sms/sms_models.dart';
import '../../../store/ai.dart';
import '../../../store/data_providers.dart';
import '../../../store/sms_sync.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';

/// "Ask AI for a suggestion" on a low-confidence message (spec §9.4,
/// acceptance 20). Shown only while the AI assistant is on. The answer
/// replaces the suggestion, labelled "Suggested by AI"; nothing is saved
/// until the user confirms (guardrail 3: AI never approves SMS).
class AiSmsHelp extends ConsumerStatefulWidget {
  const AiSmsHelp(this.m, {super.key});
  final SmsMessage m;

  @override
  ConsumerState<AiSmsHelp> createState() => _AiSmsHelpState();
}

class _AiSmsHelpState extends ConsumerState<AiSmsHelp> {
  bool _busy = false;
  AiError? _error;

  Future<void> _ask() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final m = widget.m;
    final repo = ref.read(smsRepoProvider);
    final toast = ref.read(toastProvider.notifier);
    try {
      final s = await runAi(() => ref.read(aiServiceProvider).suggestSms(m));
      final type = TxType.fromWire(s.type);
      // Only ids that exist; the AI can't invent categories or accounts.
      final categories = await ref.read(categoriesProvider.future);
      final incomeTypes = await ref.read(incomeTypesProvider.future);
      final accounts = await ref.read(accountsProvider.future);
      final category = categories.any((c) => c.id == s.categoryId) ? s.categoryId : null;
      final incomeType = incomeTypes.any((t) => t.id == s.incomeTypeId) ? s.incomeTypeId : null;
      final counter = accounts.any((a) => a.id == s.counterAccountId && a.id != m.accountId) ? s.counterAccountId : null;
      await repo.applyAiSuggestion(
        m.id,
        type: type,
        categoryId: category,
        incomeTypeId: incomeType,
        counterAccountId: counter,
        // Never "high": an AI guess must not look certain.
        confidence: s.confidence == 'low' ? SmsConfidence.low : SmsConfidence.medium,
        reason: s.reason,
      );
      toast.show('AI suggestion added — still needs your confirmation');
    } on AiError catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiSettingsProvider).value;
    final m = widget.m;
    if (ai == null || !ai.enabled || m.confidence != SmsConfidence.low || m.suggestedBy == SmsSuggestedBy.ai) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (ai.privacy != AiPrivacy.sms)
          const Note('To get AI help with unclear messages, allow “Include SMS text” in Settings → AI assistant.', tone: Tone.blue)
        else
          PaisaButton(
            label: _busy ? 'Asking AI…' : 'Ask AI for a suggestion',
            icon: PaisaIcons.bolt,
            variant: ButtonVariant.outline,
            onPressed: _busy ? null : _ask,
          ),
        if (_error != null) ...[const SizedBox(height: 8), Note(_error!.message, tone: Tone.amber)],
      ]),
    );
  }
}
