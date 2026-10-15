import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/undo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/dialog.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';

class _GoalsData {
  const _GoalsData(this.goals, this.accounts, this.categories);
  final List<Goal> goals;
  final List<Account> accounts;
  final List<ExpenseCategory> categories;
}

final _goalsDataProvider = FutureProvider<_GoalsData>((ref) async => _GoalsData(
      await ref.watch(goalsProvider.future),
      await ref.watch(accountsProvider.future),
      await ref.watch(categoriesProvider.future),
    ));

const _kinds = ['Short-term', 'Long-term savings', 'Major purchase', 'Travel', 'Other'];

/// Goals segment: emergency-fund months (essential budgets × 6, spec §7) and
/// savings goals with the monthly saving that reaches them on time.
class GoalsView extends ConsumerWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(_goalsDataProvider),
      data: (d) {
        final c = context.colors;
        final money = ref.watch(moneyFormatProvider);
        final live = d.accounts.where((a) => !a.archived).toList();
        final essential = d.categories
            .where((x) => x.active && x.essential && x.isTopLevel)
            .fold<int>(0, (t, x) => t + (x.monthlyBudget ?? 0));
        final reserved = live.where((a) => a.group == AccountGroup.reserved).fold<int>(0, (t, a) => t + a.balance);
        final months = emergencyFundMonths(essentialMonthly: essential, saved: reserved);
        final (status, tone) = essential <= 0
            ? ('Set budgets', Tone.neutral)
            : months >= kEmergencyFundMonths
                ? ('Target met', Tone.positive)
                : months >= 3
                    ? ('Building', Tone.amber)
                    : ('Low', Tone.red);
        return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Emergency fund', style: PaisaText.h3.copyWith(color: c.ink))),
                  Tag(status, tone: tone),
                ]),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(essential <= 0 ? '—' : months.toStringAsFixed(1), style: PaisaText.numeric(PaisaText.h1.copyWith(color: c.ink))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('months of essential expenses covered', style: PaisaText.sub.copyWith(color: c.ink3)),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 1; i <= kEmergencyFundMonths; i++) ...[
                    if (i > 1) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: months >= i ? c.primary : months > i - 1 ? c.lockedBar : c.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 8),
                Text(
                  essential <= 0
                      ? 'Set budgets for essential categories (rent, groceries, transport…) to see your 6-month target.'
                      : '${money.npr(reserved)} in reserved savings · essentials ${money.npr(essential)} / month · target 6 months',
                  style: PaisaText.hint.copyWith(color: c.ink3),
                ),
              ]),
            ),
          ),
          SectionHeader(
            title: 'Savings goals',
            trailing: PaisaLink(label: 'New goal', onPressed: () => showNewGoalSheet(context)),
          ),
          if (d.goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PaisaCard(
                child: Text(
                  'No goals yet. Create one for a trip, a laptop or a down payment and Paisa shows what to save each month.',
                  style: PaisaText.sub.copyWith(color: c.ink3),
                ),
              ),
            ),
          for (final g in d.goals)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _GoalCard(goal: g, accounts: live),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              'Moving money into a goal is a transfer between your accounts — it is never counted as an expense.',
              style: PaisaText.hint.copyWith(color: c.ink3),
            ),
          ),
        ]);
      },
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.accounts});
  final Goal goal;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final today = ref.watch(clockProvider).today();
    final g = goal;
    final linked = accounts.where((a) => a.id == g.linkedAccountId).firstOrNull;
    final current = linked?.balance ?? g.current;
    final ratio = g.target <= 0 ? 0.0 : (current / g.target).clamp(0.0, 1.0).toDouble();
    final monthly = recommendedMonthlySaving(target: g.target, current: current, today: today, targetDate: g.targetDate);
    final reached = current >= g.target;
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          IconWell(icon: PaisaIcons.named(g.icon), tone: reached ? Tone.positive : Tone.neutral, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: PaisaText.h3.copyWith(color: c.ink)),
              Text(
                '${g.kind} · ${g.targetDate == null ? 'no date' : 'by ${longDate(g.targetDate)}'}',
                style: PaisaText.sub.copyWith(color: c.ink3),
              ),
            ]),
          ),
          Text('${(ratio * 100).floor()}%', style: PaisaText.h3.copyWith(color: c.ink)),
          PaisaIconButton(icon: PaisaIcons.trash, label: 'Delete ${g.name}', onPressed: () => _delete(context, ref)),
        ]),
        const SizedBox(height: 10),
        ProgressBar(value: ratio, semanticLabel: '${g.name} progress'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(
              '${money.npr(current)} of ${money.npr(g.target)}',
              style: PaisaText.numeric(PaisaText.sub.copyWith(color: c.ink2)),
            ),
          ),
          Text(
            reached
                ? 'Reached'
                : monthly == null
                    ? ''
                    : 'Save ${money.npr(monthly)}/mo',
            style: PaisaText.sub.copyWith(color: reached ? c.positive : c.ink2),
          ),
        ]),
        if (linked != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Tracks the ${linked.name} balance', style: PaisaText.hint.copyWith(color: c.ink3)),
          )
        else if (!reached) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: PaisaButton(
              label: 'Add money',
              icon: PaisaIcons.plus,
              variant: ButtonVariant.secondary,
              small: true,
              onPressed: () => showAddMoneySheet(context, g),
            ),
          ),
        ],
      ]),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${goal.name}?',
      body: 'The goal is removed. Money you moved for it stays in your accounts. You can undo right after.',
      okLabel: 'Delete goal',
      okVariant: ButtonVariant.danger,
    );
    if (ok != ConfirmChoice.ok) return;
    final toast = ref.read(toastProvider.notifier);
    final undo = await ref.read(goalRepoProvider).delete(goal.id);
    showUndoToast(toast, 'Goal deleted', undo);
  }
}

class _NewGoalForm extends ChangeNotifier {
  final name = TextEditingController();
  final target = TextEditingController();
  final saved = TextEditingController();
  String kind = _kinds.first;
  IsoDate? date;
  String? nameError, targetError, savedError;

  void setKind(String k) {
    kind = k;
    notifyListeners();
  }

  void setDate(IsoDate? d) {
    date = d;
    notifyListeners();
  }

  Goal? validate() {
    final t = parseNpr(target.text);
    final s = saved.text.trim().isEmpty ? 0 : parseNpr(saved.text);
    nameError = name.text.trim().isEmpty ? 'Enter a goal name' : null;
    targetError = t == null || t <= 0 ? 'Enter a target amount' : null;
    savedError = s == null ? 'Enter a valid amount' : null;
    notifyListeners();
    if (nameError != null || targetError != null || savedError != null) return null;
    return Goal(id: '', name: name.text, kind: kind, target: t!, current: s!, targetDate: date);
  }

  @override
  void dispose() {
    for (final c in [name, target, saved]) {
      c.dispose();
    }
    super.dispose();
  }
}

Future<void> showNewGoalSheet(BuildContext context) => showPaisaFormSheet<void, _NewGoalForm>(
      context,
      title: 'New savings goal',
      create: _NewGoalForm.new,
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaTextField(label: 'Goal name', controller: f.name, hint: 'e.g. Wedding fund', errorText: f.nameError),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'Type',
            child: ChipWrap(children: [
              for (final k in _kinds) PaisaChip(label: k, selected: f.kind == k, onTap: () => f.setKind(k)),
            ]),
          ),
          const SizedBox(height: 14),
          PaisaTextField(
            label: 'Target amount (NPR)',
            controller: f.target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.targetError,
          ),
          const SizedBox(height: 14),
          PaisaTextField(
            label: 'Already saved (NPR)',
            controller: f.saved,
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.savedError,
          ),
          const SizedBox(height: 14),
          OptionalDateField(
            label: 'Target date',
            value: f.date,
            onChanged: f.setDate,
            initialPick: addMonths(ref.read(clockProvider).today(), 6),
          ),
        ]);
      }),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Create goal',
              onPressed: () async {
                final goal = f.validate();
                if (goal == null) return;
                await ref.read(goalRepoProvider).add(goal);
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show('Goal “${goal.name.trim()}” created');
              },
            ),
          ),
        ]),
      ),
    );

class _AddMoneyForm extends ChangeNotifier {
  final amount = TextEditingController();
  String? from;
  String? to;
  String? error;

  void setFrom(String id) {
    from = id;
    if (to == id) to = null;
    notifyListeners();
  }

  void setTo(String? id) {
    to = id;
    notifyListeners();
  }

  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }
}

/// Add money to a goal: from a spendable account, optionally moving it into
/// a savings account (a transfer, never an expense).
Future<void> showAddMoneySheet(BuildContext context, Goal goal) => showPaisaFormSheet<void, _AddMoneyForm>(
      context,
      title: 'Add to ${goal.name}',
      create: _AddMoneyForm.new,
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final accounts = (ref.watch(accountsProvider).value ?? const <Account>[]).where((a) => !a.archived).toList();
        final fromChoices = accounts.where((a) => a.group == AccountGroup.liquid).toList();
        final from = f.from ?? fromChoices.firstOrNull?.id;
        final toChoices =
            accounts.where((a) => a.id != from && (a.group == AccountGroup.reserved || a.group == AccountGroup.liquid)).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaTextField(
            label: 'Amount (NPR)',
            controller: f.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.error,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'From',
            child: ChipWrap(children: [
              for (final a in fromChoices) PaisaChip(label: a.shortName, selected: a.id == from, onTap: () => f.setFrom(a.id)),
            ]),
          ),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'Move it to',
            child: ChipWrap(children: [
              PaisaChip(label: 'Keep it there', selected: f.to == null, onTap: () => f.setTo(null)),
              for (final a in toChoices) PaisaChip(label: a.shortName, selected: a.id == f.to, onTap: () => f.setTo(a.id)),
            ]),
          ),
          const SizedBox(height: 14),
          const Note('Recorded as a transfer to savings — not an expense.', tone: Tone.positive),
        ]);
      }),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Add money',
              onPressed: () async {
                final amount = parseNpr(f.amount.text);
                final accounts = (ref.read(accountsProvider).value ?? const <Account>[]).where((a) => !a.archived);
                final from = f.from ?? accounts.where((a) => a.group == AccountGroup.liquid).firstOrNull?.id;
                if (amount == null || amount <= 0) {
                  f.setError('Enter an amount greater than zero');
                  return;
                }
                if (from == null) {
                  f.setError('Add a bank, wallet or cash account first');
                  return;
                }
                final toast = ref.read(toastProvider.notifier);
                final UndoAction undo = await ref
                    .read(goalRepoProvider)
                    .contribute(goal.id, amount: amount, fromAccountId: from, toAccountId: f.to);
                if (ctx.mounted) Navigator.of(ctx).pop();
                showUndoToast(toast, '${toastNpr(ref, amount)} added to ${goal.name} · not an expense', undo);
              },
            ),
          ),
        ]),
      ),
    );
