import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../components/tone.dart';
import '../icons/paisa_icons.dart';

/// Name, icon and one-line meaning of each transaction type (mockup `TYPES`).
class TxTypeInfo {
  const TxTypeInfo(this.name, this.icon, this.description);
  final String name;
  final String icon;
  final String description;
}

const Map<TxType, TxTypeInfo> kTxTypeInfo = {
  TxType.expense: TxTypeInfo('Expense', PaisaIcons.moneyOut, 'Spending that counts toward budgets'),
  TxType.income: TxTypeInfo('Income', PaisaIcons.moneyIn, 'Earnings such as salary or freelance'),
  TxType.transfer: TxTypeInfo('Transfer', PaisaIcons.transfer, 'Between your own accounts — not income or expense'),
  TxType.loanRepayment: TxTypeInfo('Loan repayment', PaisaIcons.rupee, 'Splits into principal and interest'),
  TxType.ccPayment: TxTypeInfo('Credit card payment', PaisaIcons.card, 'Settles card balance — purchases not double counted'),
  TxType.cashWithdrawal: TxTypeInfo('Cash withdrawal', PaisaIcons.cash, 'Moves money into Cash in hand'),
  TxType.refund: TxTypeInfo('Refund', PaisaIcons.undo, 'Reduces spending in a category, not income'),
  TxType.reversal: TxTypeInfo('Reversal / failed', PaisaIcons.refresh, 'Failed or reversed — never counted as spending'),
  TxType.loanDisbursement: TxTypeInfo('Loan disbursement', PaisaIcons.bank, 'Increases liabilities — not income'),
  TxType.adjustment: TxTypeInfo('Balance adjustment', PaisaIcons.scale, 'Reconciliation difference — not income or expense'),
};

/// The note at the bottom of the transaction sheet.
const Map<TxType, String> kTxTypeNote = {
  TxType.expense: 'Counts as spending and toward its category budget.',
  TxType.income: 'Counts as income for the month.',
  TxType.refund: 'Reduces spending in its category — not income.',
  TxType.transfer: 'Moved between your accounts — not income or expense.',
  TxType.cashWithdrawal: 'Moved into Cash in hand — not an expense.',
  TxType.loanRepayment: 'Principal reduced the loan; only interest is an expense.',
  TxType.ccPayment: 'Settled the card; purchases were already counted.',
  TxType.reversal: 'Failed or reversed — not counted.',
  TxType.loanDisbursement: 'Increased liabilities — not income.',
  TxType.adjustment: 'Reconciliation adjustment — not income or expense.',
};

const Map<TxSource, String> kTxSourceLabel = {
  TxSource.manual: 'Entered manually',
  TxSource.sms: 'Approved from SMS',
  TxSource.import: 'Imported from a file',
  TxSource.api: 'Added by an integration',
};

/// Names for the ids a transaction refers to.
class TxnLookup {
  TxnLookup({
    required Iterable<Account> accounts,
    required Iterable<ExpenseCategory> categories,
    required Iterable<IncomeType> incomeTypes,
  })  : accounts = {for (final a in accounts) a.id: a},
        categories = {for (final c in categories) c.id: c},
        incomeTypes = {for (final t in incomeTypes) t.id: t};

  final Map<String, Account> accounts;
  final Map<String, ExpenseCategory> categories;
  final Map<String, IncomeType> incomeTypes;

  String accountShort(String? id) => accounts[id]?.shortName ?? '—';
  String categoryName(String? id) => categories[id]?.name ?? 'Uncategorised';
  String incomeTypeName(String? id) => incomeTypes[id]?.name ?? 'Income';
}

final txnLookupProvider = FutureProvider<TxnLookup>((ref) async => TxnLookup(
      accounts: await ref.watch(accountsProvider.future),
      categories: await ref.watch(categoriesProvider.future),
      incomeTypes: await ref.watch(incomeTypesProvider.future),
    ));

enum AmountTone { positive, ink, muted }

/// Everything a transaction row shows (mockup `tvm`).
class TxnView {
  const TxnView({
    required this.title,
    required this.subtitle,
    required this.sign,
    required this.amount,
    required this.tone,
    required this.icon,
    required this.iconTone,
    required this.meta,
    required this.dateText,
  });

  final String title;
  final String subtitle;

  /// '+', [kMinus] or ''.
  final String sign;

  /// Always ≥ 0; the sign carries direction.
  final Paisa amount;
  final AmountTone tone;
  final String icon;
  final Tone iconTone;

  /// 'Pending', 'SMS · 18:02' or '18:02'.
  final String meta;

  /// 'Today', 'Yesterday' or '12 Oct'.
  final String dateText;
}

/// [money] formats amounts inside the subtitle (loan splits), so they mask
/// with "hide balances" like every other amount.
TxnView describeTxn(Txn t, TxnLookup lookup, {required IsoDate today, required MoneyFormat money}) {
  final a = lookup.accountShort(t.accountId);
  final b = lookup.accountShort(t.counterAccountId);
  final info = kTxTypeInfo[t.type]!;
  var icon = info.icon;
  final (String subtitle, String sign, AmountTone tone, Tone iconTone) = switch (t.type) {
    TxType.income => ('${lookup.incomeTypeName(t.incomeTypeId)} · $a', '+', AmountTone.positive, Tone.positive),
    TxType.expense => ('${lookup.categoryName(t.categoryId)} · $a', kMinus, AmountTone.ink, Tone.neutral),
    TxType.refund => ('Refund · ${lookup.categoryName(t.categoryId)}', '+', AmountTone.positive, Tone.positive),
    TxType.transfer => (
        t.direction == Direction.credit ? 'Transfer · $b → $a' : 'Transfer · $a → $b',
        '',
        AmountTone.muted,
        Tone.blue,
      ),
    TxType.cashWithdrawal => ('Cash withdrawal · $a → Cash', '', AmountTone.muted, Tone.blue),
    TxType.loanRepayment => (
        'Principal ${money.plain(t.principal ?? 0)} · Interest ${money.plain(t.interest ?? 0)}',
        kMinus,
        AmountTone.ink,
        Tone.amber,
      ),
    TxType.ccPayment => ('Card bill · not counted as spending', '', AmountTone.muted, Tone.blue),
    TxType.reversal => ('Reversal · $a · not counted', '', AmountTone.muted, Tone.neutral),
    TxType.loanDisbursement => ('Loan received · adds liability', '+', AmountTone.muted, Tone.amber),
    TxType.adjustment => ('Balance adjustment · $a', t.amount >= 0 ? '+' : kMinus, AmountTone.muted, Tone.neutral),
  };
  if (t.type == TxType.income) {
    final it = lookup.incomeTypes[t.incomeTypeId];
    if (it != null) icon = PaisaIcons.named(it.icon);
  } else if (t.type == TxType.expense) {
    final c = lookup.categories[t.categoryId];
    if (c != null) icon = PaisaIcons.named(c.icon);
  }
  return TxnView(
    title: t.title,
    subtitle: subtitle,
    sign: sign,
    amount: t.amount.abs(),
    tone: tone,
    icon: icon,
    iconTone: iconTone,
    meta: t.isPosted ? '${t.source == TxSource.sms ? 'SMS · ' : ''}${t.time}' : 'Pending',
    dateText: relativeDay(t.date, today),
  );
}

/// Label/value rows for the transaction detail sheet.
List<(String, String)> txnDetailRows(Txn t, TxnLookup lookup, MoneyFormat money) => [
      ('Type', kTxTypeInfo[t.type]!.name),
      ('Date', '${longDate(t.date)}, ${t.time}'),
      ('Account', lookup.accountShort(t.accountId)),
      if (t.counterAccountId != null)
        (t.direction == Direction.credit ? 'From' : 'To', lookup.accountShort(t.counterAccountId)),
      if (t.type == TxType.expense || t.type == TxType.refund) ('Category', lookup.categoryName(t.categoryId)),
      if (t.type == TxType.income) ('Income type', lookup.incomeTypeName(t.incomeTypeId)),
      if (t.type == TxType.loanRepayment) ...[
        ('Principal', money.npr(t.principal ?? 0)),
        ('Interest', money.npr(t.interest ?? 0)),
      ],
      ('Source', kTxSourceLabel[t.source]!),
      if (!t.isPosted) ('Status', 'Pending — not in totals'),
      if (t.note != null && t.note!.isNotEmpty) ('Note', t.note!),
    ];
