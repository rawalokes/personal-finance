import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/reports.dart';
import '../../../store/ui_state.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../encourage/challenge_summary.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';

/// Plans → Challenges (spec §4.3): streak, suggestions, this month, badges.
class ChallengesView extends ConsumerWidget {
  const ChallengesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(challengeRolloverProvider);
    final c = context.colors;
    final s = ref.watch(challengeStateProvider).value;
    final i = ref.watch(reportInputsProvider).value;
    if (s == null || i == null) return const SizedBox.shrink();
    final today = ref.watch(clockProvider).today();
    final cal = ref.watch(monthCalendarProvider);
    final month = cal.key(today);
    final money = ref.watch(moneyFormatProvider);
    final ctl = ref.read(challengeControllerProvider);
    final toast = ref.read(toastProvider.notifier);
    final accepted = s.acceptedIn(month);
    final suggestions = s.suggestionsIn(month);
    final streak = challengeStreak(s.history, month);
    const section = EdgeInsets.fromLTRB(0, 20, 0, 8);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
      PaisaCard(
        child: Row(children: [
          const IconWell(icon: PaisaIcons.flag, tone: Tone.positive, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(streak == 0 ? 'Start your streak' : '$streak-month streak 🔥', style: PaisaText.h3.copyWith(color: c.ink)),
              Text(
                streak == 0 ? 'Finish one challenge this month to start a streak.' : 'You finished a challenge $streak months in a row. Keep it going!',
                style: PaisaText.sub.copyWith(color: c.ink3),
              ),
            ]),
          ),
        ]),
      ),
      if (suggestions.isNotEmpty) ...[
        SectionHeader(title: 'Suggested for ${cal.monthLong(month)}', padding: section),
        for (final ch in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(challengeTitle(ch, i, money), style: PaisaText.h3.copyWith(color: c.ink)),
                Text(
                  ch.template == ChallengeTemplate.saveAmount ? '10% more than you kept last month' : 'Your fastest-growing category last month',
                  style: PaisaText.sub.copyWith(color: c.ink3),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  PaisaButton(
                    label: 'Accept',
                    small: true,
                    onPressed: () async => toast.show(await ctl.accept(ch.id) ?? 'Challenge accepted'),
                  ),
                  const SizedBox(width: 8),
                  PaisaButton(label: 'Edit', small: true, variant: ButtonVariant.outline, onPressed: () => showChallengeSheet(context, existing: ch)),
                  const SizedBox(width: 8),
                  PaisaButton(label: 'Skip', small: true, variant: ButtonVariant.ghost, onPressed: () => ctl.remove(ch.id)),
                ]),
              ]),
            ),
          ),
      ],
      SectionHeader(
        title: 'This month',
        padding: section,
        trailing: PaisaLink(label: 'New challenge', onPressed: () => showChallengeSheet(context)),
      ),
      if (accepted.isEmpty)
        Text('No challenges yet. Accept a suggestion or add your own.', style: PaisaText.sub.copyWith(color: c.ink3))
      else
        PaisaListCard(children: [
          for (final ch in accepted)
            Builder(builder: (context) {
              final p = challengeProgress(ch, i.txs, i.loans, today);
              final cap = ch.template == ChallengeTemplate.categoryCap;
              final tracked = challengeTracked(ch, i.categories, i.loans);
              return InkWell(
                onTap: () => showChallengeSheet(context, existing: ch),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text(challengeTitle(ch, i, money), style: PaisaText.h3.copyWith(color: c.ink))),
                      if (!tracked)
                        const Tag('No longer tracked')
                      else
                        Tag(
                          cap ? (p.met ? 'On track' : 'Over') : (p.met ? 'Done' : 'In progress'),
                          tone: p.met ? Tone.positive : (cap ? Tone.red : Tone.neutral),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    ProgressBar(value: p.ratio, color: cap ? (p.met ? c.positive : c.red) : (p.met ? c.positive : c.primary)),
                    const SizedBox(height: 4),
                    Text(challengeProgressText(ch, p, money), style: PaisaText.hint.copyWith(color: c.ink3)),
                  ]),
                ),
              );
            }),
        ]),
      SectionHeader(title: 'Badges', subtitle: '${s.badges.length} of ${BadgeId.values.length} earned', padding: section),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final b in BadgeId.values) Tag(b.label, tone: s.badges.contains(b) ? Tone.positive : Tone.neutral),
      ]),
    ]);
  }
}

class _ChallengeForm extends ChangeNotifier {
  _ChallengeForm(this.existing)
      : template = existing?.template ?? ChallengeTemplate.saveAmount,
        categoryId = existing?.categoryId,
        loanId = existing?.loanId,
        target = TextEditingController(text: existing == null ? '' : _targetText(existing));

  final Challenge? existing;
  ChallengeTemplate template;
  String? categoryId;
  String? loanId;
  final TextEditingController target;
  String? error;

  static bool counts(ChallengeTemplate t) => t == ChallengeTemplate.noSpendDays || t == ChallengeTemplate.categoryCut;
  static String _targetText(Challenge c) => counts(c.template) ? '${c.target}' : '${toWholeRupees(c.target)}';

  void set(void Function() change) {
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    target.dispose();
    super.dispose();
  }
}

/// New challenge, or edit [existing] (a suggestion is accepted with the edits).
Future<void> showChallengeSheet(BuildContext context, {Challenge? existing}) => showPaisaFormSheet<void, _ChallengeForm>(
      context,
      title: existing == null ? 'New challenge' : 'Edit challenge',
      create: () => _ChallengeForm(existing),
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final i = ref.watch(reportInputsProvider).value;
        final needsCategory = f.template == ChallengeTemplate.categoryCap || f.template == ChallengeTemplate.categoryCut;
        final label = switch (f.template) {
          ChallengeTemplate.noSpendDays => 'Target (days)',
          ChallengeTemplate.categoryCut => 'Cut by (%)',
          _ => 'Amount (NPR)',
        };
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (existing == null) ...[
            FieldGroup(
              label: 'Challenge',
              child: ChipWrap(children: [
                for (final t in ChallengeTemplate.values) PaisaChip(label: t.label, selected: f.template == t, onTap: () => f.set(() => f.template = t)),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          PaisaTextField(label: label, controller: f.target, keyboardType: TextInputType.number, errorText: f.error),
          if (needsCategory && i != null) ...[
            const SizedBox(height: 14),
            FieldGroup(
              label: 'Category',
              child: ChipWrap(children: [
                for (final x in i.categories)
                  if (x.active && x.isTopLevel && !x.isAutomatic)
                    PaisaChip(label: x.name, selected: f.categoryId == x.id, onTap: () => f.set(() => f.categoryId = x.id)),
              ]),
            ),
          ],
          if (f.template == ChallengeTemplate.loanExtra && i != null) ...[
            const SizedBox(height: 14),
            FieldGroup(
              label: 'Loan',
              child: ChipWrap(children: [
                for (final l in i.loans)
                  if (!l.closed) PaisaChip(label: l.name, selected: f.loanId == l.id, onTap: () => f.set(() => f.loanId = l.id)),
              ]),
            ),
          ],
        ]);
      }),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          if (existing != null && existing.accepted) ...[
            Expanded(
              child: PaisaButton(
                label: 'Remove',
                variant: ButtonVariant.danger,
                onPressed: () async {
                  await ref.read(challengeControllerProvider).remove(existing.id);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Save',
              onPressed: () async {
                final counts = _ChallengeForm.counts(f.template);
                final target = counts ? int.tryParse(f.target.text.trim()) : parseNpr(f.target.text);
                final needsCategory = f.template == ChallengeTemplate.categoryCap || f.template == ChallengeTemplate.categoryCut;
                final error = target == null || target <= 0
                    ? 'Enter a number greater than zero'
                    : needsCategory && f.categoryId == null
                        ? 'Pick a category'
                        : f.template == ChallengeTemplate.loanExtra && f.loanId == null
                            ? 'Pick a loan'
                            : null;
                if (error != null) {
                  f.set(() => f.error = error);
                  return;
                }
                final ctl = ref.read(challengeControllerProvider);
                final c = Challenge(
                  id: existing?.id ?? '',
                  template: f.template,
                  month: existing?.month ?? ref.read(monthCalendarProvider).key(ref.read(clockProvider).today()),
                  target: target!,
                  categoryId: needsCategory ? f.categoryId : null,
                  loanId: f.template == ChallengeTemplate.loanExtra ? f.loanId : null,
                  source: existing?.source ?? ChallengeSource.user,
                );
                final String? problem;
                if (existing != null && existing.accepted) {
                  await ctl.update(c);
                  problem = null;
                } else {
                  problem = await ctl.add(c);
                }
                if (problem != null) {
                  f.set(() => f.error = problem);
                  return;
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show(existing == null ? 'Challenge added' : 'Challenge saved');
              },
            ),
          ),
        ]),
      ),
    );
