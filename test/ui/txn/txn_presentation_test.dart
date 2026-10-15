import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/accounts/account_presentation.dart';
import 'package:paisa/ui/components/tone.dart';
import 'package:paisa/ui/icons/paisa_icons.dart';
import 'package:paisa/ui/txn/txn_presentation.dart';

final lookup = TxnLookup(accounts: seedAccounts, categories: seedCategories, incomeTypes: seedIncomeTypes);
Txn seeded(String id) => seedTransactions.firstWhere((t) => t.id == id);
TxnView view(Txn t, {MoneyFormat money = const MoneyFormat()}) =>
    describeTxn(t, lookup, today: '2026-10-14', money: money);

void main() {
  test('every transaction type has a name, icon, description and sheet note', () {
    for (final t in TxType.values) {
      expect(kTxTypeInfo[t], isNotNull, reason: '$t');
      expect(kTxTypeNote[t], isNotNull, reason: '$t');
    }
    for (final s in TxSource.values) {
      expect(kTxSourceLabel[s], isNotNull);
    }
  });

  test('PaisaIcons.byName covers every icon; unknown names fall back to tag', () {
    expect(PaisaIcons.byName.values.toSet(), PaisaIcons.all.toSet());
    expect(PaisaIcons.named('brief'), PaisaIcons.brief);
    expect(PaisaIcons.named('nope'), PaisaIcons.tag);
  });

  test('expense row: category · account, minus sign, category icon', () {
    final v = view(seeded('t15'));
    expect(v.title, 'WorldLink internet');
    expect(v.subtitle, 'Utilities · eSewa');
    expect(v.sign, kMinus);
    expect(v.amount, fromRupees(1695));
    expect(v.tone, AmountTone.ink);
    expect(v.icon, PaisaIcons.bolt);
    expect(v.meta, '18:20');
    expect(v.dateText, 'Yesterday');
  });

  test('income row is positive with the income type icon and SMS meta', () {
    final v = view(seeded('t14'));
    expect(v.subtitle, 'Interest Income · NIC Asia ••2290');
    expect(v.sign, '+');
    expect(v.tone, AmountTone.positive);
    expect(v.iconTone, Tone.positive);
    expect(v.icon, PaisaIcons.trend);
    expect(v.meta, 'SMS · 16:05');
    expect(v.dateText, '12 Oct');
  });

  test('transfer shows the direction between own accounts and no sign', () {
    final v = view(seeded('t12'));
    expect(v.subtitle, 'Transfer · Nabil ••4821 → eSewa');
    expect(v.sign, '');
    expect(v.tone, AmountTone.muted);
    expect(v.iconTone, Tone.blue);
  });

  test('loan repayment subtitle shows the split, and masks it with hide balances', () {
    expect(view(seeded('t5b')).subtitle, 'Principal 4,167 · Interest 1,000');
    expect(view(seeded('t5b'), money: const MoneyFormat(masked: true)).subtitle, 'Principal •••••• · Interest ••••••');
  });

  test('negative adjustment carries a minus sign and a positive amount', () {
    const adj = Txn(
      id: 'a', date: '2026-10-14', time: '10:30', title: 'Reconciliation adjustment', type: TxType.adjustment,
      accountId: 'esewa', amount: -42000,
    );
    final v = view(adj);
    expect(v.sign, kMinus);
    expect(v.amount, 42000);
    expect(v.subtitle, 'Balance adjustment · eSewa');
  });

  test('pending transactions say Pending instead of a time', () {
    const t = Txn(
      id: 'p', date: '2026-10-14', time: '09:00', title: 'Bonus', type: TxType.income, accountId: 'nabil',
      incomeTypeId: 'bonus', amount: 100, status: TxStatus.pending,
    );
    expect(view(t).meta, 'Pending');
  });

  test('detail rows for a loan repayment include the split and the source', () {
    final rows = txnDetailRows(seeded('t5b'), lookup, const MoneyFormat());
    expect(rows, containsAll([
      ('Type', 'Loan repayment'),
      ('Date', '5 Oct 2026, 06:00'),
      ('Account', 'Nabil ••4821'),
      ('Principal', 'NPR 4,167'),
      ('Interest', 'NPR 1,000'),
      ('Source', 'Approved from SMS'),
    ]));
  });

  test('detail rows for a transfer name the other account', () {
    expect(txnDetailRows(seeded('t12'), lookup, const MoneyFormat()), contains(('To', 'eSewa')));
  });

  group('account presentation', () {
    final nabil = seedAccounts.first;
    final cc = seedAccounts.last;
    test('icon, tone and type label', () {
      expect(accountIcon(nabil), PaisaIcons.bank);
      expect(accountIcon(cc), PaisaIcons.card);
      expect(accountTone(cc), Tone.red);
      expect(accountTypeLabel(nabil, seedConfig['account_types']!), 'Bank account');
      expect(accountTypeLabel(cc, const []), 'Credit card');
    });
    test('group tags and counts-toward text', () {
      expect(groupTag(AccountGroup.reserved), ('Reserved savings', Tone.blue));
      expect(countsToward(AccountGroup.locked), 'Net worth only');
    });
  });
}
