import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/records.dart';
import 'package:paisa/data/repos/account_repo.dart';
import 'package:paisa/data/repos/catalog_repo.dart';
import 'package:paisa/data/repos/transaction_repo.dart';
import 'package:paisa/finance/finance.dart';

import 'data_fixtures.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository txns;
  late AccountRepository accounts;

  setUp(() async {
    db = await ledgerDb();
    final audit = testAudit(db);
    txns = TransactionRepository(db, audit, clock: testClock);
    accounts = AccountRepository(db, audit, txns, clock: testClock, newId: counterIds('new'));
  });

  group('naming helpers', () {
    test('maskDigits keeps only the last four digits', () {
      expect(maskDigits('12 3456-7890'), '7890');
      expect(maskDigits('482'), '482');
      expect(maskDigits('abc'), isNull);
      expect(maskDigits(''), isNull);
    });

    test('deriveShortName uses the first two words before the dash, plus the mask', () {
      expect(deriveShortName('Khalti — personal', null, []), 'Khalti');
      expect(deriveShortName('Nabil Bank — savings', '4821', []), 'Nabil Bank ••4821');
      expect(deriveShortName('Cash in hand', null, []), 'Cash in');
      expect(deriveShortName('Khalti — work', null, ['Khalti']), 'Khalti — work');
    });
  });

  test('acceptance 12 setup: add a Khalti wallet, 3,500, sender Khalti, auto-update on', () async {
    final (account, _) = await accounts.add(NewAccountInput(
      name: 'Khalti — personal',
      type: AccountTypeChoice.wallet,
      balance: fromRupees(3500),
      smsSender: 'Khalti',
      autoUpdateFromSms: true,
    ));
    final saved = await accounts.get(account.id);
    expect(saved.shortName, 'Khalti');
    expect(saved.kind, AccountKind.wallet);
    expect(saved.group, AccountGroup.liquid);
    expect(saved.accountTypeId, 'a4');
    expect(saved.balance, fromRupees(3500));
    expect(saved.openingBalance, fromRupees(3500));
    expect(saved.smsSender, 'Khalti');
    expect(saved.autoUpdateFromSms, isTrue);
    expect(saved.lastReconciled, '2026-10-14');
    final all = await accounts.watchAll().first;
    expect(all.last.id, account.id, reason: 'new accounts are listed last');
    final banks = await CatalogRepository(db, testAudit(db)).watchConfig(ConfigList.banks).first;
    expect(banks.single.description, 'Sender Khalti');
    expect(await auditSummaries(db), ['Added account Khalti — personal (SMS sender Khalti)']);
  });

  test('auto-update is dropped when no SMS sender is given', () async {
    final (account, _) = await accounts.add(NewAccountInput(
      name: 'Cash in hand', type: AccountTypeChoice.cash, balance: 0, autoUpdateFromSms: true,
    ));
    expect((await accounts.get(account.id)).autoUpdateFromSms, isFalse);
  });

  test('undo of add deletes an unused account and the bank entry it created', () async {
    final (account, undo) = await accounts.add(NewAccountInput(
      name: 'IME Pay', type: AccountTypeChoice.wallet, balance: 100, smsSender: 'IMEPay',
    ));
    await undo();
    expect((await accounts.watchAll().first).map((a) => a.id), isNot(contains(account.id)));
    expect(await CatalogRepository(db, testAudit(db)).watchConfig(ConfigList.banks).first, isEmpty);
  });

  test('undo of add archives instead when the account already has activity', () async {
    final (account, undo) = await accounts.add(NewAccountInput(
      name: 'IME Pay', type: AccountTypeChoice.wallet, balance: fromRupees(1000),
    ));
    await txns.add(
      Txn(id: 't1', date: '2026-10-14', time: '10:30', title: 'Tea', type: TxType.expense, accountId: account.id, amount: 5000),
      summary: 'x',
    );
    await undo();
    expect((await accounts.get(account.id)).archived, isTrue);
    expect(await txns.find('t1'), isNotNull);
  });

  test('archive hides the account; undo brings it back; history is kept', () async {
    await txns.add(
      const Txn(id: 't1', date: '2026-10-14', time: '10:30', title: 'Tea', type: TxType.expense, accountId: 'esewa', amount: 5000),
      summary: 'x',
    );
    final undo = await accounts.archive('esewa');
    expect((await accounts.get('esewa')).archived, isTrue);
    expect(await txns.find('t1'), isNotNull);
    await undo();
    expect((await accounts.get('esewa')).archived, isFalse);
  });

  test('setAutoUpdate flips the flag and is audited', () async {
    await accounts.setAutoUpdate('esewa', true);
    expect((await accounts.get('esewa')).autoUpdateFromSms, isTrue);
    expect((await auditSummaries(db)).last, 'Turned on automatic SMS updates for esewa');
  });

  group('reconcile', () {
    test('matching balance only stamps the date', () async {
      final result = await accounts.reconcile('nabil', fromRupees(142350));
      expect(result.difference, 0);
      expect(result.undo, isNull);
      expect((await accounts.get('nabil')).lastReconciled, '2026-10-14');
      expect(await txns.watchAll().first, isEmpty);
    });

    test('a difference books an adjustment that is neither income nor expense', () async {
      final result = await accounts.reconcile('esewa', fromRupees(8000));
      expect(result.difference, fromRupees(-420));
      expect(await balanceOf(db, 'esewa'), fromRupees(8000));
      final adj = (await txns.watchAll().first).single;
      expect(adj.type, TxType.adjustment);
      expect(adj.amount, fromRupees(-420));
      final totals = monthlyTotals([adj], '2026-10');
      expect(totals.income, 0);
      expect(totals.expenses, 0);
      expect((await auditSummaries(db)).last, 'Reconciled esewa · adjustment −NPR 420');
    });

    test('a credit card that owes more than Paisa shows ends up owing exactly that', () async {
      await accounts.reconcile('cc', fromRupees(19000));
      expect(await balanceOf(db, 'cc'), fromRupees(19000));
    });

    test('undo removes the adjustment and restores the previous reconcile date', () async {
      final result = await accounts.reconcile('esewa', fromRupees(9000));
      await result.undo!();
      expect(await balanceOf(db, 'esewa'), fromRupees(8420));
      expect(await txns.watchAll().first, isEmpty);
      expect((await accounts.get('esewa')).lastReconciled, isNull);
    });
  });
}
