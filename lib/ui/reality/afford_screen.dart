import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../integrations/gemini/schemas.dart';
import '../../store/data_providers.dart';
import '../../store/learn.dart';
import '../../store/reality.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/surfaces.dart';
import '../components/text_field.dart';
import '../components/toast.dart';
import '../components/tone.dart';
import '../encourage/home_cards.dart';
import '../feedback.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../typography.dart';
import 'reality_widgets.dart';

const kPriorityLabels = {1: 'Must have', 2: 'Normal', 3: 'Someday'};

/// "Can I afford it?" — Paisa's own verdict from free-to-spend, goals and
/// EMIs, the real cost in work hours and in 10 years, and (optionally) an
/// honest AI answer. Opened from a wish, it decides that wish.
class AffordScreen extends ConsumerStatefulWidget {
  const AffordScreen({super.key, this.wishId, this.item, this.price});
  final String? wishId;
  final String? item;
  final Paisa? price;

  @override
  ConsumerState<AffordScreen> createState() => _AffordScreenState();
}

class _AffordScreenState extends ConsumerState<AffordScreen> {
  late final _item = TextEditingController(text: widget.item ?? '');
  late final _price = TextEditingController(text: widget.price == null ? '' : '${toWholeRupees(widget.price!)}');
  bool _essential = false;
  bool _filled = false;

  @override
  void dispose() {
    _item.dispose();
    _price.dispose();
    super.dispose();
  }

  WaitItem? _wish(WaitList? w) => widget.wishId == null ? null : w?.items.where((i) => i.id == widget.wishId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    ref.watch(accountsProvider);
    final plan = ref.watch(monthPlanProvider).value;
    final avg = ref.watch(averagesProvider).value;
    final inputs = ref.watch(reportInputsProvider).value;
    final w = ref.watch(waitListProvider).value;
    final wish = _wish(w);
    if (wish != null && !_filled) {
      _filled = true;
      _item.text = wish.title;
      _price.text = '${toWholeRupees(wish.amount)}';
    }
    final price = parseNpr(_price.text);
    final item = _item.text.trim();
    final check = price == null || price <= 0 || plan == null || avg == null || inputs == null
        ? null
        : canAfford(price: price, plan: plan, averages: avg, goals: inputs.goals, accounts: inputs.accounts, today: ref.watch(clockProvider).today(), essential: _essential);

    return DetailPage(
      title: 'Can I afford it?',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
        PaisaTextField(label: 'What do you want to buy?', controller: _item, hint: 'e.g. Perfume', onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        PaisaTextField(
          label: 'Price (NPR)',
          controller: _price,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FieldGroup(
          label: 'Is it a need or a want?',
          child: ChipWrap(children: [
            PaisaChip(label: 'Want', selected: !_essential, onTap: () => setState(() => _essential = false)),
            PaisaChip(label: 'Need', selected: _essential, onTap: () => setState(() => _essential = true)),
          ]),
        ),
        if (wish != null) ...[
          const SizedBox(height: 12),
          FieldGroup(
            label: 'Priority',
            child: ChipWrap(children: [
              for (final e in kPriorityLabels.entries)
                PaisaChip(label: e.value, selected: wish.priority == e.key, onTap: () => ref.read(waitListControllerProvider).setPriority(wish.id, e.key)),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        if (check == null)
          Note('Type a price to see if it fits this month — after saving and EMIs.', tone: Tone.blue)
        else ...[
          _Verdict(check: check),
          const SizedBox(height: 10),
          PaisaCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('What it really costs', style: PaisaText.h3.copyWith(color: c.ink)),
              const SizedBox(height: 6),
              _Fact(icon: PaisaIcons.wallet, text: 'Free to spend this month: ${money.npr(check.freeToSpend)} (after saving and EMIs)'),
              if (check.workHours != null) _Fact(icon: PaisaIcons.clock, text: workHoursText(check.workHours!)),
              if (check.goalDelayDays != null && check.goalDelayDays! > 0)
                _Fact(icon: PaisaIcons.flag, text: 'Pushes ${check.goalName} back by about ${check.goalDelayDays} ${check.goalDelayDays == 1 ? 'day' : 'days'}'),
              _Fact(icon: PaisaIcons.trend, text: 'Kept and growing at 8%, it’s ≈ ${money.npr(check.futureValue10y)} in 10 years'),
              if (check.monthsToSave != null)
                _Fact(icon: PaisaIcons.calendar, text: 'Saving for it takes about ${check.monthsToSave} ${check.monthsToSave == 1 ? 'month' : 'months'} at your usual pace'),
            ]),
          ),
          if (check.suggestWaiting && wish == null) ...[
            const SizedBox(height: 10),
            Note('A big want: sleep on it. Most urges fade within a day.', lead: '24-hour rule. ', tone: Tone.amber),
          ],
          const SizedBox(height: 12),
          RealityAiCard(
            key: ValueKey('$item|$price|$_essential'),
            topic: RealityTopic.afford,
            question: item.isEmpty ? 'this' : item,
            blurb: 'Get a straight answer in plain words, using your real numbers.',
            facts: () => affordFacts(item.isEmpty ? 'this' : item, check, essential: _essential),
          ),
          const SizedBox(height: 14),
          if (wish != null) ...[
            PaisaButton(
              label: 'Bought it',
              variant: check.verdict == AffordVerdict.yes ? ButtonVariant.primary : ButtonVariant.outline,
              onPressed: () async {
                await buyWaitItem(ref, wish);
                if (context.mounted) _leave(context, '/home');
              },
            ),
            const SizedBox(height: 8),
            PaisaButton(
              label: 'I don’t want it',
              variant: check.verdict == AffordVerdict.yes ? ButtonVariant.outline : ButtonVariant.primary,
              onPressed: () async {
                final saved = await ref.read(waitListControllerProvider).skip(wish.id);
                ref.read(toastProvider.notifier).show('You saved ${toastNpr(ref, saved)} by not buying 🎉');
                if (context.mounted) _leave(context, '/home');
              },
            ),
          ] else ...[
            PaisaButton(
              label: 'Add to wish list',
              variant: check.verdict == AffordVerdict.yes ? ButtonVariant.outline : ButtonVariant.primary,
              icon: PaisaIcons.heart,
              onPressed: () async {
                await ref.read(waitListControllerProvider).addWish(title: item.isEmpty ? 'Something' : item, amount: check.price);
                ref.read(toastProvider.notifier).show('Added to your wish list');
                if (context.mounted) _leave(context, '/wishlist');
              },
            ),
            if (check.suggestWaiting) ...[
              const SizedBox(height: 8),
              PaisaButton(
                label: 'Wait 24 hours',
                variant: ButtonVariant.outline,
                icon: PaisaIcons.clock,
                onPressed: () async {
                  await ref.read(waitListControllerProvider).add(title: item.isEmpty ? 'Something' : item, amount: check.price);
                  ref.read(toastProvider.notifier).show('Good call. Decide tomorrow.');
                  if (context.mounted) _leave(context, '/home');
                },
              ),
            ],
          ],
        ],
      ]),
    );
  }
}

/// Back to where the user came from, or to [fallback] when opened directly.
void _leave(BuildContext context, String fallback) => context.canPop() ? context.pop() : context.go(fallback);

class _Verdict extends StatelessWidget {
  const _Verdict({required this.check});
  final AffordCheck check;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (title, level) = switch (check.verdict) {
      AffordVerdict.yes => ('Yes, you can afford it', Level.good),
      AffordVerdict.wait => ('Wait — think it over', Level.watch),
      AffordVerdict.no => ('No — not right now', Level.bad),
    };
    final why = switch (check.reason) {
      AffordReason.fitsEasily => 'It’s under half of what’s free to spend this month.',
      AffordReason.needFits => 'It’s a need and it fits in what’s free to spend this month.',
      AffordReason.eatsMostOfFree => 'It would use more than half of what’s free to spend this month.',
      AffordReason.needsSavingsOrEmi => 'It would come out of the money for your savings or EMIs.',
      AffordReason.moreThanYouHave => 'It’s more than you have in your spendable accounts.',
    };
    return Semantics(
      liveRegion: true,
      child: PaisaCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: LevelDot(level, size: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: PaisaText.h2.copyWith(color: levelColor(context, level))),
              const SizedBox(height: 4),
              Text(why, style: PaisaText.sub.copyWith(color: c.ink2)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PaisaIcon(icon, size: 18, color: c.ink3),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: PaisaText.sub.copyWith(color: c.ink))),
      ]),
    );
  }
}
