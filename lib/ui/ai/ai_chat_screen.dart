import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../integrations/gemini/client.dart';
import '../../store/ai.dart';
import '../../store/data_providers.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/surfaces.dart';
import '../components/text_field.dart';
import '../components/tone.dart';
import '../icons/paisa_icons.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../typography.dart';
import 'ai_panel.dart';

const kSuggestedQuestions = [
  'Which loan should I pay off first?',
  'Where can I cut spending this month?',
  'How many months would my savings last?',
  'Can I afford NPR 50,000 for a phone this month?',
];

class _Message {
  const _Message(this.fromUser, this.text, {this.usedData = const [], this.deepLink = 'none'});
  final bool fromUser;
  final String text;
  final List<String> usedData;
  final String deepLink;

  static _Message? fromJson(Object? j) {
    if (j is! Map) return null;
    final text = j['text'];
    if (text is! String) return null;
    return _Message(
      j['role'] == 'user',
      text,
      usedData: [for (final u in (j['usedData'] as List? ?? const [])) if (u is String) u],
      deepLink: j['deepLink'] is String ? j['deepLink']! as String : 'none',
    );
  }
}

/// Ask Paisa (spec §9.4): questions about your own numbers. The
/// conversation is kept only on the phone.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _question = TextEditingController();
  final _scroll = ScrollController();
  List<_Message> _messages = const [];
  AiError? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(settingsRepoProvider).aiChat().then((saved) {
      if (mounted) setState(() => _messages = [for (final m in saved) ?_Message.fromJson(m)]);
    });
  }

  @override
  void dispose() {
    _question.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String q) async {
    final question = q.trim();
    if (question.isEmpty || _busy) return;
    _question.clear();
    setState(() {
      _busy = true;
      _error = null;
      _messages = [..._messages, _Message(true, question)];
    });
    try {
      final a = await runAi(() => ref.read(aiServiceProvider).ask(question));
      if (mounted) {
        setState(() => _messages = [..._messages, _Message(false, a.answer, usedData: a.usedData, deepLink: a.deepLink)]);
      }
    } on AiError catch (e) {
      // The question was not answered (or saved); take it back off the list.
      if (mounted) {
        setState(() {
          _error = e;
          _messages = _messages.sublist(0, _messages.length - 1);
          _question.text = question;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _clear() async {
    await ref.read(aiServiceProvider).clearChat();
    if (mounted) setState(() => _messages = const []);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DetailPage(
      title: 'Ask Paisa',
      actions: [
        if (_messages.isNotEmpty) PaisaIconButton(icon: PaisaIcons.trash, label: 'Clear conversation', onPressed: _clear),
      ],
      body: ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), children: [
        Text(
          'Answers use only your Paisa numbers. The conversation stays on this phone.',
          style: PaisaText.hint.copyWith(color: c.ink3),
        ),
        const SizedBox(height: 12),
        if (_messages.isEmpty) ...[
          Text('Try asking', style: PaisaText.h3.copyWith(color: c.ink)),
          const SizedBox(height: 8),
          PaisaListCard(children: [
            for (final q in kSuggestedQuestions) ListRow(title: q, onTap: _busy ? null : () => _ask(q)),
          ]),
        ],
        for (final m in _messages) _Bubble(m),
        if (_busy)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Paisa is thinking…', style: PaisaText.sub.copyWith(color: c.ink3)),
          ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Note(_error!.message, tone: Tone.amber)),
      ]),
      footer: Row(children: [
        Expanded(
          child: PaisaTextField(
            label: 'Your question',
            showLabel: false,
            hint: 'Ask about your money…',
            controller: _question,
          ),
        ),
        const SizedBox(width: 8),
        PaisaButton(label: 'Ask', small: true, onPressed: _busy ? null : () => _ask(_question.text)),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m);
  final _Message m;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final link = aiLinkLabel(m.deepLink);
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: m.fromUser ? c.surface2 : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: m.fromUser ? null : Border.all(color: c.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.text, style: PaisaText.body.copyWith(color: c.ink)),
            if (!m.fromUser) ...[
              if (m.usedData.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Used: ${m.usedData.join(', ')}', style: PaisaText.hint.copyWith(color: c.ink3)),
              ],
              if (link != null) PaisaLink(label: link, onPressed: () => openAiLink(context, m.deepLink)),
              const SizedBox(height: 2),
              const AiLabel(),
            ],
          ]),
        ),
      ),
    );
  }
}
