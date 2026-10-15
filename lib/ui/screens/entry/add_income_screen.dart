import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/salary_settings.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../accounts/add_account_sheet.dart';
import '../../theme.dart';
import '../../typography.dart';
import 'entry_data.dart';

enum _SalaryMode { takeHome, gross }

/// Add income (spec §7). Opened from Home (salary first) or an account's
/// "Money in" ([accountId] pre-selected, Other Income first).
class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key, this.accountId});
  final String? accountId;

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _amount = TextEditingController();
  late final TextEditingController _gross;
  final _desc = TextEditingController();
  late String _typeId = widget.accountId == null ? 'salary' : 'other_inc';
  String? _accountId;
  _SalaryMode _mode = _SalaryMode.takeHome;
  bool _pending = false;
  late IsoDate _date = ref.read(clockProvider).today();
  String? _amountError;
  String? _grossError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.accountId;
    final gross = ref.read(salarySettingsProvider).grossMonthly;
    _gross = TextEditingController(text: gross > 0 ? '${toWholeRupees(gross)}' : '');
    _gross.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _gross.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _isSalary => _typeId == 'salary';
  bool get _grossMode => _isSalary && _mode == _SalaryMode.gross;

  /// The type's default account, unless an account page opened the form.
  String _accountFor(EntryData d, List<Account> choices) {
    final chosen = _accountId;
    if (chosen != null && choices.any((a) => a.id == chosen)) return chosen;
    final typeDefault = d.incomeTypes.where((t) => t.id == _typeId).firstOrNull?.defaultAccountId;
    if (typeDefault != null && choices.any((a) => a.id == typeDefault)) return typeDefault;
    return choices.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(entryDataProvider);
    return DetailPage(
      title: 'Add income',
      isForm: true,
      body: AsyncView(value: data, data: _form),
      footer: SizedBox(
        width: double.infinity,
        child: PaisaButton(
          label: 'Save income',
          onPressed: _saving || data.value == null || _choices(data.value!).isEmpty ? null : () => _save(data.value!),
        ),
      ),
    );
  }

  List<Account> _choices(EntryData d) =>
      d.accountChoices({AccountGroup.liquid, AccountGroup.reserved}, widget.accountId);

  Widget _form(EntryData d) {
    if (_choices(d).isEmpty) {
      return EmptyState(
        icon: PaisaIcons.wallet,
        title: 'Add an account first',
        body: 'Income goes into a bank, wallet, cash or savings account. Add one to record it.',
        actionLabel: 'Add account',
        onAction: () => showAddAccountSheet(context),
      );
    }
    final c = context.colors;
    final salary = ref.watch(salarySettingsProvider);
    final types = d.incomeTypes.where((t) => t.active).toList();
    final choices = d.accountChoices({AccountGroup.liquid, AccountGroup.reserved}, widget.accountId);
    final account = _accountFor(d, choices);
    const gap = SizedBox(height: 16);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FieldGroup(
        label: 'Income type',
        child: ChipWrap(children: [
          for (final t in types)
            PaisaChip(
              label: t.name,
              selected: t.id == _typeId,
              onTap: () => setState(() {
                _typeId = t.id;
                if (widget.accountId == null) _accountId = null;
                _amountError = _grossError = null;
              }),
            ),
        ]),
      ),
      if (_isSalary) ...[
        gap,
        FieldGroup(
          label: 'I’m entering',
          child: Segmented<_SalaryMode>(
            segments: const [(_SalaryMode.takeHome, 'Take-home (net)'), (_SalaryMode.gross, 'Gross salary')],
            selected: _mode,
            onChanged: (m) => setState(() => _mode = m),
          ),
        ),
      ],
      gap,
      if (_grossMode) ..._grossSection(salary) else ..._amountSection(),
      gap,
      FieldGroup(
        label: 'Received in',
        child: ChipWrap(children: [
          for (final a in choices)
            PaisaChip(label: a.shortName, selected: a.id == account, onTap: () => setState(() => _accountId = a.id)),
        ]),
      ),
      gap,
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: DateField(label: 'Date', value: _date, onChanged: (v) => setState(() => _date = v))),
        const SizedBox(width: 10),
        Expanded(
          child: FieldGroup(
            label: 'Status',
            child: Segmented<bool>(
              segments: const [(false, 'Received'), (true, 'Pending')],
              selected: _pending,
              onChanged: (v) => setState(() => _pending = v),
            ),
          ),
        ),
      ]),
      gap,
      PaisaTextField(label: 'Description (optional)', controller: _desc, hint: 'e.g. Asoj salary'),
      if (_pending) ...[
        const SizedBox(height: 10),
        Text(
          'Pending income is shown in history but not added to balances or totals until received.',
          style: PaisaText.hint.copyWith(color: c.ink3),
        ),
      ],
      ]),
    );
  }

  List<Widget> _amountSection() => [
        PaisaTextField(
          label: _isSalary ? 'Take-home amount received' : 'Amount',
          controller: _amount,
          big: true,
          hint: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _amountError,
        ),
        if (_isSalary) ...[
          const SizedBox(height: 10),
          const Note(
            'Take-home is recorded as is. Tax, SSF and CIT were already deducted by payroll, so Paisa won’t deduct them again.',
            tone: Tone.positive,
            icon: PaisaIcons.check,
          ),
        ],
      ];

  List<Widget> _grossSection(SalarySettings salary) {
    final c = context.colors;
    final gross = positiveAmount(_gross.text);
    final b = gross == null ? null : salary.breakdown(gross, asOf: _date);
    final red = PaisaText.numeric(PaisaText.body.copyWith(fontSize: 14, color: c.red));
    return [
      PaisaTextField(
        label: 'Gross monthly salary',
        controller: _gross,
        big: true,
        hint: '0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        errorText: _grossError,
      ),
      const SizedBox(height: 12),
      KeyValueCard(rows: [
        if (b != null) ...[
          KeyValueRow('Gross salary', value: toastNpr(ref, b.gross)),
          KeyValueRow('− Income tax (TDS)', valueWidget: Text(toastNpr(ref, b.monthlyTax), style: red)),
          for (final l in b.employeeLines) KeyValueRow('− ${l.name}', valueWidget: Text(toastNpr(ref, l.amount), style: red)),
        ],
        KeyValueRow(
          'Take-home to record',
          valueWidget: Text(
            b == null ? '—' : toastNpr(ref, b.takeHome),
            style: PaisaText.numeric(PaisaText.h2.copyWith(color: c.positive)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Text(
        'Deductions come from Salary & Deductions settings (sample defaults). Employer contributions are not taken from your pay.',
        style: PaisaText.hint.copyWith(color: c.ink3),
      ),
      const SizedBox(height: 10),
      const Note(kSampleDefaultsBanner, tone: Tone.amber, icon: PaisaIcons.info),
    ];
  }

  Future<void> _save(EntryData d) async {
    final salary = ref.read(salarySettingsProvider);
    Paisa? amount;
    setState(() => _amountError = _grossError = null);
    if (_grossMode) {
      final gross = positiveAmount(_gross.text);
      if (gross == null) {
        setState(() => _grossError = 'Enter your gross salary');
        return;
      }
      // Whole rupees, as payslips and the salary SMS state it.
      amount = fromRupees(toWholeRupees(salary.breakdown(gross, asOf: _date).takeHome));
    } else {
      amount = positiveAmount(_amount.text);
      if (amount == null) {
        setState(() => _amountError = kAmountError);
        return;
      }
    }
    final choices = d.accountChoices({AccountGroup.liquid, AccountGroup.reserved}, widget.accountId);
    final typeName = d.incomeTypes.where((t) => t.id == _typeId).firstOrNull?.name ?? 'Income';
    final desc = _desc.text.trim();
    final clock = ref.read(clockProvider);
    final tx = Txn(
      id: ref.read(idGenProvider)(),
      date: _date,
      time: clock.hhmm(),
      title: desc.isNotEmpty
          ? desc
          : _isSalary && salary.employer.isNotEmpty
              ? 'Salary — ${salary.employer}'
              : typeName,
      type: TxType.income,
      accountId: _accountFor(d, choices),
      incomeTypeId: _typeId,
      amount: amount,
      status: _pending ? TxStatus.pending : TxStatus.posted,
    );
    final toast = ref.read(toastProvider.notifier);
    setState(() => _saving = true);
    try {
      final undo = await ref.read(transactionRepoProvider).add(tx, summary: 'Added income ${tx.title} · ${toastNpr(ref, amount)}');
      if (mounted) leavePage(context);
      showUndoToast(toast, '${_pending ? 'Pending income added' : 'Income saved'} · ${toastNpr(ref, amount)}', undo);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      toast.show('Couldn’t save — nothing was changed');
    }
  }
}
