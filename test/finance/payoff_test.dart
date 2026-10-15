import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';
import 'package:paisa/finance/payoff.dart';

import 'fixtures.dart';

void main() {
  test('+5,000/month avalanche finishes earlier and saves interest (acceptance 10)', () {
    final c = comparePayoff(seedLoans(), extraMonthly: fromRupees(5000));
    expect(c.plan.hitLimit, isFalse);
    expect(c.baseline.hitLimit, isFalse);
    expect(c.plan.months, lessThan(c.baseline.months));
    expect(c.monthsSaved, greaterThan(0));
    expect(c.interestSaved, greaterThan(0));
  });

  test('avalanche ranks flat loans by principal × rate ÷ outstanding', () {
    final r = simulatePayoff(seedLoans(), extraMonthly: fromRupees(5000));
    expect(r.loans.map((l) => l.loanId), ['L3', 'L2', 'L1', 'L4']);
    final first = r.loans.first;
    expect(first.nextMonthExtra, fromRupees(5000));
    expect(first.nextMonthPayment, fromRupees(5167 + 5000));
    expect(r.nextMonthTotal, fromRupees(11501 + 6790 + 5167 + 5000 + 5000));
  });

  test('snowball pays the smallest balance first', () {
    final r = simulatePayoff(seedLoans(), extraMonthly: fromRupees(5000), strategy: PayoffStrategy.snowball);
    expect(r.loans.first.loanId, 'L4');
    expect(r.loans.first.nextMonthExtra, fromRupees(5000));
  });

  test('every loan gets a payoff month when the plan succeeds', () {
    final r = simulatePayoff(seedLoans(), extraMonthly: fromRupees(5000));
    expect(r.loans.every((l) => l.payoffMonth != null), isTrue);
    expect(r.loans.map((l) => l.payoffMonth!).reduce((a, b) => a > b ? a : b), r.months - 1);
  });

  test('an installment below interest is never repaid (acceptance 10)', () {
    final bad = Loan(
      id: 'X', loanTypeId: 'personal', name: 'Bad loan', lender: 'Bank',
      principal: fromRupees(100000), outstanding: fromRupees(100000), ratePct: 24,
      method: InterestMethod.reducing, installment: fromRupees(1500), frequency: LoanFrequency.monthly,
    );
    final r = simulatePayoff([bad]);
    expect(r.hitLimit, isTrue);
    expect(r.loans.single.payoffMonth, isNull);
  });

  test('nothing to plan means debt-free now (Review Focus 5)', () {
    expect(simulatePayoff(const []).months, 0);
    final closed = seedLoans().map((l) => l.copyWith(closed: true));
    final zero = seedLoans().map((l) => l.copyWith(outstanding: 0));
    for (final loans in [closed, zero]) {
      final r = simulatePayoff(loans, extraMonthly: fromRupees(5000));
      expect(r.months, 0);
      expect(r.hitLimit, isFalse);
      expect(r.totalInterest, 0);
      expect(r.loans, isEmpty);
    }
  });
}
