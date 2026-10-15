import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repos/loan_repo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../loans/loan_presentation.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

class _FormData {
  const _FormData(this.types, this.accounts, this.loan);
  final List<LoanType> types;
  final List<Account> accounts;
  final Loan? loan;
}

final _formDataProvider = FutureProvider.family<_FormData, String?>((ref, loanId) async {
  final loans = await ref.watch(loansProvider.future);
  return _FormData(
    await ref.watch(loanTypesProvider.future),
    (await ref.watch(accountsProvider.future)).where((a) => !a.archived).toList(),
    loanId == null ? null : loans.where((l) => l.id == loanId).firstOrNull,
  );
});

/// Add a loan, or edit one ([loanId]). Paisa never assumes a term the user
/// hasn't entered: a blank rate stays "Not entered" (spec §5.4).
class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.loanId, this.typeId});
  final String? loanId;
  final String? typeId;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _name = TextEditingController();
  final _lender = TextEditingController();
  final _principal = TextEditingController();
  final _outstanding = TextEditingController();
  final _rate = TextEditingController();
  final _installment = TextEditingController();
  final _fees = TextEditingController();
  String? _typeId;
  InterestMethod _method = InterestMethod.reducing;
  LoanFrequency _frequency = LoanFrequency.monthly;
  IsoDate? _start;
  IsoDate? _maturity;
  late IsoDate _next = addMonths(ref.read(clockProvider).today(), 1);

  /// An edited loan that had no due date keeps none unless one is picked.
  bool _noDueDate = false;
  String? _accountId;
  bool _loaded = false;

  /// True while [_load] fills the fields during build, when the text
  /// listeners must not call setState.
  bool _filling = false;
  bool _saving = false;
  final _errors = <String, String>{};

  bool get _editing => widget.loanId != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_principal, _outstanding, _rate, _installment]) {
      c.addListener(() {
        if (!_filling) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _lender, _principal, _outstanding, _rate, _installment, _fees]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the fields once, from the loan being edited or the chosen type.
  void _load(_FormData d) {
    if (_loaded) return;
    _loaded = true;
    _filling = true;
    try {
      _fill(d);
    } finally {
      _filling = false;
    }
  }

  void _fill(_FormData d) {
    final l = d.loan;
    if (l != null) {
      _typeId = l.loanTypeId;
      _name.text = l.name;
      _lender.text = l.lender;
      _principal.text = plainRupees(l.principal);
      _outstanding.text = plainRupees(l.outstanding);
      _rate.text = l.ratePct == null || l.method == InterestMethod.none ? '' : '${l.ratePct}';
      _installment.text = plainRupees(l.installment);
      _fees.text = l.feesAndPrepayment ?? '';
      _method = l.method;
      _frequency = l.frequency;
      _start = l.startDate;
      _maturity = l.maturityDate;
      _next = l.nextDueDate ?? _next;
      _noDueDate = l.nextDueDate == null;
      _accountId = l.repaymentAccountId;
    } else {
      final active = d.types.where((t) => t.active).toList();
      final type = active.where((t) => t.id == widget.typeId).firstOrNull ??
          active.where((t) => t.id == 'personal').firstOrNull ??
          active.firstOrNull;
      _typeId = type?.id;
      _method = type?.defaultMethod ?? InterestMethod.reducing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_formDataProvider(widget.loanId));
    return DetailPage(
      title: _editing ? 'Edit loan' : 'Add a loan',
      isForm: true,
      body: AsyncView(
        value: data,
        data: (d) {
          _load(d);
          return _form(d);
        },
      ),
      footer: SizedBox(
        width: double.infinity,
        child: PaisaButton(
          label: _editing ? 'Save changes' : 'Save loan',
          onPressed: _saving || data.value == null ? null : () => _save(data.value!),
        ),
      ),
    );
  }

  Widget _form(_FormData d) {
    final c = context.colors;
    const gap = SizedBox(height: 16);
    final money = TextInputType.numberWithOptions(decimal: true);
    final accounts = d.accounts.where((a) => a.group == AccountGroup.liquid || a.group == AccountGroup.reserved).toList();
    final preview = _preview();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldGroup(
          label: 'Loan type',
          child: ChipWrap(children: [
            for (final t in d.types.where((t) => t.active || t.id == _typeId))
              PaisaChip(
                label: t.name,
                selected: t.id == _typeId,
                onTap: () => setState(() {
                  _typeId = t.id;
                  if (!_editing) _method = t.defaultMethod;
                }),
              ),
          ]),
        ),
        gap,
        PaisaTextField(label: 'Loan name', controller: _name, hint: 'e.g. Scooter loan', errorText: _errors['name']),
        gap,
        PaisaTextField(label: 'Lender', controller: _lender, hint: 'Bank, finance company or person', errorText: _errors['lender']),
        gap,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: PaisaTextField(label: 'Original principal', controller: _principal, keyboardType: money, errorText: _errors['principal']),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PaisaTextField(label: 'Outstanding now', controller: _outstanding, keyboardType: money, errorText: _errors['outstanding']),
          ),
        ]),
        gap,
        FieldGroup(
          label: 'Interest method',
          footer: Text(
            switch (_method) {
              InterestMethod.reducing => 'Interest on the outstanding balance — typical for bank loans in Nepal.',
              InterestMethod.flat => 'Interest on the original principal for the whole term.',
              InterestMethod.none => 'Interest-free, e.g. borrowing from family.',
            },
            style: PaisaText.hint.copyWith(color: c.ink3),
          ),
          child: ChipWrap(children: [
            for (final (m, label) in const [
              (InterestMethod.reducing, 'Reducing'),
              (InterestMethod.flat, 'Flat rate'),
              (InterestMethod.none, 'No interest'),
            ])
              PaisaChip(label: label, selected: m == _method, onTap: () => setState(() => _method = m)),
          ]),
        ),
        gap,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_method != InterestMethod.none) ...[
            Expanded(
              child: PaisaTextField(
                label: 'Interest rate (% p.a.)',
                controller: _rate,
                hint: 'Not entered',
                keyboardType: money,
                errorText: _errors['rate'],
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: PaisaTextField(label: 'Installment', controller: _installment, keyboardType: money, errorText: _errors['installment']),
          ),
        ]),
        gap,
        FieldGroup(
          label: 'Payment frequency',
          child: ChipWrap(children: [
            for (final f in LoanFrequency.values)
              PaisaChip(label: frequencyLabel(f), selected: f == _frequency, onTap: () => setState(() => _frequency = f)),
          ]),
        ),
        gap,
        DateField(
          label: 'Next due date',
          value: _next,
          onChanged: (v) => setState(() {
            _next = v;
            _noDueDate = false;
          }),
        ),
        gap,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: OptionalDateField(
              label: 'Start date',
              value: _start,
              onChanged: (v) => setState(() => _start = v),
              initialPick: ref.read(clockProvider).today(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OptionalDateField(
              label: 'Maturity date',
              value: _maturity,
              onChanged: (v) => setState(() => _maturity = v),
              initialPick: addMonths(ref.read(clockProvider).today(), 36),
            ),
          ),
        ]),
        gap,
        FieldGroup(
          label: 'Repayment account',
          child: accounts.isEmpty
              ? Text('Add an account to pay from later.', style: PaisaText.sub.copyWith(color: c.ink3))
              : ChipWrap(children: [
                  for (final a in accounts)
                    PaisaChip(label: a.shortName, selected: a.id == _accountId, onTap: () => setState(() => _accountId = a.id)),
                ]),
        ),
        gap,
        PaisaTextField(label: 'Fees & prepayment conditions', controller: _fees, hint: 'Optional, e.g. 1% fee on prepayment'),
        if (preview != null) ...[
          gap,
          Note(preview.$1, tone: preview.$2),
        ],
        gap,
        Text(
          'Paisa never assumes terms you haven’t entered. Leave a field blank if you don’t know it yet.',
          style: PaisaText.hint.copyWith(color: c.ink3),
        ),
      ]),
    );
  }

  /// "Repaid in about N installments", or why it never would be.
  (String, Tone)? _preview() {
    final out = parseNpr(_outstanding.text);
    final inst = parseNpr(_installment.text);
    if (out == null || out <= 0 || inst == null || inst <= 0) return null;
    final rate = _method == InterestMethod.none ? 0.0 : double.tryParse(_rate.text.trim());
    final probe = Loan(
      id: 'preview', loanTypeId: '', name: '', lender: '', principal: parseNpr(_principal.text) ?? out, outstanding: out,
      ratePct: rate, method: _method, installment: inst, frequency: _frequency, nextDueDate: _next,
    );
    final s = buildSchedule(probe, maxRows: 0);
    if (s.neverRepaid) return ('This installment does not cover the interest — the loan would never be repaid.', Tone.red);
    final missing = _method != InterestMethod.none && rate == null;
    return (
      'At this installment the loan is repaid in about ${s.periods} installments'
          '${missing ? ' (interest not entered — estimate excludes interest).' : '.'}',
      missing ? Tone.amber : Tone.positive,
    );
  }

  Future<void> _save(_FormData d) async {
    final principal = parseNpr(_principal.text);
    final outstanding = parseNpr(_outstanding.text);
    final installment = parseNpr(_installment.text);
    final rateText = _rate.text.trim();
    final rate = rateText.isEmpty ? null : double.tryParse(rateText);
    final e = <String, String>{};
    if (_name.text.trim().isEmpty) e['name'] = 'Give this loan a name';
    if (_lender.text.trim().isEmpty) e['lender'] = 'Who lent the money?';
    if (principal == null || principal <= 0) e['principal'] = 'Enter the original amount';
    if (outstanding == null) {
      e['outstanding'] = 'Enter what you still owe';
    } else if (principal != null && outstanding > principal) {
      e['outstanding'] = 'Can’t exceed the original principal';
    }
    if (installment == null || installment <= 0) e['installment'] = 'Enter the installment';
    if (_method != InterestMethod.none && rateText.isNotEmpty && (rate == null || rate < 0 || rate > 100)) {
      e['rate'] = 'Enter a rate between 0 and 100, or leave it blank';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(e);
    });
    final toast = ref.read(toastProvider.notifier);
    if (e.isNotEmpty) {
      toast.show('Please fix the highlighted fields');
      return;
    }
    final type = d.types.where((t) => t.id == _typeId).firstOrNull;
    if (type == null) {
      toast.show('Add a loan type first');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(loanRepoProvider);
    final router = GoRouter.of(context);
    try {
      if (_editing) {
        final undo = await repo.update(d.loan!.copyWithTerms(
          loanTypeId: type.id,
          name: _name.text.trim(),
          lender: _lender.text.trim(),
          principal: principal,
          outstanding: outstanding,
          ratePct: _method == InterestMethod.none ? 0 : rate,
          clearRate: _method != InterestMethod.none && rate == null,
          method: _method,
          installment: installment,
          frequency: _frequency,
          startDate: _start,
          maturityDate: _maturity,
          nextDueDate: _noDueDate ? null : _next,
          repaymentAccountId: _accountId,
          feesAndPrepayment: _fees.text.trim(),
        ));
        if (mounted) leavePage(context);
        showUndoToast(toast, 'Loan updated', undo);
      } else {
        final (loan, undo) = await repo.add(LoanInput(
          loanTypeId: type.id,
          name: _name.text,
          lender: _lender.text,
          principal: principal!,
          outstanding: outstanding!,
          ratePct: rate,
          method: _method,
          installment: installment!,
          frequency: _frequency,
          startDate: _start,
          maturityDate: _maturity,
          nextDueDate: _next,
          repaymentAccountId: _accountId,
          feesAndPrepayment: _fees.text,
        ));
        router.pushReplacement('/loans/${loan.id}');
        showUndoToast(toast, 'Loan added under ${type.name}', undo);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      toast.show('Couldn’t save the loan — nothing was changed');
    }
  }
}
