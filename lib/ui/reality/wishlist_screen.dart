import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../../store/learn.dart';
import '../../store/reality.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/money_text.dart';
import '../components/sheet.dart';
import '../components/surfaces.dart';
import '../components/text_field.dart';
import '../components/toast.dart';
import '../components/tone.dart';
import '../encourage/home_cards.dart';
import '../icons/paisa_icons.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../typography.dart';
import 'afford_screen.dart';
import 'reality_widgets.dart';

/// Things you want to buy, with when you can really afford each one, plus
/// anything still waiting out its 24 hours.
class WishListScreen extends ConsumerWidget {
  const WishListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final w = ref.watch(waitListProvider).value ?? const WaitList();
    final plan = ref.watch(monthPlanProvider).value;
    final avg = ref.watch(averagesProvider).value;
    final inputs = ref.watch(reportInputsProvider).value;
    final today = ref.watch(clockProvider).today();
    final now = ref.watch(clockProvider).stamp();
    final total = w.wishes.fold<Paisa>(0, (s, i) => s + i.amount);

    AffordCheck? check(WaitItem i) => plan == null || avg == null || inputs == null
        ? null
        : canAfford(price: i.amount, plan: plan, averages: avg, goals: inputs.goals, accounts: inputs.accounts, today: today);

    return DetailPage(
      title: 'Wish list',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
        if (w.savedByWaiting > 0) ...[
          PaisaCard(
            color: c.positiveBg,
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text('Saved by not buying: ', style: PaisaText.sub.copyWith(color: c.positiveInk)),
              MoneyText(w.savedByWaiting, style: PaisaText.h3, color: c.positiveInk),
              Text(' 🎉', style: PaisaText.sub.copyWith(color: c.positiveInk)),
            ]),
          ),
          const SizedBox(height: 10),
        ],
        Text('Write it down instead of buying it now. Paisa tells you when it really fits.', style: PaisaText.sub.copyWith(color: c.ink3)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: PaisaButton(label: 'Add a wish', icon: PaisaIcons.plus, onPressed: () => _addWish(context, ref))),
          const SizedBox(width: 8),
          Expanded(child: PaisaButton(label: 'Can I afford…?', variant: ButtonVariant.outline, onPressed: () => context.push('/afford'))),
        ]),
        if (w.wishes.isNotEmpty) ...[
          SectionHeader(padding: kInsetSection, title: 'Wishes', subtitle: '${w.wishes.length} · total ${ref.watch(moneyFormatProvider).npr(total)}'),
          for (final i in w.wishes) ...[_WishTile(item: i, check: check(i)), const SizedBox(height: 8)],
        ] else ...[
          const SizedBox(height: 16),
          Note('Nothing on your wish list yet. Add the next thing you feel like buying — waiting is how you save.', tone: Tone.blue),
        ],
        if (w.waiting.isNotEmpty) ...[
          const SectionHeader(padding: kInsetSection, title: 'Waiting 24 hours'),
          PaisaListCard(children: [
            for (final i in w.waiting)
              ListRow(
                title: i.title,
                subtitle: i.isReady(now) ? 'Still want it?' : 'Decide in ${i.hoursLeft(now)} h',
                trailing: i.isReady(now)
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        PaisaButton(
                          label: 'Skip',
                          small: true,
                          onPressed: () async {
                            final saved = await ref.read(waitListControllerProvider).skip(i.id);
                            ref.read(toastProvider.notifier).show('You saved ${ref.read(moneyFormatProvider).npr(saved)} by waiting 🎉');
                          },
                        ),
                        const SizedBox(width: 6),
                        PaisaButton(label: 'Buy', small: true, variant: ButtonVariant.outline, onPressed: () => buyWaitItem(ref, i)),
                      ])
                    : MoneyText(i.amount, style: PaisaText.sub),
              ),
          ]),
        ],
      ]),
    );
  }
}

class _WishTile extends ConsumerWidget {
  const _WishTile({required this.item, required this.check});
  final WaitItem item;
  final AffordCheck? check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final k = check;
    final (String fits, Level level) = k == null
        ? ('', Level.watch)
        : k.verdict == AffordVerdict.yes
            ? ('Can afford now', Level.good)
            : k.monthsToSave != null
                ? ('In about ${k.monthsToSave} ${k.monthsToSave == 1 ? 'month' : 'months'} at your usual savings', Level.watch)
                : ('Not while nothing is left over each month', Level.bad);
    return PaisaCard(
      onTap: () => context.push('/afford?wish=${item.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(item.title, style: PaisaText.h3.copyWith(color: c.ink), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          MoneyText(item.amount, style: PaisaText.h3),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Tag(kPriorityLabels[item.priority] ?? 'Normal', tone: item.priority == 1 ? Tone.blue : Tone.neutral),
          if (fits.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: [
              LevelDot(level, size: 8),
              const SizedBox(width: 6),
              Flexible(child: Text(fits, style: PaisaText.hint.copyWith(color: c.ink2))),
            ]),
          if (k?.workHours != null) Text(workHoursText(k!.workHours!), style: PaisaText.hint.copyWith(color: c.ink3)),
        ]),
      ]),
    );
  }
}

class _WishForm extends ChangeNotifier {
  final name = TextEditingController();
  final price = TextEditingController();
  int priority = 2;
  String? nameError;
  String? priceError;

  void setPriority(int p) {
    priority = p;
    notifyListeners();
  }

  bool validate() {
    nameError = name.text.trim().isEmpty ? 'Give it a name' : null;
    final p = parseNpr(price.text);
    priceError = p == null || p <= 0 ? 'Enter a price' : null;
    notifyListeners();
    return nameError == null && priceError == null;
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    super.dispose();
  }
}

Future<void> _addWish(BuildContext context, WidgetRef ref) => showPaisaFormSheet<void, _WishForm>(
      context,
      title: 'Add a wish',
      create: _WishForm.new,
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PaisaTextField(label: 'What is it?', controller: f.name, hint: 'e.g. Perfume', errorText: f.nameError),
        const SizedBox(height: 14),
        PaisaTextField(
          label: 'Price (NPR)',
          controller: f.price,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: f.priceError,
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: 'Priority',
          child: ChipWrap(children: [
            for (final e in kPriorityLabels.entries) PaisaChip(label: e.value, selected: f.priority == e.key, onTap: () => f.setPriority(e.key)),
          ]),
        ),
      ]),
      footer: (ctx, f) => PaisaButton(
        label: 'Add to wish list',
        onPressed: () async {
          if (!f.validate()) return;
          await ref.read(waitListControllerProvider).addWish(title: f.name.text.trim(), amount: parseNpr(f.price.text)!, priority: f.priority);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
