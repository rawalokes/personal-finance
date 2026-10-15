import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/ledger.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';

import 'fixtures.dart';

void main() {
  late LedgerState seed;
  setUp(() => seed = seedLedger());

  test('transfer Nabil → NIC moves 15,000 between own accounts (acceptance 3)', () {
    final s = applyTransaction(seed, tx(TxType.transfer, 'nabil', 15000, to: 'nic', dir: Direction.debit));
    expect(s.balanceOf('nabil'), fromRupees(127350));
    expect(s.balanceOf('nic'), fromRupees(400000));
  });

  test('credit-direction transfer moves money into the SMS account', () {
    final s = applyTransaction(seed, tx(TxType.transfer, 'esewa', 5000, to: 'nabil', dir: Direction.credit));
    expect(s.balanceOf('esewa'), fromRupees(13420));
    expect(s.balanceOf('nabil'), fromRupees(137350));
  });

  test('expense lowers an asset and raises card debt', () {
    var s = applyTransaction(seed, tx(TxType.expense, 'nabil', 2450, cat: 'groceries'));
    expect(s.balanceOf('nabil'), fromRupees(139900));
    s = applyTransaction(s, tx(TxType.expense, 'cc', 1850, cat: 'other'));
    expect(s.balanceOf('cc'), fromRupees(20490));
  });

  test('income and refund add to the account', () {
    var s = applyTransaction(seed, tx(TxType.income, 'nabil', 92789, incomeType: 'salary'));
    expect(s.balanceOf('nabil'), fromRupees(235139));
    s = applyTransaction(s, tx(TxType.refund, 'esewa', 1500, cat: 'fun'));
    expect(s.balanceOf('esewa'), fromRupees(9920));
  });

  test('reversal restores the account in the reported direction', () {
    expect(applyTransaction(seed, tx(TxType.reversal, 'khalti', 640, dir: Direction.credit)).balanceOf('khalti'),
        fromRupees(2790));
    expect(applyTransaction(seed, tx(TxType.reversal, 'khalti', 640, dir: Direction.debit)).balanceOf('khalti'),
        fromRupees(1510));
  });

  test('cash withdrawal moves bank money into cash', () {
    final s = applyTransaction(seed, tx(TxType.cashWithdrawal, 'nabil', 10000, to: 'cash', dir: Direction.debit));
    expect(s.balanceOf('nabil'), fromRupees(132350));
    expect(s.balanceOf('cash'), fromRupees(16500));
  });

  test('card bill payment reduces bank balance and card debt (acceptance 7)', () {
    final s = applyTransaction(seed, tx(TxType.ccPayment, 'nabil', 18640, to: 'cc'));
    expect(s.balanceOf('nabil'), fromRupees(123710));
    expect(s.balanceOf('cc'), 0);
  });

  test('loan repayment takes principal off the loan and moves next due (acceptance 4)', () {
    final s = applyTransaction(
        seed, tx(TxType.loanRepayment, 'gibl', 11501, loanId: 'L1', principal: 9357, interest: 2144));
    expect(s.balanceOf('gibl'), fromRupees(13099));
    expect(s.outstandingOf('L1'), fromRupees(219283));
    expect(s.loans['L1']!.nextDueDate, '2026-11-13');
  });

  test('loan disbursement adds cash and debt, not income', () {
    final s = applyTransaction(seed, tx(TxType.loanDisbursement, 'nic', 50000, loanId: 'L2'));
    expect(s.balanceOf('nic'), fromRupees(435000));
    expect(s.outstandingOf('L2'), fromRupees(181450));
  });

  test('adjustment applies a signed difference', () {
    final s = applyTransaction(seed, tx(TxType.adjustment, 'cash', -500));
    expect(s.balanceOf('cash'), fromRupees(6000));
  });

  test('pending transactions change nothing', () {
    final s = applyTransaction(seed, tx(TxType.income, 'nabil', 5000, status: TxStatus.pending));
    expect(snapshot(s), snapshot(seed));
  });

  test('deleting reverses the exact effect and undo re-applies it (acceptance 11)', () {
    final txs = [
      tx(TxType.expense, 'nabil', 2450, cat: 'groceries'),
      tx(TxType.transfer, 'nabil', 15000, to: 'nic', dir: Direction.debit),
      tx(TxType.loanRepayment, 'gibl', 11501, loanId: 'L1', principal: 9357, interest: 2144),
      tx(TxType.ccPayment, 'nabil', 18640, to: 'cc'),
      tx(TxType.loanDisbursement, 'nic', 50000, loanId: 'L2'),
      tx(TxType.reversal, 'khalti', 640, dir: Direction.debit),
    ];
    final after = applyAll(seed, txs);
    var undone = after;
    for (final t in txs.reversed) {
      undone = revertTransaction(undone, t);
    }
    expect(snapshot(undone), snapshot(seed));
    expect(snapshot(applyAll(undone, txs)), snapshot(after));
  });

  test('reverting changes that hit zero or below restores them exactly (Review Focus 2)', () {
    final clear = tx(TxType.loanRepayment, 'esewa', 30000, loanId: 'L4', principal: 30000, interest: 0);
    final overdraw = tx(TxType.expense, 'khalti', 5000, cat: 'other');
    final s = applyAll(seed, [clear, overdraw]);
    expect(s.outstandingOf('L4'), 0);
    expect(s.balanceOf('khalti'), fromRupees(-2850));
    final back = revertTransaction(revertTransaction(s, overdraw), clear);
    expect(snapshot(back), snapshot(seed));
    expect(back.loans['L4']!.nextDueDate, '2026-10-01');
  });

  test('rejects broken transactions with LedgerError', () {
    expect(() => applyTransaction(seed, tx(TxType.expense, 'nope', 10)), throwsA(isA<LedgerError>()));
    expect(() => applyTransaction(seed, tx(TxType.expense, 'nabil', 0)), throwsA(isA<LedgerError>()));
    expect(() => applyTransaction(seed, tx(TxType.transfer, 'nabil', 10, dir: Direction.debit)),
        throwsA(isA<LedgerError>()));
    expect(() => applyTransaction(seed, tx(TxType.transfer, 'nabil', 10, to: 'nabil', dir: Direction.debit)),
        throwsA(isA<LedgerError>()));
    expect(() => applyTransaction(seed, tx(TxType.loanRepayment, 'nabil', 10)), throwsA(isA<LedgerError>()));
  });
}
