import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/budgets.dart';
import 'package:paisa/finance/money.dart';

void main() {
  BudgetLine line(num limit, num spent) =>
      BudgetLine(categoryId: 'fun', limit: fromRupees(limit), spent: fromRupees(spent));

  test('budget states', () {
    expect(line(5000, 5640).state, BudgetState.over);
    expect(line(5000, 5640).remaining, fromRupees(-640));
    expect(line(12000, 10200).state, BudgetState.nearLimit);
    expect(line(12000, 4000).state, BudgetState.ok);
    expect(line(5000, 5000).state, BudgetState.nearLimit);
  });

  test('no limit is never over and refunds never push spending below zero', () {
    expect(line(0, 2144).state, BudgetState.ok);
    expect(line(0, 2144).ratio, 0);
    expect(line(5000, -1500).spent, 0);
  });

  test('emergency fund: essentials 63,000 × 6 against NIC 3,85,000 ≈ 6.1 months', () {
    expect(emergencyFundTarget(fromRupees(63000)), fromRupees(378000));
    expect(emergencyFundMonths(essentialMonthly: fromRupees(63000), saved: fromRupees(385000)), closeTo(6.11, 0.01));
    expect(emergencyFundMonths(essentialMonthly: 0, saved: fromRupees(1)), 0);
  });

  test('recommended monthly saving for a goal', () {
    expect(recommendedMonthlySaving(target: fromRupees(80000), current: fromRupees(32000),
        today: '2026-10-14', targetDate: '2026-12-20'), fromRupees(24000));
    expect(recommendedMonthlySaving(target: fromRupees(180000), current: fromRupees(64000),
        today: '2026-10-14', targetDate: '2027-03-31'), fromRupees(23200));
    expect(recommendedMonthlySaving(target: fromRupees(100), current: fromRupees(100),
        today: '2026-10-14', targetDate: '2027-01-01'), 0);
    expect(recommendedMonthlySaving(target: fromRupees(1000), current: 0,
        today: '2026-10-14', targetDate: '2026-09-01'), fromRupees(1000));
    expect(recommendedMonthlySaving(target: fromRupees(1000), current: 0, today: '2026-10-14'), isNull);
  });
}
