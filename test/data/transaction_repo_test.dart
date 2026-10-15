import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/repos/transaction_repo.dart';
import 'package:paisa/data/undo.dart';
import 'package:paisa/finance/finance.dart';

import 'data_fixtures.dart';

Txn expense(String id, Paisa amount, {String account = 'nabil', String date = '2026-10-14'}) => Txn(
      id: id, date: date, time: '10:30', title: 'Big Mart', type: TxType.expense,
      accountId: account, categoryId: 'groceries', amount: amount,
    );

void main() {
  late TransactionRepository repo;

  Future<AppDatabase> setUpRepo() async {
    final db = await ledgerDb();
    repo = TransactionRepository(db, testAudit(db), clock: testClock);
    return db;
  }

  test('add applies the engine effect and writes the row and an audit entry', () async {
    final db = await setUpRepo();
    await repo.add(expense('t1', fromRupees(2180)), summary: 'Added expense Big Mart · NPR 2,180');
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 2180));
    final saved = await repo.find('t1');
    expect(saved!.createdAt, '2026-10-14T10:30:00');
    expect(await auditSummaries(db), ['Added expense Big Mart · NPR 2,180']);
  });

  test('a transaction the engine rejects saves nothing at all', () async {
    final db = await setUpRepo();
    const badTransfer = Txn(
      id: 't1', date: '2026-10-14', time: '10:30', title: 'X', type: TxType.transfer,
      direction: Direction.debit, accountId: 'nabil', amount: 100, // no counter account
    );
    await expectLater(repo.add(badTransfer, summary: 'x'), throwsA(isA<LedgerError>()));
    expect(await repo.find('t1'), isNull);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect(await auditSummaries(db), isEmpty);
  });

  test('acceptance 11: delete reverses the exact effect; undo restores it', () async {
    final db = await setUpRepo();
    const transfer = Txn(
      id: 't1', date: '2026-10-13', time: '19:20', title: 'Fonepay transfer', type: TxType.transfer,
      direction: Direction.debit, accountId: 'nabil', counterAccountId: 'nic', amount: 1500000,
    );
    await repo.add(transfer, summary: 'added');
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 15000));
    expect(await balanceOf(db, 'nic'), fromRupees(385000 + 15000));

    final undo = await repo.delete('t1');
    expect(await repo.find('t1'), isNull);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect(await balanceOf(db, 'nic'), fromRupees(385000));

    await undo();
    final back = await repo.find('t1');
    expect(back!.counterAccountId, 'nic');
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 15000));
    expect(await balanceOf(db, 'nic'), fromRupees(385000 + 15000));
    expect(await auditSummaries(db), ['added', 'Deleted Fonepay transfer · NPR 15,000', 'Undid the last change']);
  });

  test('deleting a loan repayment restores the loan outstanding and due date', () async {
    final db = await setUpRepo();
    const repayment = Txn(
      id: 't5b', date: '2026-10-05', time: '06:00', title: 'Personal loan B installment',
      type: TxType.loanRepayment, accountId: 'nabil', loanId: 'L3',
      amount: 516700, principal: 416700, interest: 100000,
    );
    await repo.add(repayment, summary: 'added');
    expect((await loanRow(db, 'L3')).outstanding, 5416300 - 416700);
    expect((await loanRow(db, 'L3')).nextDueDate, '2026-12-05');

    final undo = await repo.delete('t5b');
    expect((await loanRow(db, 'L3')).outstanding, 5416300);
    expect((await loanRow(db, 'L3')).nextDueDate, '2026-11-05');
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));

    await undo();
    expect((await loanRow(db, 'L3')).outstanding, 5416300 - 416700);
  });

  test('undo of add removes the transaction and its effect', () async {
    final db = await setUpRepo();
    final undo = await repo.add(expense('t1', fromRupees(500), account: 'cc'), summary: 'added');
    expect(await balanceOf(db, 'cc'), fromRupees(18640 + 500));
    await undo();
    expect(await repo.find('t1'), isNull);
    expect(await balanceOf(db, 'cc'), fromRupees(18640));
  });

  test('review focus: running the same undo twice reverses the change only once', () async {
    final db = await setUpRepo();
    final undo = await repo.add(expense('t1', fromRupees(1000)), summary: 'added');
    await undo();
    await undo();
    expect(undo.isUsed, isTrue);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect(await auditSummaries(db), ['added', 'Undid the last change']);
  });

  test('UndoAction.combine runs the parts last-first', () async {
    final order = <String>[];
    final combined = UndoAction.combine([
      UndoAction(() async => order.add('first')),
      UndoAction(() async => order.add('second')),
    ]);
    await combined();
    expect(order, ['second', 'first']);
  });

  test('deleting an unknown id throws and changes nothing', () async {
    final db = await setUpRepo();
    await expectLater(repo.delete('nope'), throwsStateError);
    expect(await auditSummaries(db), isEmpty);
  });

  test('watchAll lists newest first; watchForAccount includes the counter side', () async {
    await setUpRepo();
    await repo.add(expense('old', 100, date: '2026-10-01'), summary: 'a');
    await repo.add(expense('new', 100, date: '2026-10-13'), summary: 'b');
    await repo.add(
      const Txn(
        id: 'tr', date: '2026-10-12', time: '09:00', title: 'Load eSewa', type: TxType.transfer,
        direction: Direction.debit, accountId: 'nabil', counterAccountId: 'esewa', amount: 500000,
      ),
      summary: 'c',
    );
    expect((await repo.watchAll().first).map((t) => t.id), ['new', 'tr', 'old']);
    expect((await repo.watchForAccount('esewa').first).map((t) => t.id), ['tr']);
  });
}
