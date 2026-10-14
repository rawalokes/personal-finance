import 'dart:math' as math;

import 'loans.dart';
import 'models.dart';
import 'money.dart';

enum PayoffStrategy { avalanche, snowball }

/// Above this a balance is running away (installment below interest); stop.
const Paisa _runawayBalance = 1000000000000000;

class PayoffLoanResult {
  const PayoffLoanResult({
    required this.loanId,
    required this.name,
    required this.payoffMonth,
    required this.nextMonthPayment,
    required this.nextMonthExtra,
  });
  final String loanId;
  final String name;

  /// 0-based month index (0 = next month) in which this loan reaches zero;
  /// null when it never does.
  final int? payoffMonth;

  /// "What to pay next month": installment plus any extra.
  final Paisa nextMonthPayment;
  final Paisa nextMonthExtra;
}

class PayoffResult {
  const PayoffResult({
    required this.months,
    required this.hitLimit,
    required this.totalInterest,
    required this.loans,
  });

  /// Months until every loan is paid (0 = already debt-free).
  final int months;

  /// True when the 600-month limit was reached or a balance ran away.
  final bool hitLimit;
  final Paisa totalInterest;

  /// In the order the strategy sends extra money in the first month.
  final List<PayoffLoanResult> loans;

  Paisa get nextMonthTotal => loans.fold(0, (t, l) => t + l.nextMonthPayment);
}

class PayoffComparison {
  const PayoffComparison({required this.baseline, required this.plan});
  final PayoffResult baseline;
  final PayoffResult plan;
  int get monthsSaved => baseline.months - plan.months;
  Paisa get interestSaved => baseline.totalInterest - plan.totalInterest;
}

class _SimLoan {
  _SimLoan(Loan l)
      : id = l.id,
        name = l.name,
        method = l.method,
        principal = l.principal,
        ratePct = l.ratePct,
        installment = (l.installment / l.frequency.monthsPerPeriod).round(),
        balance = l.outstanding;

  final String id;
  final String name;
  final InterestMethod method;
  final Paisa principal;
  final double? ratePct;

  /// Monthly-equivalent installment.
  final Paisa installment;
  Paisa balance;
  int? done;
  Paisa firstPay = 0;
  Paisa firstExtra = 0;
  int rank = 1 << 30;

  bool get open => balance > 0;

  Paisa monthlyInterest() =>
      interestFor(method: method, balance: balance, principal: principal, ratePct: ratePct);

  /// Annual % comparable across methods.
  double effectiveRate() => switch (method) {
        InterestMethod.reducing => ratePct ?? 0,
        InterestMethod.flat => principal * (ratePct ?? 0) / math.max(balance, 1),
        InterestMethod.none => 0,
      };
}

PayoffResult simulatePayoff(
  Iterable<Loan> loans, {
  Paisa extraMonthly = 0,
  PayoffStrategy strategy = PayoffStrategy.avalanche,
  bool rollover = true,
}) {
  final sims = [for (final l in loans) if (!l.closed && l.outstanding > 0) _SimLoan(l)];
  var month = 0;
  Paisa totalInterest = 0;
  var runaway = false;

  int byStrategy(_SimLoan a, _SimLoan b) {
    final c = strategy == PayoffStrategy.avalanche
        ? b.effectiveRate().compareTo(a.effectiveRate())
        : a.balance.compareTo(b.balance);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  while (sims.any((s) => s.open) && month < kMaxPayoffMonths && !runaway) {
    var pool = extraMonthly;

    // 1. Interest and regular installments; freed installments roll into the pool.
    for (final s in sims) {
      if (!s.open) {
        if (rollover) pool += s.installment;
        continue;
      }
      final interest = s.monthlyInterest();
      totalInterest += interest;
      final pay = math.min(s.installment, s.balance + interest);
      s.balance = s.balance + interest - pay;
      if (month == 0) s.firstPay = pay;
      if (!s.open) {
        s.done ??= month;
        if (rollover) pool += s.installment - pay;
      }
      if (s.balance > _runawayBalance) runaway = true;
    }

    // 2–3. Send the pool to loans in strategy order.
    final order = sims.where((s) => s.open).toList()..sort(byStrategy);
    if (month == 0) {
      for (var i = 0; i < order.length; i++) {
        order[i].rank = i;
      }
    }
    for (final s in order) {
      if (pool <= 0) break;
      final extra = math.min(pool, s.balance);
      s.balance -= extra;
      pool -= extra;
      if (month == 0) {
        s.firstPay += extra;
        s.firstExtra += extra;
      }
      if (!s.open) s.done ??= month;
    }
    month++;
  }

  final ranked = [...sims]..sort((a, b) => a.rank != b.rank ? a.rank.compareTo(b.rank) : a.id.compareTo(b.id));
  return PayoffResult(
    months: month,
    hitLimit: sims.any((s) => s.open),
    totalInterest: totalInterest,
    loans: [
      for (final s in ranked)
        PayoffLoanResult(
          loanId: s.id,
          name: s.name,
          payoffMonth: s.done,
          nextMonthPayment: s.firstPay,
          nextMonthExtra: s.firstExtra,
        ),
    ],
  );
}

/// Baseline = no extra and no rollover; plan = extra with rollover.
PayoffComparison comparePayoff(
  Iterable<Loan> loans, {
  required Paisa extraMonthly,
  PayoffStrategy strategy = PayoffStrategy.avalanche,
}) =>
    PayoffComparison(
      baseline: simulatePayoff(loans, strategy: strategy, rollover: false),
      plan: simulatePayoff(loans, extraMonthly: extraMonthly, strategy: strategy),
    );
