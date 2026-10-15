import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/loans.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';

import 'fixtures.dart';

Loan loan({
  num principal = 100000,
  num outstanding = 100000,
  double? rate = 12,
  InterestMethod method = InterestMethod.reducing,
  num installment = 10000,
  LoanFrequency frequency = LoanFrequency.monthly,
  String? next = '2026-10-31',
}) =>
    Loan(
      id: 'X', loanTypeId: 'personal', name: 'Test loan', lender: 'Bank',
      principal: fromRupees(principal), outstanding: fromRupees(outstanding), ratePct: rate,
      method: method, installment: fromRupees(installment), frequency: frequency, nextDueDate: next,
    );

void main() {
  final loans = {for (final l in seedLoans()) l.id: l};

  test('scooter EMI 11,501 splits into 2,144 interest + 9,357 principal (acceptance 4)', () {
    final s = splitRepayment(loans['L1']!, fromRupees(11501));
    expect(s.interest, fromRupees(2144));
    expect(s.principal, fromRupees(9357));
  });

  test('flat interest uses the original principal', () {
    final s = splitRepayment(loans['L3']!, fromRupees(5167));
    expect(s.interest, fromRupees(1000));
    expect(s.principal, fromRupees(4167));
  });

  test('interest-free loan is all principal', () {
    final s = splitRepayment(loans['L4']!, fromRupees(5000));
    expect(s.interest, 0);
    expect(s.principal, fromRupees(5000));
  });

  test('a small payment covers interest first and never goes negative', () {
    final s = splitRepayment(loans['L1']!, fromRupees(1000));
    expect(s.interest, fromRupees(1000));
    expect(s.principal, 0);
  });

  test('payoffAmount is outstanding plus this period interest', () {
    expect(payoffAmount(loans['L1']!), fromRupees(228640 + 2144));
  });

  test('schedule shows the next 6 installments with dates', () {
    final sch = buildSchedule(loans['L1']!);
    expect(sch.rows, hasLength(6));
    expect(sch.rows.first.dueDate, '2026-10-13');
    expect(sch.rows.first.interest, fromRupees(2144));
    expect(sch.rows.first.principal, fromRupees(9357));
    expect(sch.rows.first.balanceAfter, fromRupees(219283));
    expect(sch.rows[1].dueDate, '2026-11-13');
    expect(sch.neverRepaid, isFalse);
    expect(sch.periods, greaterThan(6));
    expect(sch.payoffDate, isNotNull);
  });

  test('installment at or below interest is never repaid (§5.4)', () {
    final sch = buildSchedule(loan(rate: 24, installment: 2000));
    expect(sch.neverRepaid, isTrue);
    expect(sch.payoffDate, isNull);
  });

  test('a missing rate is reported, not assumed (Review Focus 3)', () {
    final l = loan(outstanding: 131450, rate: null, installment: 6790);
    expect(rateMissing(l), isTrue);
    expect(periodInterest(l), 0);
    final sch = buildSchedule(l);
    expect(sch.neverRepaid, isFalse);
    expect(sch.periods, 20);
    expect(rateMissing(loans['L4']!), isFalse);
  });

  test('quarterly loans charge a quarter of the annual rate and step 3 months', () {
    final sch = buildSchedule(loan(frequency: LoanFrequency.quarterly));
    expect(sch.rows.first.interest, fromRupees(3000));
    expect(sch.rows[1].dueDate, '2027-01-31');
    expect(sch.rows[2].dueDate, '2027-04-30');
  });

  test('month-end due dates do not drift (Review Focus 4)', () {
    final sch = buildSchedule(loan(next: '2027-01-31'));
    expect(sch.rows.map((r) => r.dueDate).take(3), ['2027-01-31', '2027-02-28', '2027-03-31']);
  });
}
