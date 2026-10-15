import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repos/account_repo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../components/buttons.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../feedback.dart';
import '../../theme.dart';
import '../../typography.dart';

/// Quick picks (spec §7): name, type and SMS sender for common wallets/banks.
class _Preset {
  const _Preset(this.label, this.name, this.type, this.sender);
  final String label;
  final String name;
  final AccountTypeChoice type;
  final String sender;
}

const _presets = [
  _Preset('eSewa', 'eSewa — personal', AccountTypeChoice.wallet, 'eSewa'),
  _Preset('Khalti', 'Khalti — personal', AccountTypeChoice.wallet, 'Khalti'),
  _Preset('IME Pay', 'IME Pay — personal', AccountTypeChoice.wallet, 'IMEPay'),
  _Preset('Nabil Bank', 'Nabil Bank — savings', AccountTypeChoice.bank, 'NABIL_ALERT'),
  _Preset('NIC Asia Bank', 'NIC Asia Bank — savings', AccountTypeChoice.bank, 'NIC_ASIA'),
  _Preset('Global IME Bank', 'Global IME Bank — savings', AccountTypeChoice.bank, 'GIBL'),
  _Preset('Cash', 'Cash in hand', AccountTypeChoice.cash, ''),
];

/// Form state shared by the sheet body and its footer.
class _AddAccountForm extends ChangeNotifier {
  final name = TextEditingController();
  final balance = TextEditingController();
  final digits = TextEditingController();
  final sender = TextEditingController();
  _Preset? preset;
  AccountTypeChoice type = AccountTypeChoice.wallet;
  bool autoUpdate = true;
  String? nameError;
  String? balanceError;
  bool saving = false;

  void pick(_Preset p) {
    preset = p;
    name.text = p.name;
    type = p.type;
    sender.text = p.sender;
    autoUpdate = p.sender.isNotEmpty;
    notifyListeners();
  }

  void setType(AccountTypeChoice t) {
    type = t;
    notifyListeners();
  }

  void setSaving(bool v) {
    saving = v;
    notifyListeners();
  }

  void setAuto(bool v) {
    autoUpdate = v;
    notifyListeners();
  }

  /// Returns the input, or null after showing field errors.
  NewAccountInput? validate() {
    final amount = parseNpr(balance.text);
    nameError = name.text.trim().isEmpty ? 'Enter an account name' : null;
    balanceError = amount == null ? 'Enter the opening balance' : null;
    notifyListeners();
    if (nameError != null || amount == null) return null;
    return NewAccountInput(
      name: name.text,
      type: type,
      balance: amount,
      lastDigits: digits.text,
      smsSender: sender.text,
      autoUpdateFromSms: autoUpdate,
    );
  }

  @override
  void dispose() {
    for (final c in [name, balance, digits, sender]) {
      c.dispose();
    }
    super.dispose();
  }
}

/// "Add account" sheet: quick picks, name, type, balance (or amount owed),
/// last 4 digits, SMS sender and the auto-update toggle.
Future<void> showAddAccountSheet(BuildContext context) => showPaisaFormSheet<void, _AddAccountForm>(
      context,
      title: 'Add account',
      create: _AddAccountForm.new,
      body: (ctx, form) => _Body(form),
      footer: (ctx, form) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(
            child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop()),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(label: 'Add account', onPressed: form.saving ? null : () => _save(ctx, ref, form)),
          ),
        ]),
      ),
    );

Future<void> _save(BuildContext context, WidgetRef ref, _AddAccountForm form) async {
  final input = form.validate();
  if (input == null) return;
  form.setSaving(true);
  final toast = ref.read(toastProvider.notifier);
  try {
    final (account, undo) = await ref.read(accountRepoProvider).add(input);
    if (context.mounted) Navigator.of(context).pop();
    showUndoToast(toast, '${account.shortName} added · balance ${toastNpr(ref, account.balance)}', undo);
  } catch (_) {
    form.setSaving(false);
    toast.show('Couldn’t add the account — nothing was saved');
  }
}

class _Body extends StatelessWidget {
  const _Body(this.form);
  final _AddAccountForm form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final owed = form.type.group == AccountGroup.liability;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
        'Add a wallet, bank or card with its current balance. Linked SMS will add credits (Cr) and deduct debits (Dr) for you.',
        style: PaisaText.sub.copyWith(color: c.ink3),
      ),
      const SizedBox(height: 14),
      FieldGroup(
        label: 'Quick pick',
        child: ChipWrap(children: [
          for (final p in _presets) PaisaChip(label: p.label, selected: form.preset == p, onTap: () => form.pick(p)),
        ]),
      ),
      const SizedBox(height: 14),
      PaisaTextField(label: 'Account name', controller: form.name, hint: 'e.g. eSewa — personal', errorText: form.nameError),
      const SizedBox(height: 14),
      FieldGroup(
        label: 'Account type',
        child: ChipWrap(children: [
          for (final t in AccountTypeChoice.values)
            PaisaChip(label: t.label, selected: form.type == t, onTap: () => form.setType(t)),
        ]),
      ),
      const SizedBox(height: 14),
      PaisaTextField(
        label: owed ? 'Amount owed now (NPR)' : 'Current balance (NPR)',
        controller: form.balance,
        hint: '0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        errorText: form.balanceError,
      ),
      const SizedBox(height: 14),
      PaisaTextField(
        label: 'Last 4 digits (optional)',
        controller: form.digits,
        hint: 'e.g. 4821',
        keyboardType: TextInputType.number,
        helper: 'Used to match bank SMS to this account. Never store the full number.',
      ),
      const SizedBox(height: 14),
      PaisaTextField(label: 'SMS sender ID (optional)', controller: form.sender, hint: 'e.g. eSewa, Khalti, NABIL_ALERT'),
      const SizedBox(height: 14),
      ToggleRow(
        title: 'Update balance automatically from SMS',
        subtitle: 'Confident Dr/Cr messages are saved instantly; anything unclear still waits for review.',
        value: form.autoUpdate,
        onChanged: form.setAuto,
      ),
    ]);
  }
}
