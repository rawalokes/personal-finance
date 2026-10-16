import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14'; // day 14 of 31

Loan emi(String id, {required String due, num installment = 10000}) => Loan(
    id: id, loanTypeId: 'p', name: 'Loan $id', lender: 'B', principal: fromRupees(200000), outstanding: fromRupees(100000),
    ratePct: 12, method: InterestMethod.reducing, installment: fromRupees(installment), frequency: LoanFrequency.monthly, nextDueDate: due);

MonthPlan plan({List<Txn> txs = const [], List<Account>? accounts, List<Loan> loans = const [], List<ExpenseCategory> categories = const [], List<Goal> goals = const []}) =>
    monthPlan(txs: txs, accounts: accounts ?? [acct('bank', AccountGroup.liquid, 100000)], loans: loans, categories: categories, goals: goals, today: today);

void main() {
  test('nothing to go on: no savings target, everything you have is free', () {
    final p = plan();
    expect(p.saveTarget, 0);
    expect(p.youHave, fromRupees(100000));
    expect(p.freeToSpend, fromRupees(100000));
    expect(p.emisDue, 0);
    expect(p.budgetsSet, 0);
  });

  test('savings target is 20% of income; behind when you have kept less than you should by today', () {
    final p = plan(txs: [tx(TxType.income, 'bank', 100000, date: '2026-10-01'), tx(TxType.expense, 'bank', 95000, cat: 'x', date: '2026-10-02')]);
    expect(p.saveTarget, fromRupees(20000));
    expect(p.saved, fromRupees(5000));
    // By day 14 of 31 you should have kept 20,000 × 14/31 ≈ 9,032.
    expect(p.behindBy, closeTo(fromRupees(4032), 100));
    expect(p.freeToSpend, fromRupees(100000 - 15000));
  });

  test('a goal that needs more than 20% sets the target; ahead shows as negative behind', () {
    final goal = Goal(id: 'g', name: 'Bike', kind: 'Major purchase', target: fromRupees(300000), current: 0, targetDate: '2027-03-14');
    final p = plan(txs: [tx(TxType.income, 'bank', 100000, date: '2026-10-01'), tx(TxType.expense, 'bank', 40000, cat: 'x', date: '2026-10-02')], goals: [goal]);
    expect(p.saveTarget, fromRupees(60000), reason: '3,00,000 over 5 months');
    expect(p.saved, fromRupees(60000));
    expect(p.behindBy, lessThan(0));
    expect(p.saveLeft, 0);
  });

  test('EMIs due this month or overdue, minus those paid; free to spend sets them aside', () {
    final p = plan(
      loans: [emi('A', due: '2026-10-28'), emi('B', due: '2026-11-05'), emi('C', due: '2026-10-02', installment: 5000), emi('D', due: '2026-11-13')],
      txs: [tx(TxType.loanRepayment, 'bank', 7000, loanId: 'D', principal: 6000, interest: 1000, date: '2026-10-13')],
    );
    // A due later this month, C overdue → 15,000 left; D paid this month (its next date moved on).
    expect(p.emiLeft, fromRupees(15000));
    expect((p.emisPaid, p.emisDue), (1, 3));
    expect(p.nextDue, '2026-10-02', reason: 'the overdue EMI is the most urgent');
    expect(p.freeToSpend, fromRupees(100000 - 15000));
  });

  test('budgets: count over and the one closest to its limit', () {
    final p = plan(
      categories: [
        ExpenseCategory(id: 'food', name: 'Food', icon: 't', monthlyBudget: fromRupees(10000)),
        ExpenseCategory(id: 'fun', name: 'Fun', icon: 't', monthlyBudget: fromRupees(1000)),
      ],
      txs: [tx(TxType.expense, 'bank', 9200, cat: 'food', date: '2026-10-05'), tx(TxType.expense, 'bank', 1500, cat: 'fun', date: '2026-10-05')],
    );
    expect((p.budgetsSet, p.budgetsOver), (2, 1));
    expect(p.closestBudget!.$1, 'food');
    expect(p.closestBudget!.$2, closeTo(0.92, 1e-9));
  });

  test('free to spend goes negative when commitments exceed what you have', () {
    final p = plan(accounts: [acct('bank', AccountGroup.liquid, 5000)], loans: [emi('A', due: '2026-10-20')]);
    expect(p.freeToSpend, fromRupees(-5000));
  });

  test('BS: the month is Asoj and days left count to its end', () {
    final p = monthPlan(txs: const [], accounts: const [], loans: const [], categories: const [], goals: const [], today: today, cal: const BsCalendar());
    expect(p.month, 'B2083-06');
    expect(p.daysLeft, const BsCalendar().daysIn('B2083-06') - 28);
  });
}
