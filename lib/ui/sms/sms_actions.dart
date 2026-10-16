import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/records.dart';
import '../../data/repos/sms_repo.dart';
import '../../finance/finance.dart';
import '../../sms/sms_models.dart';
import '../../store/data_providers.dart';
import '../../store/sms_sync.dart';
import '../components/buttons.dart';
import '../components/dialog.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/sheet.dart';
import '../components/surfaces.dart';
import '../components/text_field.dart';
import '../components/toast.dart';
import '../feedback.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../typography.dart';
import '../txn/party_field.dart';
import '../txn/txn_presentation.dart';
import 'sms_presentation.dart';

final _confirming = <String>{};

/// Confirm, with the duplicate dialog (acceptance 12). True if saved.
/// A second tap while the first is saving does nothing.
Future<bool> confirmSmsFlow(BuildContext context, WidgetRef ref, SmsMessage m) async {
  if (!_confirming.add(m.id)) return false;
  try {
    return await _confirmSms(context, ref, m);
  } finally {
    _confirming.remove(m.id);
  }
}

Future<bool> _confirmSms(BuildContext context, WidgetRef ref, SmsMessage m) async {
  final repo = ref.read(smsRepoProvider);
  final toast = ref.read(toastProvider.notifier);
  Future<bool> save({required bool force}) async {
    final undo = await repo.confirm(m.id, force: force);
    showUndoToast(toast, '${kTxTypeInfo[m.type]!.name} saved · ${toastNpr(ref, m.amount)}', undo);
    return true;
  }

  try {
    return await save(force: false);
  } on SmsPossibleDuplicate catch (e) {
    if (!context.mounted) return false;
    final o = e.original;
    final choice = await showConfirmDialog(
      context,
      title: 'This looks like a duplicate',
      body: o == null
          ? 'Another message with the same amount arrived on the same account. Saving both would count it twice.'
          : 'A message for ${toastNpr(ref, o.amount)} at ${o.merchant} arrived at ${o.time} on the same account. '
              'Saving both would count this purchase twice.',
      okLabel: 'Ignore duplicate',
      altLabel: 'Save anyway',
    );
    if (choice == ConfirmChoice.ok) {
      final undo = await repo.reject(m.id);
      showUndoToast(toast, 'Duplicate ignored', undo);
      return true;
    }
    if (choice == ConfirmChoice.alt) {
      try {
        return await save(force: true);
      } on SmsNotReady catch (e) {
        toast.show(e.message);
      }
    }
    return false;
  } on SmsNotReady catch (e) {
    toast.show(e.message);
    return false;
  }
}

/// Ignore, after asking (spec §6: reject with confirmation). True if done.
Future<bool> rejectSmsFlow(BuildContext context, WidgetRef ref, SmsMessage m) async {
  final choice = await showConfirmDialog(
    context,
    title: 'Ignore this message?',
    body: 'It won’t be counted in any balance, budget or report. You can restore it later from Rejected / Ignored.',
    okLabel: 'Ignore message',
    okVariant: ButtonVariant.danger,
  );
  if (choice != ConfirmChoice.ok) return false;
  final undo = await ref.read(smsRepoProvider).reject(m.id);
  showUndoToast(ref.read(toastProvider.notifier), 'Message ignored', undo);
  return true;
}

Future<void> laterSms(WidgetRef ref, SmsMessage m) async {
  await ref.read(smsRepoProvider).later(m.id);
  ref.read(toastProvider.notifier).show('Moved to the end of Needs review');
}

Future<void> restoreSms(WidgetRef ref, SmsMessage m) async {
  await ref.read(smsRepoProvider).restore(m.id);
  ref.read(toastProvider.notifier).show('Restored to Needs review');
}

/// Transaction type sheet.
Future<void> showSmsTypeSheet(BuildContext context, SmsMessage m) => showPaisaSheet<void>(
      context,
      title: 'Transaction type',
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final c = ctx.colors;
          return PaisaListCard(children: [
            for (final t in kSmsTypes)
              ListRow(
                title: kTxTypeInfo[t]!.name,
                subtitle: kTxTypeInfo[t]!.description,
                leading: PaisaIcon(kTxTypeInfo[t]!.icon, size: 20, color: c.ink2),
                trailing: t == m.type ? PaisaIcon(PaisaIcons.check, size: 20, color: c.primary) : null,
                onTap: () async {
                  await ref.read(smsRepoProvider).setType(m.id, t);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.read(toastProvider.notifier).show('Type set to ${kTxTypeInfo[t]!.name} · accounting updated');
                },
              ),
          ]);
        },
      ),
    );

/// Category (expense, refund) or income type (income) sheet.
Future<void> showSmsCategorySheet(BuildContext context, SmsMessage m) => showPaisaSheet<void>(
      context,
      title: m.type == TxType.income ? 'Income type' : 'Category',
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final c = ctx.colors;
          final options = m.type == TxType.income
              ? [for (final t in ref.watch(incomeTypesProvider).value ?? const <IncomeType>[]) if (t.active) (t.id, t.name)]
              : [
                  for (final x in ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[])
                    if (x.active && x.isTopLevel && x.system == null) (x.id, x.name),
                ];
          final current = m.type == TxType.income ? m.incomeTypeId : m.categoryId;
          return PaisaListCard(children: [
            for (final (id, name) in options)
              ListRow(
                title: name,
                trailing: id == current ? PaisaIcon(PaisaIcons.check, size: 20, color: c.primary) : null,
                onTap: () async {
                  await ref.read(smsRepoProvider).setCategory(m.id, id);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.read(toastProvider.notifier).show('Category updated');
                },
              ),
          ]);
        },
      ),
    );

class _EditForm extends ChangeNotifier {
  _EditForm(SmsMessage m)
      : amount = TextEditingController(text: plainRupees(m.amount)),
        time = TextEditingController(text: m.time),
        merchant = TextEditingController(text: m.merchant),
        description = TextEditingController(text: m.description ?? ''),
        account = m.accountId,
        counter = m.counterAccountId,
        loan = m.loanId,
        party = m.partyId,
        date = m.date;

  final TextEditingController amount, time, merchant, description;
  String? account, counter, loan, party;

  /// False until the user picks a party; until then a party whose name is
  /// in the merchant text is suggested.
  bool partyPicked = false;

  String? partyOr(List<ConfigItem> parties, SmsMessage m) =>
      partyPicked || party != null ? party : guessParty(parties, m.merchant);
  IsoDate date;
  Map<String, String> errors = const {};

  void set(void Function() change) {
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    amount.dispose();
    time.dispose();
    merchant.dispose();
    description.dispose();
    super.dispose();
  }
}

/// Edit details: amount, account, other account, loan, party, date, time,
/// merchant and description (spec §7 Edit bottom sheet).
Future<void> showSmsEditSheet(BuildContext context, SmsMessage m) => showPaisaFormSheet<void, _EditForm>(
      context,
      title: 'Edit details',
      create: () => _EditForm(m),
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final accounts = [for (final a in ref.watch(accountsProvider).value ?? const <Account>[]) if (!a.archived) a];
        final loans = [for (final l in ref.watch(loansProvider).value ?? const <Loan>[]) if (!l.closed) l];
        final needsCounter = {TxType.transfer, TxType.cashWithdrawal, TxType.ccPayment}.contains(m.type);
        final needsLoan = m.type == TxType.loanRepayment || m.type == TxType.loanDisbursement;
        final parties = ref.watch(configListProvider(ConfigList.parties)).value ?? const <ConfigItem>[];
        Widget gap() => const SizedBox(height: 14);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaTextField(
            label: 'Amount (NPR)',
            controller: f.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.errors['amount'],
          ),
          gap(),
          FieldGroup(
            label: 'Account',
            footer: f.errors['account'] == null ? null : Text(f.errors['account']!, style: PaisaText.hint.copyWith(color: ctx.colors.red)),
            child: accounts.isEmpty
                ? Text('No accounts yet. Add one in the Accounts tab first.', style: PaisaText.sub.copyWith(color: ctx.colors.ink3))
                : ChipWrap(children: [
                    for (final a in accounts)
                      PaisaChip(label: a.shortName, selected: a.id == f.account, onTap: () => f.set(() => f.account = a.id)),
                  ]),
          ),
          if (hasParty(m.type)) ...[
            gap(),
            PartyField(
              label: partyLabel(m.type),
              value: f.partyOr(parties, m),
              onChanged: (id) => f.set(() {
                f.party = id;
                f.partyPicked = true;
              }),
            ),
          ],
          if (needsCounter) ...[
            gap(),
            FieldGroup(
              label: m.type == TxType.ccPayment ? 'Credit card' : (m.direction == Direction.debit ? 'To account' : 'From account'),
              footer: f.errors['counter'] == null ? null : Text(f.errors['counter']!, style: PaisaText.hint.copyWith(color: ctx.colors.red)),
              child: ChipWrap(children: [
                for (final a in accounts)
                  if (a.id != f.account) PaisaChip(label: a.shortName, selected: a.id == f.counter, onTap: () => f.set(() => f.counter = a.id)),
              ]),
            ),
          ],
          if (needsLoan) ...[
            gap(),
            FieldGroup(
              label: 'Loan',
              footer: f.errors['loan'] == null ? null : Text(f.errors['loan']!, style: PaisaText.hint.copyWith(color: ctx.colors.red)),
              child: ChipWrap(children: [
                for (final l in loans) PaisaChip(label: l.name, selected: l.id == f.loan, onTap: () => f.set(() => f.loan = l.id)),
              ]),
            ),
          ],
          gap(),
          DateField(label: 'Date', value: f.date, onChanged: (d) => f.set(() => f.date = d)),
          gap(),
          PaisaTextField(label: 'Time (HH:mm)', controller: f.time, keyboardType: TextInputType.datetime, errorText: f.errors['time']),
          gap(),
          PaisaTextField(label: 'Merchant / remark', controller: f.merchant),
          gap(),
          PaisaTextField(label: 'Description (optional)', controller: f.description, maxLines: 3),
        ]);
      }),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Save details',
              onPressed: () async {
                final amount = parseNpr(f.amount.text);
                final needsCounter = {TxType.transfer, TxType.cashWithdrawal, TxType.ccPayment}.contains(m.type);
                final needsLoan = m.type == TxType.loanRepayment || m.type == TxType.loanDisbursement;
                final errors = <String, String>{
                  if (amount == null || amount <= 0) 'amount': 'Enter an amount greater than zero',
                  if (f.account == null) 'account': 'Pick the account',
                  if (needsCounter && (f.counter == null || f.counter == f.account)) 'counter': 'Choose a different account',
                  if (needsLoan && f.loan == null) 'loan': 'Pick the loan',
                  if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(f.time.text.trim())) 'time': 'Use 24-hour time, e.g. 08:41',
                };
                if (errors.isNotEmpty) {
                  f.set(() => f.errors = errors);
                  return;
                }
                await ref.read(smsRepoProvider).edit(
                      m.id,
                      SmsEdit(
                        amount: amount!,
                        accountId: f.account!,
                        counterAccountId: needsCounter ? f.counter : null,
                        loanId: needsLoan ? f.loan : null,
                        partyId: f.partyOr(ref.read(configListProvider(ConfigList.parties)).value ?? const [], m),
                        date: f.date,
                        time: f.time.text.trim(),
                        merchant: f.merchant.text,
                        description: f.description.text.trim().isEmpty ? null : f.description.text.trim(),
                      ),
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show('Details updated — review and confirm');
              },
            ),
          ),
        ]),
      ),
    );

class _PasteForm extends ChangeNotifier {
  final body = TextEditingController();
  String? sender;
  String? error;
  bool busy = false;

  void set(void Function() change) {
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }
}

/// "Paste an SMS": the fallback when Paisa can't read SMS (spec §6 (c)).
Future<void> showPasteSmsSheet(BuildContext context) => showPaisaFormSheet<void, _PasteForm>(
      context,
      title: 'Paste an SMS',
      create: _PasteForm.new,
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final senders = ref.watch(trustedSendersProvider).value ?? const <String>[];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            'Copy a bank or wallet message from your SMS app and paste it here. It goes to the inbox for review.',
            style: PaisaText.sub.copyWith(color: ctx.colors.ink3),
          ),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'From',
            child: ChipWrap(children: [
              for (final s in senders) PaisaChip(label: s, selected: s == f.sender, onTap: () => f.set(() => f.sender = s)),
            ]),
          ),
          const SizedBox(height: 14),
          PaisaTextField(label: 'Message text', controller: f.body, maxLines: 6, errorText: f.error),
        ]);
      }),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => SizedBox(
          width: double.infinity,
          child: PaisaButton(
            label: 'Add to inbox',
            onPressed: f.busy
                ? null
                : () async {
                    final sender = f.sender;
                    if (sender == null) {
                      f.set(() => f.error = 'Pick who sent it');
                      return;
                    }
                    if (f.body.text.trim().isEmpty) {
                      f.set(() => f.error = 'Paste the message text');
                      return;
                    }
                    f.set(() => f.busy = true);
                    final toast = ref.read(toastProvider.notifier);
                    final r = await ref.read(smsSyncProvider).paste(sender: sender, body: f.body.text.trim());
                    switch (r.outcome) {
                      case IngestOutcome.ignored:
                        f.set(() {
                          f.busy = false;
                          f.error = 'This doesn’t look like a bank or wallet transaction';
                        });
                        return;
                      case IngestOutcome.alreadySeen:
                        toast.show('That message is already in the inbox');
                      case IngestOutcome.inbox:
                        toast.show('Added to the inbox — review and confirm');
                      case IngestOutcome.autoSaved:
                        showUndoToast(toast, 'Auto-saved from SMS · ${toastNpr(ref, r.message!.amount)}', r.undo!);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
          ),
        ),
      ),
    );
