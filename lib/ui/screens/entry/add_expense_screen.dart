import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/undo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../accounts/add_account_sheet.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/party_field.dart';
import 'entry_data.dart';

/// Add expense (spec §7). Opened from Home / Activity, or an account's
/// "Money out" with [accountId] pre-selected.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.accountId});
  final String? accountId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  String _categoryId = 'groceries';
  String? _accountId;
  String? _partyId;
  late IsoDate _date = ref.read(clockProvider).today();
  bool _repeat = false;
  String? _amountError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accountId;
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  /// Top-level, active, user-chosen categories (Loan Interest is automatic).
  List<ExpenseCategory> _categories(EntryData d) =>
      d.categories.where((c) => c.active && c.isTopLevel && !c.isAutomatic).toList();

  List<Account> _choices(EntryData d) =>
      d.accountChoices({AccountGroup.liquid, AccountGroup.liability}, widget.accountId);

  String _account(List<Account> choices) {
    final chosen = _accountId;
    if (chosen != null && choices.any((a) => a.id == chosen)) return chosen;
    return choices.any((a) => a.id == 'nabil') ? 'nabil' : choices.first.id;
  }

  ExpenseCategory _category(EntryData d) {
    final cats = _categories(d);
    return cats.where((c) => c.id == _categoryId).firstOrNull ?? cats.first;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(entryDataProvider);
    return DetailPage(
      title: 'Add expense',
      isForm: true,
      body: AsyncView(value: data, data: _form),
      footer: SizedBox(
        width: double.infinity,
        child: PaisaButton(
          label: 'Save expense',
          onPressed: _saving || data.value == null || !_ready(data.value!) ? null : () => _save(data.value!),
        ),
      ),
    );
  }

  /// An account to pay from and a category to file under both exist.
  bool _ready(EntryData d) => _choices(d).isNotEmpty && _categories(d).isNotEmpty;

  Widget _form(EntryData d) {
    if (_choices(d).isEmpty) {
      return EmptyState(
        icon: PaisaIcons.wallet,
        title: 'Add an account first',
        body: 'Expenses are paid from a bank, wallet, cash or card account. Add one to record spending.',
        actionLabel: 'Add account',
        onAction: () => showAddAccountSheet(context),
      );
    }
    if (_categories(d).isEmpty) {
      return const EmptyState(
        icon: PaisaIcons.tag,
        title: 'No categories',
        body: 'Turn on at least one expense category to record spending.',
      );
    }
    final c = context.colors;
    final cat = _category(d);
    final choices = _choices(d);
    final account = _account(choices);
    final budget = cat.monthlyBudget;
    final spent = d.month.byCategory[cat.id] ?? 0;
    final used = spent < 0 ? 0 : spent;
    final after = used + (parseNpr(_amount.text) ?? 0);
    const gap = SizedBox(height: 16);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaTextField(
        label: 'Amount',
        controller: _amount,
        big: true,
        hint: '0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        errorText: _amountError,
      ),
      gap,
      FieldGroup(
        label: 'Category',
        footer: budget == null || budget <= 0
            ? null
            : Text(
                // Includes the month's stored spending, so it masks with hide balances.
                '${cat.name}: ${ref.watch(moneyFormatProvider).npr(after)} of ${ref.watch(moneyFormatProvider).npr(budget)} after this'
                '${after > budget ? ' — over budget' : ''}',
                style: PaisaText.numeric(PaisaText.hint.copyWith(color: after > budget ? c.red : c.ink3)),
              ),
        child: LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - 3 * 8) / 4;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final x in _categories(d))
              SizedBox(
                width: w,
                child: _CategoryTile(category: x, selected: x.id == cat.id, onTap: () => setState(() => _categoryId = x.id)),
              ),
          ]);
        }),
      ),
      gap,
      FieldGroup(
        label: 'Paid from',
        child: ChipWrap(children: [
          for (final a in choices)
            PaisaChip(label: a.shortName, selected: a.id == account, onTap: () => setState(() => _accountId = a.id)),
        ]),
      ),
      gap,
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: DateField(label: 'Date', value: _date, onChanged: (v) => setState(() => _date = v))),
        const SizedBox(width: 10),
        Expanded(child: PaisaTextField(label: 'Merchant', controller: _merchant, hint: 'e.g. Bhat-Bhateni')),
      ]),
      gap,
      PartyField(label: partyLabel(TxType.expense), value: _partyId, onChanged: (id) => setState(() => _partyId = id)),
      gap,
      PaisaCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ToggleRow(
          title: 'Repeat monthly',
          subtitle: 'Adds a recurring reminder',
          value: _repeat,
          onChanged: (v) => setState(() => _repeat = v),
          leading: const IconWell(icon: PaisaIcons.repeat, tone: Tone.blue, size: 36),
        ),
      ),
      ]),
    );
  }

  Future<void> _save(EntryData d) async {
    final amount = positiveAmount(_amount.text);
    if (amount == null) {
      setState(() => _amountError = kAmountError);
      return;
    }
    setState(() => _amountError = null);
    final cat = _category(d);
    final accountId = _account(_choices(d));
    final merchant = _merchant.text.trim();
    final title = merchant.isNotEmpty ? merchant : cat.name;
    final newId = ref.read(idGenProvider);
    final tx = Txn(
      id: newId(),
      date: _date,
      time: ref.read(clockProvider).hhmm(),
      title: title,
      type: TxType.expense,
      accountId: accountId,
      categoryId: cat.id,
      partyId: _partyId,
      amount: amount,
    );
    final toast = ref.read(toastProvider.notifier);
    setState(() => _saving = true);
    try {
      final txns = ref.read(transactionRepoProvider);
      final catalog = ref.read(catalogRepoProvider);
      final summary = 'Added expense $title · ${toastNpr(ref, amount)}';
      // One database transaction: if the repeat rule can't be saved, the
      // expense isn't either, so "nothing was changed" stays true.
      final undos = await ref.read(databaseProvider).transaction(() async => [
            await txns.add(tx, summary: summary),
            if (_repeat)
              await catalog.addRecurring(RecurringRule(
                id: newId(),
                name: title,
                kind: RecurringKind.expense,
                amount: amount,
                categoryId: cat.id,
                accountId: accountId,
                frequency: RecurringFrequency.monthly,
                nextDate: addMonths(_date, 1),
              )),
          ]);
      if (mounted) leavePage(context);
      showUndoToast(
        toast,
        'Expense saved · ${toastNpr(ref, amount)}${_repeat ? ' · repeats monthly' : ''}',
        UndoAction.combine(undos),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      toast.show('Couldn’t save — nothing was changed');
    }
  }
}

/// Category choice: icon above name, mint outline when selected.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});
  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.attentionBg : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? c.primary : c.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                PaisaIcon(PaisaIcons.named(category.icon), size: 19, color: selected ? c.attentionInk : c.ink2),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PaisaText.tag.copyWith(fontSize: 11.5, height: 1.2, color: c.ink),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
