import 'dart:math' as math;

import 'dates.dart';
import 'models.dart';
import 'money.dart';

/// Schedules and the payoff planner stop here (spec §5.5).
const int kMaxPayoffMonths = 600;

/// Rounds paisa to whole rupees, as banks state installment splits.
Paisa roundToRupee(double paisa) => (paisa / 100).round() * 100;

/// Interest for one period. A missing rate is treated as 0 here; callers must
/// show "Not entered" using [rateMissing] instead of presenting it as 0%.
Paisa interestFor({
  required InterestMethod method,
  required Paisa balance,
  required Paisa principal,
  required double? ratePct,
  int periodsPerYear = 12,
}) {
  final rate = ratePct ?? 0;
  return switch (method) {
    InterestMethod.reducing => roundToRupee(balance * rate / (100 * periodsPerYear)),
    InterestMethod.flat => roundToRupee(principal * rate / (100 * periodsPerYear)),
    InterestMethod.none => 0,
  };
}

bool rateMissing(Loan l) => l.method != InterestMethod.none && l.ratePct == null;

Paisa periodInterest(Loan l) => interestFor(
      method: l.method,
      balance: l.outstanding,
      principal: l.principal,
      ratePct: l.ratePct,
      periodsPerYear: l.frequency.periodsPerYear,
    );

/// The most a single repayment can usefully be.
Paisa payoffAmount(Loan l) => l.outstanding + periodInterest(l);

class RepaymentSplit {
  const RepaymentSplit({required this.principal, required this.interest});
  final Paisa principal;
  final Paisa interest;
}

/// Interest first, the rest reduces principal (never below zero outstanding).
RepaymentSplit splitRepayment(Loan l, Paisa amount) {
  final interest = math.min(periodInterest(l), amount);
  final principal = math.min(amount - interest, l.outstanding);
  return RepaymentSplit(principal: principal, interest: interest);
}

class ScheduleRow {
  const ScheduleRow({
    required this.dueDate,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balanceAfter,
  });
  final IsoDate? dueDate;
  final Paisa payment;
  final Paisa principal;
  final Paisa interest;
  final Paisa balanceAfter;
}

class LoanSchedule {
  const LoanSchedule({
    required this.rows,
    required this.periods,
    required this.neverRepaid,
    required this.totalInterest,
    this.payoffDate,
  });

  /// The first rows only (see [buildSchedule]'s maxRows).
  final List<ScheduleRow> rows;

  /// Installments needed to clear the loan.
  final int periods;
  final bool neverRepaid;
  final Paisa totalInterest;
  final IsoDate? payoffDate;
}

LoanSchedule buildSchedule(Loan l, {int maxRows = 6}) {
  final rows = <ScheduleRow>[];
  final first = l.nextDueDate;
  IsoDate? dueAt(int k) => first == null ? null : addMonths(first, k * l.frequency.monthsPerPeriod);

  var balance = l.outstanding;
  var periods = 0;
  Paisa totalInterest = 0;
  while (balance > 0 && periods < kMaxPayoffMonths) {
    final interest = interestFor(
      method: l.method,
      balance: balance,
      principal: l.principal,
      ratePct: l.ratePct,
      periodsPerYear: l.frequency.periodsPerYear,
    );
    if (l.installment <= interest) {
      return LoanSchedule(rows: rows, periods: periods, neverRepaid: true, totalInterest: totalInterest);
    }
    final principal = math.min(l.installment - interest, balance);
    balance -= principal;
    totalInterest += interest;
    if (rows.length < maxRows) {
      rows.add(ScheduleRow(
        dueDate: dueAt(periods),
        payment: principal + interest,
        principal: principal,
        interest: interest,
        balanceAfter: balance,
      ));
    }
    periods++;
  }
  final repaid = balance <= 0;
  return LoanSchedule(
    rows: rows,
    periods: periods,
    neverRepaid: !repaid,
    totalInterest: totalInterest,
    payoffDate: repaid && periods > 0 ? dueAt(periods - 1) : null,
  );
}
