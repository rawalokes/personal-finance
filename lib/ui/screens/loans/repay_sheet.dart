import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../theme.dart';
import '../../typography.dart';

class _RepayForm extends ChangeNotifier {
  _RepayForm(Loan loan, IsoDate today)
      : amount = TextEditingController(text: '${toWholeRupees(loan.installment)}'),
        date = today,
        account = loan.repaymentAccountId {
    amount.addListener(notifyListeners);
  }

  final TextEditingController amount;
  IsoDate date;
  String? account;
  String? error;
  bool saving = false;

  void setDate(IsoDate d) {
    date = d;
    notifyListeners();
  }

  void setAccount(String id) {
    account = id;
    notifyListeners();
  }

  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  void setSaving(bool v) {
    saving = v;
    notifyListeners();
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }
}

/// Record a loan payment: amount, date and paying account, with the live
/// principal/interest split (only interest counts as spending).
Future<void> showRepaySheet(BuildContext context, Loan loan) => showPaisaFormSheet<void, _RepayForm>(
      context,
      title: 'Record repayment',
      create: () => _RepayForm(loan, ProviderScope.containerOf(context).read(clockProvider).today()),
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final accounts = (ref.watch(accountsProvider).value ?? const <Account>[])
            .where((a) => !a.archived && (a.group == AccountGroup.liquid || a.group == AccountGroup.reserved))
            .toList();
        final amount = parseNpr(f.amount.text) ?? 0;
        final split = splitRepayment(loan, amount);
        final selected = f.account ?? accounts.firstOrNull?.id;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${loan.name} · ${loan.lender}', style: PaisaText.sub.copyWith(color: ctx.colors.ink3)),
          const SizedBox(height: 14),
          PaisaTextField(
            label: 'Amount paid (NPR)',
            controller: f.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.error,
          ),
          const SizedBox(height: 14),
          DateField(label: 'Payment date', value: f.date, onChanged: f.setDate),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'Paid from',
            child: ChipWrap(children: [
              for (final a in accounts) PaisaChip(label: a.shortName, selected: a.id == selected, onTap: () => f.setAccount(a.id)),
            ]),
          ),
          const SizedBox(height: 14),
          Note(
            'Split: ${toastNpr(ref, split.principal)} principal · ${toastNpr(ref, split.interest)} interest. '
            'Only interest counts as an expense.',
            tone: Tone.positive,
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
              label: 'Record payment',
              onPressed: f.saving
                  ? null
                  : () async {
                      final amount = parseNpr(f.amount.text);
                      final accounts = (ref.read(accountsProvider).value ?? const <Account>[])
                          .where((a) => !a.archived && (a.group == AccountGroup.liquid || a.group == AccountGroup.reserved));
                      final account = f.account ?? accounts.firstOrNull?.id;
                      if (amount == null || amount <= 0) {
                        f.setError('Enter an amount greater than zero');
                        return;
                      }
                      if (account == null) {
                        f.setError('Add an account to pay from first');
                        return;
                      }
                      f.setSaving(true);
                      final toast = ref.read(toastProvider.notifier);
                      try {
                        final undo = await ref
                            .read(loanRepoProvider)
                            .recordRepayment(loan.id, amount: amount, date: f.date, fromAccountId: account);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        showUndoToast(toast, 'Repayment recorded · principal and interest split', undo);
                      } catch (_) {
                        if (ctx.mounted) f.setSaving(false);
                        toast.show('Couldn’t record the payment — nothing was changed');
                      }
                    },
            ),
          ),
        ]),
      ),
    );
