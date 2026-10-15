import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/ledger.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';
import 'package:paisa/finance/networth.dart';
import 'package:paisa/finance/totals.dart';

import 'fixtures.dart';

void main() {
  const oct = '2026-10';
  final history = [
    tx(TxType.expense, 'nabil', 4380, cat: 'groceries', date: '2026-10-02'),
    tx(TxType.income, 'nabil', 25000, incomeType: 'freelance', date: '2026-10-06'),
    tx(TxType.income, 'nabil', 92789, incomeType: 'salary', date: '2026-09-16'),
  ];

  test('confirming the salary credit raises October income and Nabil by 92,789 (acceptance 1)', () {
    final salary = tx(TxType.income, 'nabil', 92789, incomeType: 'salary');
    final before = monthlyTotals(history, oct);
    final after = monthlyTotals([...history, salary], oct);
    expect(after.income - before.income, fromRupees(92789));
    expect(after.byIncomeType['salary'], fromRupees(92789));
    expect(applyTransaction(seedLedger(), salary).balanceOf('nabil') - fromRupees(142350), fromRupees(92789));
  });

  test('refund lowers its category spending and is not income (acceptance 5)', () {
    final t = monthlyTotals([
      tx(TxType.expense, 'esewa', 4500, cat: 'fun'),
      tx(TxType.refund, 'esewa', 1500, cat: 'fun'),
    ], oct);
    expect(t.byCategory['fun'], fromRupees(3000));
    expect(t.expenses, fromRupees(3000));
    expect(t.income, 0);
  });

  test('transfer, reversal and card payment are neither income nor expense (acceptance 3, 6, 7)', () {
    final t = monthlyTotals([
      tx(TxType.transfer, 'nabil', 15000, to: 'nic', dir: Direction.debit),
      tx(TxType.reversal, 'khalti', 640, dir: Direction.credit),
      tx(TxType.ccPayment, 'nabil', 18640, to: 'cc'),
      tx(TxType.cashWithdrawal, 'nabil', 10000, to: 'cash', dir: Direction.debit),
      tx(TxType.loanDisbursement, 'nic', 50000, loanId: 'L2'),
    ], oct);
    expect(t.income, 0);
    expect(t.expenses, 0);
  });

  test('loan repayment counts only its interest, as Loan Interest (acceptance 4)', () {
    final t = monthlyTotals(
        [tx(TxType.loanRepayment, 'gibl', 11501, loanId: 'L1', principal: 9357, interest: 2144)], oct);
    expect(t.expenses, fromRupees(2144));
    expect(t.byCategory[kLoanInterestCategoryId], fromRupees(2144));
  });

  test('pending and other-month transactions are ignored', () {
    final t = monthlyTotals([
      tx(TxType.income, 'nabil', 5000, status: TxStatus.pending),
      tx(TxType.expense, 'nabil', 700, date: '2026-09-30'),
      tx(TxType.expense, 'nabil', 300, date: '2026-10-31'),
    ], oct);
    expect(t.income, 0);
    expect(t.expenses, fromRupees(300));
  });

  test('surplus and savings rate', () {
    final t = monthlyTotals([
      tx(TxType.income, 'nabil', 100000, incomeType: 'salary'),
      tx(TxType.expense, 'nabil', 45000, cat: 'housing'),
    ], oct);
    expect(t.surplus, fromRupees(55000));
    expect(t.savingsRate, closeTo(0.55, 1e-9));
    expect(monthlyTotals(const [], oct).savingsRate, 0);
  });

  test('balance summary from the seed (spec §12, §9.4 payload)', () {
    final b = summarizeBalances(seedAccounts(), seedLoans());
    expect(b.availableToSpend, fromRupees(184020));
    expect(b.reserved, fromRupees(385000));
    expect(b.locked, fromRupees(981200));
    expect(b.creditCards, fromRupees(18640));
    expect(b.loans, fromRupees(444253));
    expect(b.liabilities, fromRupees(462893));
    expect(b.netWorth, fromRupees(1087327));
  });

  test('archived accounts and closed loans are left out', () {
    final accounts = [...seedAccounts().map((a) => a.id == 'cash' ? a.copyWith(archived: true) : a)];
    final loans = [...seedLoans().map((l) => l.id == 'L4' ? l.copyWith(closed: true) : l)];
    final b = summarizeBalances(accounts, loans);
    expect(b.liquid, fromRupees(184020 - 6500));
    expect(b.loans, fromRupees(444253 - 30000));
  });
}
