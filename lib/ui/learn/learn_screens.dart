import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../content/lessons.dart';
import '../../integrations/gemini/client.dart';
import '../../integrations/gemini/schemas.dart';
import '../../store/ai.dart';
import '../../store/data_providers.dart';
import '../../store/learn.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/layout.dart';
import '../components/surfaces.dart';
import '../components/tone.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../typography.dart';

/// Paragraphs and '• ' bullets.
class LessonBody extends StatelessWidget {
  const LessonBody(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = PaisaText.body.copyWith(color: c.ink2, height: 1.5);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final para in text.trim().split('\n\n'))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final line in para.split('\n'))
              line.startsWith('• ')
                  ? Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('•  ', style: style.copyWith(color: c.primary)),
                        Expanded(child: Text(line.substring(2), style: style)),
                      ]),
                    )
                  : Text(line, style: style),
          ]),
        ),
    ]);
  }
}

/// Settings → Learn and Home → Learn: lessons by topic and today's AI lesson.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final read = ref.watch(learnReadProvider).value ?? const <String>{};
    final done = kLessons.where((l) => read.contains(l.id)).length;
    return DetailPage(
      title: 'Learn',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
        Text('Short lessons to spend less, save more and clear loans — written for Nepal.', style: PaisaText.sub.copyWith(color: c.ink3)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ProgressBar(value: done / kLessons.length, color: c.positive)),
          const SizedBox(width: 10),
          Text(done == kLessons.length ? 'All $done read 🎓' : '$done of ${kLessons.length} read', style: PaisaText.sub.copyWith(color: c.ink2)),
        ]),
        const SizedBox(height: 12),
        const AiLessonCard(),
        for (final topic in LessonTopic.values) ...[
          SectionHeader(title: topic.label, padding: const EdgeInsets.fromLTRB(0, 20, 0, 8)),
          PaisaListCard(children: [
            for (final l in kLessons)
              if (l.topic == topic)
                ListRow(
                  title: l.title,
                  subtitle: '${l.summary} · ${l.minutes} min',
                  leading: PaisaIcon(read.contains(l.id) ? PaisaIcons.check : PaisaIcons.book, size: 20, color: read.contains(l.id) ? c.positive : c.ink2),
                  onTap: () => context.push('/learn/${l.id}'),
                ),
          ]),
        ],
      ]),
    );
  }
}

/// "Today's lesson": written by the AI from the user's numbers, once a day.
class AiLessonCard extends ConsumerStatefulWidget {
  const AiLessonCard({super.key});

  @override
  ConsumerState<AiLessonCard> createState() => _AiLessonCardState();
}

class _AiLessonCardState extends ConsumerState<AiLessonCard> {
  bool _busy = false;
  String? _error;
  AiLesson? _fresh;

  Future<void> _write() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final l = await ref.read(aiServiceProvider).lesson();
      if (mounted) setState(() => _fresh = l);
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
      return Note('Turn on the AI assistant in Settings to get a lesson written from your own numbers each day.', tone: Tone.blue);
    }
    final lesson = _fresh ?? ref.watch(cachedAiLessonProvider).value;
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Today’s lesson', style: PaisaText.h3.copyWith(color: c.ink))),
          const Tag('AI', tone: Tone.blue),
        ]),
        const SizedBox(height: 8),
        if (lesson != null) ...[
          Text(lesson.title, style: PaisaText.h3.copyWith(color: c.ink)),
          const SizedBox(height: 6),
          LessonBody(lesson.body),
          Note(lesson.takeaway, lead: 'This week: ', tone: Tone.positive),
        ] else ...[
          Text('A short lesson based on your own spending, saving and loans.', style: PaisaText.sub.copyWith(color: c.ink3)),
          const SizedBox(height: 10),
          PaisaButton(
            label: _busy ? 'Writing…' : 'Write today’s lesson',
            icon: PaisaIcons.bolt,
            variant: ButtonVariant.outline,
            onPressed: _busy ? null : _write,
          ),
        ],
        if (_error != null) ...[const SizedBox(height: 8), Note(_error!, tone: Tone.amber)],
      ]),
    );
  }
}

/// One lesson; opening it marks it read.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kLessons.any((l) => l.id == widget.lessonId)) markLessonRead(ref.read(settingsRepoProvider), widget.lessonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = kLessons.where((x) => x.id == widget.lessonId).firstOrNull;
    if (l == null) return const DetailPage(title: 'Learn', body: Center(child: Text('Lesson not found')));
    final i = kLessons.indexOf(l);
    final next = i + 1 < kLessons.length ? kLessons[i + 1] : null;
    return DetailPage(
      title: l.topic.label,
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), children: [
        Text(l.title, style: PaisaText.h1.copyWith(color: c.ink)),
        const SizedBox(height: 4),
        Text('${l.minutes} min read', style: PaisaText.hint.copyWith(color: c.ink3)),
        const SizedBox(height: 16),
        LessonBody(l.body),
        if (l.tryInPaisa != null) Note(l.tryInPaisa!, lead: 'Try it in Paisa: ', tone: Tone.positive),
        SectionHeader(title: 'Sources', padding: const EdgeInsets.fromLTRB(0, 20, 0, 6)),
        for (final s in l.sources)
          Align(
            alignment: Alignment.centerLeft,
            child: PaisaLink(
              label: s.label,
              onPressed: () => launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication),
            ),
          ),
        if (next != null) ...[
          const SizedBox(height: 20),
          PaisaButton(label: 'Next: ${next.title}', variant: ButtonVariant.outline, onPressed: () => context.pushReplacement('/learn/${next.id}')),
        ],
      ]),
    );
  }
}
