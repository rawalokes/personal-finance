import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repos/catalog_repo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/dialog.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

String _frequencyLabel(IncomeFrequency f) => '${f.name[0].toUpperCase()}${f.name.substring(1)}';

final _incomeDataProvider = FutureProvider<(List<IncomeType>, List<Account>)>(
  (ref) async => (await ref.watch(incomeTypesProvider.future), await ref.watch(accountsProvider.future)),
);

/// Settings → Income types: editable examples, not a fixed list.
class IncomeTypesScreen extends ConsumerWidget {
  const IncomeTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    return DetailPage(
      title: 'Income types',
      actions: [PaisaLink(label: 'New type', onPressed: () => showIncomeTypeSheet(context, null))],
      body: AsyncView(
        value: ref.watch(_incomeDataProvider),
        data: (d) {
          final (types, accounts) = d;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            Text(
              'Editable examples — not a fixed list. Disabled types stay in history but are hidden when adding income.',
              style: PaisaText.sub.copyWith(color: c.ink3),
            ),
            const SizedBox(height: 12),
            for (final t in types)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Opacity(
                  opacity: t.active ? 1 : 0.6,
                  child: PaisaCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        IconWell(icon: PaisaIcons.named(t.icon), tone: Tone.positive, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.name, style: PaisaText.h3.copyWith(color: c.ink)),
                            Text(t.description ?? 'No description', style: PaisaText.sub.copyWith(color: c.ink3)),
                          ]),
                        ),
                        PaisaToggle(
                          value: t.active,
                          label: '${t.active ? 'Disable' : 'Enable'} ${t.name}',
                          onChanged: (on) async {
                            await ref.read(catalogRepoProvider).setIncomeTypeActive(t.id, on);
                            ref.read(toastProvider.notifier).show('${t.name} ${on ? 'enabled' : 'disabled'}');
                          },
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        [
                          t.recurring ? 'Recurring · ${_frequencyLabel(t.frequency)}' : 'One-time / ${t.frequency.name}',
                          if ((t.expectedAmount ?? 0) > 0) 'Expected ${money.npr(t.expectedAmount!)}' else 'No expected amount',
                          if (accounts.any((a) => a.id == t.defaultAccountId))
                            '→ ${accounts.firstWhere((a) => a.id == t.defaultAccountId).shortName}',
                          if (t.applicableDeductionIds.isNotEmpty) '${t.applicableDeductionIds.length} deductions apply',
                        ].join(' · '),
                        style: PaisaText.hint.copyWith(color: c.ink3),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: [
                        PaisaButton(
                          label: 'Edit',
                          small: true,
                          variant: ButtonVariant.outline,
                          onPressed: () => showIncomeTypeSheet(context, t),
                        ),
                        PaisaButton(
                          label: 'Add record',
                          small: true,
                          variant: ButtonVariant.secondary,
                          onPressed: t.active ? () => context.push('/income/new?type=${t.id}') : null,
                        ),
                        if (t.id == 'salary')
                          PaisaButton(
                            label: 'Salary settings',
                            small: true,
                            variant: ButtonVariant.ghost,
                            onPressed: () => context.push('/settings/salary'),
                          ),
                      ]),
                    ]),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _IncomeForm extends ChangeNotifier {
  _IncomeForm(IncomeType? t)
      : name = TextEditingController(text: t?.name ?? ''),
        description = TextEditingController(text: t?.description ?? ''),
        expected = TextEditingController(text: (t?.expectedAmount ?? 0) > 0 ? '${toWholeRupees(t!.expectedAmount!)}' : ''),
        recurring = t?.recurring ?? true,
        frequency = t?.frequency ?? IncomeFrequency.monthly,
        account = t?.defaultAccountId;
  final TextEditingController name, description, expected;
  bool recurring;
  IncomeFrequency frequency;
  String? account;
  String? nameError, expectedError;

  void update(void Function() f) {
    f();
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    expected.dispose();
    super.dispose();
  }
}

Future<void> showIncomeTypeSheet(BuildContext context, IncomeType? type) => showPaisaFormSheet<void, _IncomeForm>(
      context,
      title: type == null ? 'New income type' : 'Edit income type',
      create: () => _IncomeForm(type),
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final accounts = (ref.watch(accountsProvider).value ?? const <Account>[])
            .where((a) => !a.archived && (a.group == AccountGroup.liquid || a.group == AccountGroup.reserved))
            .toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaTextField(label: 'Name', controller: f.name, hint: 'e.g. Teaching Income', errorText: f.nameError),
          const SizedBox(height: 14),
          PaisaTextField(label: 'Description', controller: f.description, hint: 'Optional'),
          const SizedBox(height: 14),
          ToggleRow(
            title: 'Recurring',
            subtitle: 'Off for one-time income',
            value: f.recurring,
            onChanged: (v) => f.update(() => f.recurring = v),
          ),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'Frequency',
            child: ChipWrap(children: [
              for (final q in IncomeFrequency.values)
                PaisaChip(label: _frequencyLabel(q), selected: f.frequency == q, onTap: () => f.update(() => f.frequency = q)),
            ]),
          ),
          const SizedBox(height: 14),
          PaisaTextField(
            label: 'Expected amount (NPR)',
            controller: f.expected,
            hint: 'Optional',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.expectedError,
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            FieldGroup(
              label: 'Default account',
              child: ChipWrap(children: [
                for (final a in accounts)
                  PaisaChip(label: a.shortName, selected: f.account == a.id, onTap: () => f.update(() => f.account = a.id)),
              ]),
            ),
          ],
        ]);
      }),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Save',
              onPressed: () async {
                final expected = f.expected.text.trim().isEmpty ? null : parseNpr(f.expected.text);
                f.update(() {
                  f.nameError = f.name.text.trim().isEmpty ? 'Enter a name' : null;
                  f.expectedError = f.expected.text.trim().isNotEmpty && expected == null ? 'Enter a valid amount' : null;
                });
                if (f.nameError != null || f.expectedError != null) return;
                try {
                  await ref.read(catalogRepoProvider).saveIncomeType(IncomeType(
                        id: type?.id ?? '',
                        name: f.name.text,
                        description: f.description.text.trim().isEmpty ? null : f.description.text.trim(),
                        icon: type?.icon ?? 'moneyIn',
                        color: type?.color ?? 0xFF1F4FC4,
                        defaultAccountId: f.account,
                        recurring: f.recurring,
                        expectedAmount: expected,
                        frequency: f.frequency,
                        expectedDay: type?.expectedDay,
                        applicableDeductionIds: type?.applicableDeductionIds ?? const [],
                        active: type?.active ?? true,
                      ));
                } on DuplicateName {
                  f.update(() => f.nameError = 'An income type with this name already exists');
                  return;
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show(type == null ? '${f.name.text.trim()} added' : 'Income type updated');
              },
            ),
          ),
        ]),
      ),
    );

/// Settings → Expense categories.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    return DetailPage(
      title: 'Expense categories',
      actions: [PaisaLink(label: 'New', onPressed: () => showCategorySheet(context, null))],
      body: AsyncView(
        value: ref.watch(categoriesProvider),
        data: (all) {
          final top = all.where((x) => x.isTopLevel).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            Text(
              'Create your own categories. Essential categories feed the emergency-fund target.',
              style: PaisaText.sub.copyWith(color: c.ink3),
            ),
            const SizedBox(height: 12),
            PaisaListCard(children: [
              for (final x in top)
                Opacity(
                  opacity: x.active ? 1 : 0.6,
                  child: ListRow(
                    title: x.name,
                    subtitle: [
                      x.isAutomatic
                          ? 'Automatic from loan interest'
                          : (x.monthlyBudget ?? 0) > 0
                              ? 'Budget ${money.npr(x.monthlyBudget!)}/month'
                              : 'No budget',
                      if (x.essential) 'Essential',
                      ...all.where((s) => s.parentId == x.id).map((s) => s.name),
                    ].join(' · '),
                    leading: IconWell(icon: PaisaIcons.named(x.icon), size: 36),
                    onTap: x.isAutomatic ? null : () => showCategorySheet(context, x),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (x.custom)
                        PaisaIconButton(icon: PaisaIcons.trash, label: 'Delete ${x.name}', onPressed: () => _delete(context, ref, x)),
                      if (!x.isAutomatic)
                        PaisaToggle(
                          value: x.active,
                          label: '${x.active ? 'Disable' : 'Enable'} ${x.name}',
                          onChanged: (on) => ref.read(catalogRepoProvider).setCategoryActive(x.id, on),
                        ),
                    ]),
                  ),
                ),
            ]),
          ]);
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ExpenseCategory x) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${x.name}?',
      body: 'Existing transactions keep their history but show as Uncategorised.',
      okLabel: 'Delete category',
      okVariant: ButtonVariant.danger,
    );
    if (ok != ConfirmChoice.ok) return;
    await ref.read(catalogRepoProvider).deleteCategory(x.id);
    ref.read(toastProvider.notifier).show('Category deleted');
  }
}

class _CategoryForm extends ChangeNotifier {
  _CategoryForm(ExpenseCategory? x)
      : name = TextEditingController(text: x?.name ?? ''),
        budget = TextEditingController(text: (x?.monthlyBudget ?? 0) > 0 ? '${toWholeRupees(x!.monthlyBudget!)}' : ''),
        essential = x?.essential ?? false;
  final TextEditingController name, budget;
  bool essential;
  String? nameError, budgetError;

  void update(void Function() f) {
    f();
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    budget.dispose();
    super.dispose();
  }
}

Future<void> showCategorySheet(BuildContext context, ExpenseCategory? x) => showPaisaFormSheet<void, _CategoryForm>(
      context,
      title: x == null ? 'New category' : 'Edit category',
      create: () => _CategoryForm(x),
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PaisaTextField(label: 'Name', controller: f.name, hint: 'e.g. Pet care', errorText: f.nameError),
        const SizedBox(height: 14),
        PaisaTextField(
          label: 'Monthly budget (NPR)',
          controller: f.budget,
          hint: 'Optional',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: f.budgetError,
        ),
        const SizedBox(height: 14),
        ToggleRow(
          title: 'Essential expense',
          subtitle: 'Counts toward the emergency-fund target',
          value: f.essential,
          onChanged: (v) => f.update(() => f.essential = v),
        ),
      ]),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Save',
              onPressed: () async {
                final budget = f.budget.text.trim().isEmpty ? null : parseNpr(f.budget.text);
                f.update(() {
                  f.nameError = f.name.text.trim().isEmpty ? 'Enter a name' : null;
                  f.budgetError = f.budget.text.trim().isNotEmpty && budget == null ? 'Enter a valid amount' : null;
                });
                if (f.nameError != null || f.budgetError != null) return;
                try {
                  await ref.read(catalogRepoProvider).saveCategory(ExpenseCategory(
                        id: x?.id ?? '',
                        name: f.name.text,
                        icon: x?.icon ?? 'tag',
                        parentId: x?.parentId,
                        monthlyBudget: budget == 0 ? null : budget,
                        essential: f.essential,
                        system: x?.system,
                        active: x?.active ?? true,
                        custom: x?.custom ?? true,
                      ));
                } on DuplicateName {
                  f.update(() => f.nameError = 'A category with this name already exists');
                  return;
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show(x == null ? '${f.name.text.trim()} category added' : 'Category updated');
              },
            ),
          ),
        ]),
      ),
    );
