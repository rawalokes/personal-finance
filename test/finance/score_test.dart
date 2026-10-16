import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

ExpenseCategory food({num budget = 10000}) =>
    ExpenseCategory(id: 'food', name: 'Food', icon: 'tag', monthlyBudget: fromRupees(budget));

void main() {
  const today = '2026-10-14';

  test('no data at all: score 0, only the savings part, no tip, no crash', () {
    final s = scoreForMonth('2026-10', txs: const [], categories: const [], loans: const [], today: today);
    expect(s.total, 0);
    expect(s.parts.keys, [ScorePartKind.savingsRate]);
    expect(s.tip, isNull);
    expect(s.isFinal, isFalse);
  });

  test('saving 20% with nothing else to judge is a full 100', () {
    final s = scoreForMonth('2026-09',
        txs: [tx(TxType.income, 'a', 100000, date: '2026-09-01'), tx(TxType.expense, 'a', 80000, cat: 'x', date: '2026-09-02')],
        categories: const [], loans: const [], today: today);
    expect(s.total, 100);
    expect(s.isFinal, isTrue);
  });

  test('an over-budget month and a 10% savings rate', () {
    final s = scoreForMonth('2026-09',
        txs: [tx(TxType.income, 'a', 100000, date: '2026-09-01'), tx(TxType.expense, 'a', 90000, cat: 'food', date: '2026-09-02')],
        categories: [food()], loans: const [], today: today);
    // savings 20/40, budgets 0/25 → 20 of 65 → 31 of 100
    expect(s.total, 31);
    expect(s.parts[ScorePartKind.budgets], 0);
  });

  test('spending 25% above the 3-month average earns half the spending points', () {
    final txs = [
      for (final m in ['06', '07', '08']) tx(TxType.expense, 'a', 10000, cat: 'x', date: '2026-$m-10'),
      tx(TxType.expense, 'a', 12500, cat: 'x', date: '2026-09-10'),
    ];
    final s = scoreForMonth('2026-09', txs: txs, categories: const [], loans: const [], today: today);
    // savings 0/40 (no income), spending 7.5/15 → 7.5 of 55 → 14
    expect(s.total, 14);
  });

  test('a recorded installment that lowers the balance earns full loan points', () {
    final loan = Loan(id: 'L1', loanTypeId: 'p', name: 'Scooter', lender: 'Bank', principal: fromRupees(100000),
        outstanding: fromRupees(50000), ratePct: 12, method: InterestMethod.reducing, installment: fromRupees(5000),
        frequency: LoanFrequency.monthly);
    final s = scoreForMonth('2026-09',
        txs: [tx(TxType.loanRepayment, 'a', 5000, loanId: 'L1', principal: 4000, interest: 1000, date: '2026-09-13')],
        categories: const [], loans: [loan], today: today);
    expect(s.parts[ScorePartKind.loans]! / s.maxima[ScorePartKind.loans]!, closeTo(1, 1e-9));
  });

  test('the current month gets the tip that adds the most points', () {
    final s = scoreForMonth('2026-10',
        txs: [tx(TxType.income, 'a', 100000, date: '2026-10-01'), tx(TxType.expense, 'a', 90000, cat: 'x', date: '2026-10-02')],
        categories: const [], loans: const [], today: today);
    expect(s.tip!.text, 'Save NPR 10,000 more this month');
    expect(s.tip!.gain, 50);
  });

  test('trend is six months, oldest first, ending this month', () {
    final t = scoreTrend(txs: const [], categories: const [], loans: const [], today: today);
    expect(t.map((s) => s.month), ['2026-05', '2026-06', '2026-07', '2026-08', '2026-09', '2026-10']);
  });

  test('review fix: an EMI due later this month is not counted as missed', () {
    final loan = Loan(id: 'L1', loanTypeId: 'p', name: 'Scooter', lender: 'Bank', principal: fromRupees(100000),
        outstanding: fromRupees(50000), ratePct: 12, method: InterestMethod.reducing, installment: fromRupees(5000),
        frequency: LoanFrequency.monthly, nextDueDate: '2026-10-28');
    final s = scoreForMonth('2026-10', txs: const [], categories: const [], loans: [loan], today: today);
    expect(s.parts[ScorePartKind.loans]! / s.maxima[ScorePartKind.loans]!, closeTo(0.5, 1e-9), reason: 'nothing due yet: installment half full, balance half empty');
    expect(s.tip?.text ?? '', isNot(contains('Record the')));
    final overdue = scoreForMonth('2026-10', txs: const [], categories: const [], loans: [Loan(id: 'L1', loanTypeId: 'p', name: 'Scooter', lender: 'Bank', principal: fromRupees(100000),
        outstanding: fromRupees(50000), ratePct: 12, method: InterestMethod.reducing, installment: fromRupees(5000),
        frequency: LoanFrequency.monthly, nextDueDate: '2026-10-10')], today: today);
    expect(overdue.parts[ScorePartKind.loans], 0);
  });
}
