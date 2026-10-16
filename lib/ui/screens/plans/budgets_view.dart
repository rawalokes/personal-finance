import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/undo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';
import 'ai_budget_suggestions.dart';

final _budgetDataProvider = FutureProvider<(List<ExpenseCategory>, MonthlyTotals)>(
  (ref) async => (await ref.watch(categoriesProvider.future), await ref.watch(monthTotalsProvider.future)),
);

/// Days left in [today]'s month, today included.
int daysLeftInMonth(IsoDate today) {
  final d = parseIsoDate(today);
  return DateTime.utc(d.year, d.month + 1, 0).day - d.day;
}

/// Budgets segment: this month's total against all limits, then one bar per
/// category. Tapping a category edits its limit.
class BudgetsView extends ConsumerWidget {
  const BudgetsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(_budgetDataProvider),
      data: (d) {
        final (cats, month) = d;
        final c = context.colors;
        final today = ref.watch(clockProvider).today();
        final cal = ref.watch(monthCalendarProvider);
        final money = ref.watch(moneyFormatProvider);
        final shown = cats.where((x) => x.active && x.isTopLevel).toList()
          ..sort((a, b) => (a.isAutomatic ? 1 : 0).compareTo(b.isAutomatic ? 1 : 0));
        final lines = [
          for (final x in shown)
            if (!x.isAutomatic && (x.monthlyBudget ?? 0) > 0)
              BudgetLine(categoryId: x.id, limit: x.monthlyBudget!, spent: month.byCategory[x.id] ?? 0),
        ];
        final total = lines.fold<int>(0, (t, l) => t + l.limit);
        final spent = lines.fold<int>(0, (t, l) => t + l.spent);
        final over = lines.where((l) => l.state == BudgetState.over).length;
        return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: lines.isEmpty
                ? PaisaCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('No budgets yet', style: PaisaText.h2.copyWith(color: c.ink)),
                      const SizedBox(height: 6),
                      Text(
                        'Tap a category below to set a monthly limit. Paisa warns you at 85% and when you go over.',
                        style: PaisaText.sub.copyWith(color: c.ink3),
                      ),
                    ]),
                  )
                : PaisaCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('${cal.monthLong(cal.key(today))} budget', style: PaisaText.sub.copyWith(color: c.ink3))),
                        Tag(over > 0 ? '$over over budget' : 'On track', tone: over > 0 ? Tone.red : Tone.positive),
                      ]),
                      const SizedBox(height: 8),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Flexible(child: MoneyText(total - spent < 0 ? 0 : total - spent, style: PaisaText.h1.copyWith(fontSize: 28))),
                        const SizedBox(width: 6),
                        Text('left', style: PaisaText.sub.copyWith(color: c.ink3)),
                      ]),
                      const SizedBox(height: 10),
                      ProgressBar(
                        value: total == 0 ? 0 : spent / total,
                        color: over > 0 ? c.red : null,
                        semanticLabel: 'Budget used',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${money.npr(spent)} spent of ${money.npr(total)} · ${daysLeftInMonth(today)} days remaining',
                        style: PaisaText.hint.copyWith(color: c.ink3),
                      ),
                    ]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              Expanded(
                child: PaisaButton(
                  label: 'Categories',
                  icon: PaisaIcons.tag,
                  variant: ButtonVariant.outline,
                  small: true,
                  onPressed: () => context.push('/settings/categories'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PaisaButton(
                  label: 'Recurring',
                  icon: PaisaIcons.repeat,
                  variant: ButtonVariant.outline,
                  small: true,
                  onPressed: () => context.push('/settings/recurring'),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PaisaButton(
              label: 'Build a budget plan',
              icon: PaisaIcons.sliders,
              variant: ButtonVariant.outline,
              onPressed: () => context.push('/reality/budget'),
            ),
          ),
          const AiBudgetSuggestionsButton(),
          SectionHeader(
            title: 'By category',
            trailing: Text('Tap to edit a limit', style: PaisaText.sub.copyWith(color: c.ink3)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PaisaListCard(children: [
              for (final x in shown) _BudgetRow(category: x, spent: month.byCategory[x.id] ?? 0),
            ]),
          ),
        ]);
      },
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({required this.category, required this.spent});
  final ExpenseCategory category;
  final Paisa spent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final x = category;
    final limit = x.monthlyBudget ?? 0;
    final line = BudgetLine(categoryId: x.id, limit: limit, spent: spent);
    final (String sub, String trail, Color color) = x.isAutomatic
        ? ('${money.plain(line.spent)} this month · from loan repayments', 'Auto', c.ink3)
        : limit <= 0
            ? (line.spent > 0 ? 'No budget · ${money.plain(line.spent)} spent' : 'No budget', 'Set', c.ink3)
            : (
                '${money.plain(line.spent)} of ${money.plain(limit)}',
                line.state == BudgetState.over
                    ? '${money.short(line.spent - limit)} over'
                    : '${money.short(line.remaining)} left',
                switch (line.state) {
                  BudgetState.over => c.red,
                  BudgetState.nearLimit => c.amber,
                  BudgetState.ok => c.primary,
                },
              );
    return InkWell(
      onTap: x.isAutomatic ? null : () => showBudgetSheet(context, x, line.spent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconWell(icon: PaisaIcons.named(x.icon), tone: line.state == BudgetState.over ? Tone.red : Tone.neutral, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(x.name, style: PaisaText.h3.copyWith(color: c.ink)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.sub.copyWith(color: c.ink3)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(trail, style: PaisaText.buttonSmall.copyWith(color: line.state == BudgetState.over ? c.red : c.ink2)),
          ]),
          if (limit > 0 && !x.isAutomatic) ...[
            const SizedBox(height: 10),
            ProgressBar(value: line.ratio, color: color, semanticLabel: '${x.name} budget used'),
          ],
        ]),
      ),
    );
  }
}

class _BudgetForm extends ChangeNotifier {
  _BudgetForm(Paisa? current)
      : limit = TextEditingController(text: current == null || current <= 0 ? '' : '${toWholeRupees(current)}');
  final TextEditingController limit;
  String? error;
  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    limit.dispose();
    super.dispose();
  }
}

/// Edit (or remove) one category's monthly limit.
Future<void> showBudgetSheet(BuildContext context, ExpenseCategory category, Paisa spent) {
  return showPaisaFormSheet<void, _BudgetForm>(
    context,
    title: '${category.name} budget',
    create: () => _BudgetForm(category.monthlyBudget),
    body: (ctx, form) => Consumer(builder: (ctx, ref, _) {
      final today = ref.watch(clockProvider).today();
      final cal = ref.watch(monthCalendarProvider);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'Spent ${ref.watch(moneyFormatProvider).npr(spent)} so far in ${cal.monthLong(cal.key(today))}.',
          style: PaisaText.sub.copyWith(color: ctx.colors.ink3),
        ),
        const SizedBox(height: 14),
        PaisaTextField(
          label: 'Monthly limit (NPR)',
          controller: form.limit,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: form.error,
          autofocus: true,
        ),
      ]);
    }),
    footer: (ctx, form) => Consumer(builder: (ctx, ref, _) {
      Future<void> save(Paisa? value) async {
        final catalog = ref.read(catalogRepoProvider);
        final toast = ref.read(toastProvider.notifier);
        final previous = category.monthlyBudget;
        await catalog.setBudget(category.id, value);
        if (ctx.mounted) Navigator.of(ctx).pop();
        showUndoToast(
          toast,
          value == null ? '${category.name} budget removed' : '${category.name} budget set to ${toastNpr(ref, value)}',
          UndoAction(() => catalog.setBudget(category.id, previous)),
        );
      }

      return Row(children: [
        if ((category.monthlyBudget ?? 0) > 0) ...[
          Expanded(child: PaisaButton(label: 'Remove', variant: ButtonVariant.danger, onPressed: () => save(null))),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: PaisaButton(
            label: 'Save',
            onPressed: () {
              final v = parseNpr(form.limit.text);
              if (v == null || v <= 0) {
                form.setError('Enter an amount greater than zero');
                return;
              }
              save(v);
            },
          ),
        ),
      ]);
    }),
  );
}
