import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/lessons.dart';
import '../../content/quotes.dart';
import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../../store/learn.dart';
import '../../store/reality.dart';
import '../components/buttons.dart';
import '../components/money_text.dart';
import '../components/surfaces.dart';
import '../components/toast.dart';
import '../components/tone.dart';
import '../feedback.dart';
import '../icons/paisa_icons.dart';
import '../reality/reality_widgets.dart';
import '../theme.dart';
import '../typography.dart';

/// A saving quote; pull Home down, or tap, for the next one.
class QuoteCard extends ConsumerWidget {
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final q = kQuotes[ref.watch(quoteIndexProvider)];
    return Semantics(
      button: true,
      hint: 'Shows another quote',
      child: PaisaCard(
        onTap: () => ref.read(quoteIndexProvider.notifier).next(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('“${q.text}”', style: PaisaText.body.copyWith(color: c.ink, fontStyle: FontStyle.italic, height: 1.45)),
          if (q.translation != null) ...[
            const SizedBox(height: 4),
            Text(q.translation!, style: PaisaText.sub.copyWith(color: c.ink2)),
          ],
          const SizedBox(height: 6),
          Text('— ${q.byline}', style: PaisaText.hint.copyWith(color: c.ink3)),
        ]),
      ),
    );
  }
}

/// Learn progress and the next unread lesson.
class LearnCard extends ConsumerWidget {
  const LearnCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final read = ref.watch(learnReadProvider).value ?? const <String>{};
    final next = kLessons.where((l) => !read.contains(l.id)).firstOrNull;
    return PaisaCard(
      onTap: () => context.push(next == null ? '/learn' : '/learn/${next.id}'),
      child: Row(children: [
        const IconWell(icon: PaisaIcons.book, tone: Tone.blue, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Learn · ${read.length} of ${kLessons.length} read', style: PaisaText.h3.copyWith(color: c.ink)),
            Text(next == null ? 'All lessons read 🎓 — revisit any time' : 'Next: ${next.title} · ${next.minutes} min',
                style: PaisaText.sub.copyWith(color: c.ink3)),
          ]),
        ),
        PaisaLink(label: 'All', onPressed: () => context.push('/learn')),
      ]),
    );
  }
}

/// Records [item] as an expense today and takes it off the list.
Future<void> buyWaitItem(WidgetRef ref, WaitItem item) async {
  final accounts = ref.read(accountsProvider).value ?? const <Account>[];
  final account = accounts.where((a) => a.id == item.accountId && !a.archived).firstOrNull ??
      accounts.where((a) => !a.archived && a.group == AccountGroup.liquid).firstOrNull;
  final toast = ref.read(toastProvider.notifier);
  if (account == null) {
    toast.show('Add an account first');
    return;
  }
  final clock = ref.read(clockProvider);
  final undo = await ref.read(transactionRepoProvider).add(
        Txn(
          id: ref.read(idGenProvider)(),
          date: clock.today(),
          time: clock.hhmm(),
          title: item.title,
          type: TxType.expense,
          accountId: account.id,
          categoryId: item.categoryId,
          amount: item.amount,
        ),
        summary: 'Bought ${item.title} after waiting · ${toastNpr(ref, item.amount)}',
      );
  await ref.read(waitListControllerProvider).bought(item.id);
  showUndoToast(toast, 'Expense saved · ${toastNpr(ref, item.amount)}', undo);
}

/// The 24-hour list: wants the user chose to sleep on.
class WaitingCard extends ConsumerWidget {
  const WaitingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final w = ref.watch(waitListProvider).value;
    if (w == null || (w.items.isEmpty && w.savedByWaiting == 0)) return const SizedBox.shrink();
    final now = ref.watch(clockProvider).stamp();
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(w.waiting.isEmpty ? 'Wish list' : 'Waiting 24 hours', style: PaisaText.h3.copyWith(color: c.ink))),
          PaisaLink(label: 'Wish list', onPressed: () => context.push('/wishlist')),
        ]),
        if (w.savedByWaiting > 0)
          Wrap(children: [
            Text('Saved by waiting so far: ', style: PaisaText.hint.copyWith(color: c.positive)),
            MoneyText(w.savedByWaiting, style: PaisaText.hint, color: c.positive),
          ]),
        if (w.wishes.isNotEmpty)
          Text(
            '${w.wishes.length} ${w.wishes.length == 1 ? 'thing' : 'things'} on your wish list',
            style: PaisaText.sub.copyWith(color: c.ink3),
          ),
        if (w.items.isEmpty)
          Text('Nothing waiting. Wants of NPR 5,000 or more can wait a day before you buy.', style: PaisaText.sub.copyWith(color: c.ink3)),
        for (final item in w.waiting)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: PaisaText.sub.copyWith(color: c.ink), overflow: TextOverflow.ellipsis),
                  Wrap(children: [
                    MoneyText(item.amount, style: PaisaText.hint, color: c.ink3),
                    Text(item.isReady(now) ? ' · still want it?' : ' · decide in ${item.hoursLeft(now)} h',
                        style: PaisaText.hint.copyWith(color: c.ink3)),
                  ]),
                ]),
              ),
              if (item.isReady(now)) ...[
                PaisaButton(
                  label: 'Skip',
                  small: true,
                  onPressed: () async {
                    final saved = await ref.read(waitListControllerProvider).skip(item.id);
                    ref.read(toastProvider.notifier).show('You saved ${toastNpr(ref, saved)} by waiting 🎉');
                  },
                ),
                const SizedBox(width: 6),
                PaisaButton(label: 'Buy', small: true, variant: ButtonVariant.outline, onPressed: () => buyWaitItem(ref, item)),
              ],
            ]),
          ),
      ]),
    );
  }
}

/// One honest line about money habits and goals, plus the "Can I afford
/// it?" decoder and the wish list.
class RealityCard extends ConsumerWidget {
  const RealityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final h = ref.watch(habitReportProvider).value;
    if (h == null) return const SizedBox.shrink();
    final goals = ref.watch(goalChecksProvider).value ?? const <GoalCheck>[];
    final reds = h.metrics.where((m) => m.level == Level.bad).length;
    final ambers = h.metrics.where((m) => m.level == Level.watch).length;
    final offGoals = goals.where((g) => g.verdict == GoalVerdict.notRealistic).length;
    final line = [
      reds > 0
          ? '$reds red ${reds == 1 ? 'flag' : 'flags'}'
          : ambers > 0
              ? '$ambers ${ambers == 1 ? 'habit' : 'habits'} to watch'
              : 'Habits look healthy',
      if (offGoals > 0) '$offGoals ${offGoals == 1 ? 'goal' : 'goals'} not realistic',
    ].join(' · ');
    return PaisaCard(
      onTap: () => context.push('/reality'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          LevelDot(h.overall, size: 12),
          const SizedBox(width: 8),
          Expanded(child: Text('Reality check', style: PaisaText.h3.copyWith(color: c.ink))),
          PaisaLink(label: 'Open', onPressed: () => context.push('/reality')),
        ]),
        Text(line, style: PaisaText.sub.copyWith(color: levelColor(context, h.overall))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          PaisaButton(label: 'Can I afford…?', small: true, icon: PaisaIcons.cart, onPressed: () => context.push('/afford')),
          PaisaButton(label: 'Wish list', small: true, variant: ButtonVariant.outline, icon: PaisaIcons.heart, onPressed: () => context.push('/wishlist')),
        ]),
      ]),
    );
  }
}
