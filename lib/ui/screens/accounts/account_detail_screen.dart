import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/records.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../accounts/account_presentation.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/dialog.dart';
import '../../components/empty_state.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/transaction_tile.dart';
import '../../txn/txn_presentation.dart';
import '../../txn/txn_sheet.dart';
import 'reconcile_sheet.dart';

class _DetailData {
  const _DetailData(this.account, this.txns, this.types, this.lookup);
  final Account? account;
  final List<Txn> txns;
  final List<ConfigItem> types;
  final TxnLookup lookup;
}

final _detailProvider = FutureProvider.family<_DetailData, String>((ref, id) async {
  final accounts = await ref.watch(accountsProvider.future);
  return _DetailData(
    accounts.where((a) => a.id == id).firstOrNull,
    await ref.watch(accountTransactionsProvider(id).future),
    await ref.watch(accountTypesProvider.future),
    await ref.watch(txnLookupProvider.future),
  );
});

/// One account: balance, actions (Money in / out, Reconcile, Archive),
/// SMS auto-update, facts and its activity.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_detailProvider(accountId));
    return DetailPage(
      title: data.value?.account?.name ?? 'Account',
      body: AsyncView(
        value: data,
        data: (d) => d.account == null
            ? const EmptyState(
                icon: PaisaIcons.wallet,
                title: 'Account not found',
                body: 'It may have been removed. Go back to see your accounts.',
              )
            : _DetailBody(d),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody(this.d);
  final _DetailData d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final a = d.account!;
    final owed = isOwed(a.group, a.balance);
    final liability = a.group == AccountGroup.liability;
    final (tagText, tagTone) = groupTag(a.group);
    final money = ref.watch(moneyFormatProvider);
    final today = ref.watch(clockProvider).today();
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [Tag(tagText, tone: tagTone), Tag(accountTypeLabel(a, d.types))]),
              const SizedBox(height: 14),
              Text(
                liability ? (owed || a.balance == 0 ? 'Amount owed' : 'In credit') : 'Current balance',
                style: PaisaText.sub.copyWith(color: c.ink3),
              ),
              const SizedBox(height: 4),
              MoneyText(
                shownBalance(a.group, a.balance),
                color: owed ? c.red : c.ink,
                style: PaisaText.h1.copyWith(fontSize: 32, fontVariations: const [FontVariation('wght', 650)]),
              ),
              if (a.note != null) ...[
                const SizedBox(height: 8),
                Text(a.note!, style: PaisaText.sub.copyWith(color: c.ink3)),
              ],
              if (a.creditLimit != null && a.creditLimit! > 0) ...[
                const SizedBox(height: 12),
                ProgressBar(value: a.balance / a.creditLimit!, color: c.amber, semanticLabel: 'Credit limit used'),
                const SizedBox(height: 6),
                Text(
                  '${money.npr(a.balance)} used of ${money.npr(a.creditLimit!)} limit'
                  '${a.statementDueDate == null ? '' : ' · statement due ${shortDate(a.statementDueDate)}'}',
                  style: PaisaText.hint.copyWith(color: c.ink3),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (final (i, (icon, label, onTap)) in <(String, String, VoidCallback)>[
              (PaisaIcons.moneyIn, 'Money in', () => context.push('/income/new?account=${a.id}')),
              (PaisaIcons.moneyOut, 'Money out', () => context.push('/expense/new?account=${a.id}')),
              (PaisaIcons.scale, 'Reconcile', () => showReconcileSheet(context, a)),
              (PaisaIcons.archive, 'Archive', () => _archive(context, ref, a)),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _ActionTile(icon: icon, label: label, onTap: onTap)),
            ],
          ]),
          const SizedBox(height: 12),
          PaisaCard(
            child: Column(children: [
              Row(children: [
                const IconWell(icon: PaisaIcons.sms, tone: Tone.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SMS updates', style: PaisaText.h3.copyWith(color: c.ink)),
                    Text(
                      a.smsSender == null
                          ? 'No SMS sender linked — add one when you create the account'
                          : 'Reads messages from sender “${a.smsSender}”'
                              '${a.maskedNumber == null ? '' : ' for ••${a.maskedNumber}'}',
                      style: PaisaText.sub.copyWith(color: c.ink3),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              ToggleRow(
                title: 'Update balance automatically',
                subtitle: 'High-confidence debits (Dr) and credits (Cr) are saved instantly. '
                    'Duplicates and unclear messages still wait for review.',
                value: a.autoUpdateFromSms,
                onChanged: (on) => _setAuto(ref, a, on),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          KeyValueCard(rows: [
            KeyValueRow('Opening balance', valueWidget: MoneyText(a.openingBalance, style: PaisaText.body.copyWith(fontSize: 14))),
            KeyValueRow('Last reconciled', value: a.lastReconciled == null ? 'Never' : longDate(a.lastReconciled)),
            KeyValueRow('Counts toward', value: countsToward(a.group)),
          ]),
        ]),
      ),
      SectionHeader(
        title: 'Activity',
        trailing: Text('${d.txns.length} transactions', style: PaisaText.sub.copyWith(color: c.ink3)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: d.txns.isEmpty
            ? PaisaCard(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No transactions linked to this account yet.',
                  textAlign: TextAlign.center,
                  style: PaisaText.sub.copyWith(color: c.ink3),
                ),
              )
            : PaisaListCard(children: [
                for (final t in d.txns)
                  TransactionTile(
                    view: describeTxn(t, d.lookup, today: today, money: money),
                    onTap: () => showTxnSheet(context, t),
                  ),
              ]),
      ),
    ]);
  }

  Future<void> _setAuto(WidgetRef ref, Account a, bool on) async {
    await ref.read(accountRepoProvider).setAutoUpdate(a.id, on);
    ref.read(toastProvider.notifier).show(on
        ? 'Confident SMS for ${a.shortName} will update the balance automatically'
        : 'SMS for ${a.shortName} will wait for review');
  }

  Future<void> _archive(BuildContext context, WidgetRef ref, Account a) async {
    final choice = await showConfirmDialog(
      context,
      title: 'Archive ${a.name}?',
      body: 'It will be hidden and excluded from totals. Its transaction history is kept and you can undo this right away.',
      okLabel: 'Archive account',
      okVariant: ButtonVariant.danger,
    );
    if (choice != ConfirmChoice.ok || !context.mounted) return;
    final toast = ref.read(toastProvider.notifier);
    final undo = await ref.read(accountRepoProvider).archive(a.id);
    if (context.mounted) leavePage(context);
    showUndoToast(toast, 'Account archived', undo);
  }
}

/// Outline pill with an icon above its label (mockup `.btn.bo.sm` column).
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              PaisaIcon(icon, size: 19, color: c.ink),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.buttonSmall.copyWith(fontSize: 12.5, color: c.ink)),
            ]),
          ),
        ),
      ),
    );
  }
}
