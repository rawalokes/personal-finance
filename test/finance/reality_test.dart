import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14'; // day 14 of 31

Loan loan(String id, {num outstanding = 100000, num installment = 10000, double? rate = 12, String due = '2026-10-28'}) => Loan(
    id: id, loanTypeId: 'p', name: 'Loan $id', lender: 'B', principal: fromRupees(200000), outstanding: fromRupees(outstanding),
    ratePct: rate, method: InterestMethod.reducing, installment: fromRupees(installment), frequency: LoanFrequency.monthly, nextDueDate: due);

const food = ExpenseCategory(id: 'food', name: 'Food', icon: 't', essential: true);
const rent = ExpenseCategory(id: 'rent', name: 'Rent', icon: 't', essential: true);
const fun = ExpenseCategory(id: 'fun', name: 'Fun', icon: 't');
const shop = ExpenseCategory(id: 'shop', name: 'Shopping', icon: 't');
const snacks = ExpenseCategory(id: 'snacks', name: 'Snacks', icon: 't', parentId: 'fun');

/// Three full months (Jul–Sep) of [income] in and [spend] spent per category.
List<Txn> history({num income = 100000, Map<String, num> spend = const {'food': 20000, 'rent': 20000, 'fun': 15000, 'shop': 5000}}) => [
      for (final m in ['2026-07', '2026-08', '2026-09']) ...[
        tx(TxType.income, 'bank', income, date: '$m-01'),
        for (final e in spend.entries) tx(TxType.expense, 'bank', e.value, cat: e.key, date: '$m-05'),
      ],
    ];

void main() {
  group('monthly averages', () {
    test('average of the last three complete months with data, ignoring this month', () {
      final a = monthlyAverages([...history(), tx(TxType.income, 'bank', 999999, date: '2026-10-01')], today);
      expect(a.months, 3);
      expect(a.income, fromRupees(100000));
      expect(a.spending, fromRupees(60000));
      expect(a.surplus, fromRupees(40000));
      expect(a.savingsRate, closeTo(0.4, 1e-9));
      expect(a.byCategory['food'], fromRupees(20000));
      expect(a.hourlyIncome, (fromRupees(100000) / kWorkHoursPerMonth).round());
    });

    test('loan principal is not spending but leaves less cash to save', () {
      final a = monthlyAverages([
        ...history(),
        for (final m in ['2026-07', '2026-08', '2026-09'])
          tx(TxType.loanRepayment, 'bank', 10000, loanId: 'L', principal: 9000, interest: 1000, date: '$m-10'),
      ], today);
      expect(a.spending, fromRupees(61000), reason: 'interest is spending');
      expect(a.principal, fromRupees(9000));
      expect(a.cashLeft, fromRupees(30000));
    });

    test('months without any data are skipped; with no history at all, this month is used', () {
      final one = monthlyAverages([tx(TxType.income, 'bank', 50000, date: '2026-09-01')], today);
      expect((one.months, one.income), (1, fromRupees(50000)));
      final fresh = monthlyAverages([tx(TxType.income, 'bank', 30000, date: '2026-10-01')], today);
      expect((fresh.months, fresh.income), (1, fromRupees(30000)));
      final none = monthlyAverages(const [], today);
      expect((none.months, none.income, none.hourlyIncome), (0, 0, null));
    });
  });

  group('habit check', () {
    HabitReport check({List<Txn>? txs, List<Loan> loans = const [], num reserved = 0}) => habitCheck(
          txs: txs ?? history(),
          accounts: [acct('bank', AccountGroup.liquid, 50000), acct('save', AccountGroup.reserved, reserved)],
          loans: loans,
          categories: const [food, rent, fun, shop],
          today: today,
        );

    HabitMetric metric(HabitReport r, HabitKind k) => r.metrics.firstWhere((m) => m.kind == k);

    test('a healthy month: no debt, 40% saved, but no emergency fund', () {
      final r = check();
      expect(metric(r, HabitKind.emiLoad).level, Level.good);
      expect(metric(r, HabitKind.savingsRate).level, Level.good);
      expect(metric(r, HabitKind.emergencyFund).level, Level.bad);
      expect(r.overall, Level.watch, reason: 'one red flag');
    });

    test('heavy EMIs and big debt are red; debt-free date is the last loan paid off', () {
      final r = check(loans: [loan('A', outstanding: 600000, installment: 30000), loan('B', outstanding: 500000, installment: 15000, rate: 18)], reserved: 400000);
      expect(r.monthlyEmi, fromRupees(45000));
      expect(metric(r, HabitKind.emiLoad).value, closeTo(0.45, 1e-9));
      expect(metric(r, HabitKind.emiLoad).level, Level.bad);
      expect(r.totalDebt, fromRupees(1100000));
      expect(metric(r, HabitKind.debtSize).value, closeTo(11, 1e-9));
      expect(metric(r, HabitKind.debtSize).level, Level.watch);
      expect(r.debtFreeDate, isNotNull);
      expect(r.debtFreeDate!.compareTo('2027-12-01'), greaterThan(0));
      expect(r.interestPerMonth, greaterThan(0));
    });

    test('spending more than you earn is red, and the overall verdict is red with two red flags', () {
      final r = check(txs: history(income: 50000));
      expect(metric(r, HabitKind.savingsRate).level, Level.bad);
      expect(r.overall, Level.bad);
    });

    test('top leaks are the biggest non-essential categories, subcategories rolled up', () {
      final r = habitCheck(
        txs: history(spend: {'food': 20000, 'fun': 8000, 'snacks': 4000, 'shop': 9000}),
        accounts: const [],
        loans: const [],
        categories: const [food, fun, shop, snacks],
        today: today,
      );
      expect([for (final l in r.leaks) l.$1], ['fun', 'shop']);
      expect(r.leaks.first.$2, fromRupees(12000));
    });
  });

  group('goal reality', () {
    Goal goal(String id, num target, String? date, {num current = 0}) =>
        Goal(id: id, name: id, kind: 'k', target: fromRupees(target), current: fromRupees(current), targetDate: date);
    final avg = monthlyAverages(history(), today); // 40,000 left a month

    test('realistic, stretch and not realistic against what you really save', () {
      final checks = goalChecks(
        goals: [goal('easy', 150000, '2027-04-14'), goal('tight', 30000, '2027-10-14'), goal('dream', 1000000, '2027-10-14')],
        accounts: const [],
        averages: avg,
        today: today,
      );
      final byId = {for (final c in checks) c.goal.id: c};
      // easy needs 25,000/month of 40,000 → realistic; 15,000 left over.
      expect(byId['easy']!.verdict, GoalVerdict.realistic);
      // tight (2,500/month) and dream (83,334/month) share the 15,000 left: dates tie, so list order.
      expect(byId['tight']!.verdict, GoalVerdict.realistic);
      expect(byId['dream']!.verdict, GoalVerdict.notRealistic);
      expect(byId['dream']!.shortBy, greaterThan(0));
      expect(byId['dream']!.monthsAtPace, isNotNull);
      expect(byId['dream']!.paceDate!.compareTo('2027-10-14'), greaterThan(0));
    });

    test('stretch when it needs most of what is left', () {
      final c = goalChecks(goals: [goal('g', 360000, '2027-04-14')], accounts: const [], averages: avg, today: today).single;
      expect(c.need, fromRupees(60000));
      expect(c.verdict, GoalVerdict.notRealistic);
      final s = goalChecks(goals: [goal('g', 210000, '2027-04-14')], accounts: const [], averages: avg, today: today).single;
      expect(s.verdict, GoalVerdict.stretch, reason: '35,000 of 40,000');
    });

    test('done goals and goals without a date', () {
      final checks = goalChecks(goals: [goal('done', 1000, null, current: 1000), goal('open', 80000, null)], accounts: const [], averages: avg, today: today);
      expect(checks[0].verdict, GoalVerdict.done);
      expect(checks[1].verdict, GoalVerdict.noDate);
      expect(checks[1].monthsAtPace, 2);
    });

    test('nothing left each month: not realistic and no pace', () {
      final c = goalChecks(goals: [goal('g', 50000, '2027-04-14')], accounts: const [], averages: monthlyAverages(history(income: 60000), today), today: today).single;
      expect(c.verdict, GoalVerdict.notRealistic);
      expect(c.monthsAtPace, isNull);
    });
  });

  group('can I afford it', () {
    final avg = monthlyAverages(history(), today);
    MonthPlan planWith(num have) =>
        monthPlan(txs: const [], accounts: [acct('bank', AccountGroup.liquid, have)], loans: const [], categories: const [], goals: const [], today: today);

    test('fits easily: yes, with what it costs in work hours and in 10 years', () {
      final c = canAfford(price: fromRupees(6500), plan: planWith(100000), averages: avg, goals: const [], accounts: const [], today: today);
      expect(c.verdict, AffordVerdict.yes);
      expect(c.reason, AffordReason.fitsEasily);
      expect(c.workHours, closeTo(6500 / (100000 / kWorkHoursPerMonth), 0.1));
      expect(c.futureValue10y, closeTo(fromRupees(6500 * 2.1589), fromRupees(5)));
    });

    test('takes more than half of what is free: wait — unless it is a need', () {
      final c = canAfford(price: fromRupees(60000), plan: planWith(100000), averages: avg, goals: const [], accounts: const [], today: today);
      expect((c.verdict, c.reason), (AffordVerdict.wait, AffordReason.eatsMostOfFree));
      expect(c.monthsToSave, 2);
      final need = canAfford(price: fromRupees(60000), plan: planWith(100000), averages: avg, goals: const [], accounts: const [], today: today, essential: true);
      expect(need.verdict, AffordVerdict.yes);
    });

    test('more than is free to spend, or more than you have: no', () {
      final p = monthPlan(
          txs: const [], accounts: [acct('bank', AccountGroup.liquid, 20000)], loans: [loan('A', installment: 15000)], categories: const [], goals: const [], today: today);
      final c = canAfford(price: fromRupees(10000), plan: p, averages: avg, goals: const [], accounts: const [], today: today);
      expect((c.verdict, c.reason), (AffordVerdict.no, AffordReason.needsSavingsOrEmi));
      final d = canAfford(price: fromRupees(30000), plan: p, averages: avg, goals: const [], accounts: const [], today: today);
      expect((d.verdict, d.reason), (AffordVerdict.no, AffordReason.moreThanYouHave));
    });

    test('how long it pushes back your nearest goal', () {
      final goals = [
        Goal(id: 'far', name: 'Car', kind: 'k', target: fromRupees(900000), targetDate: '2030-01-01'),
        Goal(id: 'near', name: 'Bike', kind: 'k', target: fromRupees(200000), targetDate: '2027-06-01'),
      ];
      final c = canAfford(price: fromRupees(4000), plan: planWith(100000), averages: avg, goals: goals, accounts: const [], today: today);
      expect(c.goalName, 'Bike');
      expect(c.goalDelayDays, 3, reason: '4,000 at 40,000 a month ≈ 3 days');
    });

    test('no income history: no work hours or goal delay', () {
      final c = canAfford(price: fromRupees(100), plan: planWith(100000), averages: monthlyAverages(const [], today), goals: const [], accounts: const [], today: today);
      expect(c.workHours, isNull);
      expect(c.goalDelayDays, isNull);
    });
  });

  group('budget plan', () {
    final avg = monthlyAverages(history(spend: {'food': 25000, 'rent': 25000, 'fun': 30000, 'shop': 10000}), today);
    PlanLine line(BudgetPlan p, String id) => p.lines.firstWhere((l) => l.categoryId == id);

    test('50/30/20: wants cut to 30% of income, needs kept, 20% saved', () {
      final p = buildBudgetPlan(method: BudgetMethod.fiftyThirtyTwenty, averages: avg, categories: const [food, rent, fun, shop], loans: const []);
      expect(line(p, 'food').suggested, fromRupees(25000));
      expect(line(p, 'fun').suggested + line(p, 'shop').suggested, lessThanOrEqualTo(fromRupees(30000)));
      expect(line(p, 'fun').suggested, fromRupees(22500));
      expect(p.save, greaterThanOrEqualTo(fromRupees(20000)));
      expect(p.save + p.extraDebt + p.emis + p.lines.fold<Paisa>(0, (s, l) => s + l.suggested), p.income, reason: 'every rupee has a job');
    });

    test('zero-based: wants trimmed 15%, leftover split between saving and costly debt', () {
      final p = buildBudgetPlan(method: BudgetMethod.zeroBased, averages: avg, categories: const [food, rent, fun, shop], loans: [loan('A', installment: 5000, rate: 15)]);
      expect(line(p, 'fun').suggested, fromRupees(25500));
      expect(p.emis, fromRupees(5000));
      expect(p.extraDebt, greaterThan(0));
      expect(p.extraDebtLoanId, 'A');
      expect(p.save + p.extraDebt + p.emis + p.lines.fold<Paisa>(0, (s, l) => s + l.suggested), p.income);
    });

    test('debt first (avalanche): 10% saved, the rest of what is left to the costliest loan', () {
      final p = buildBudgetPlan(
          method: BudgetMethod.debtFirst, averages: avg, categories: const [food, rent, fun, shop], loans: [loan('A', rate: 11, installment: 5000), loan('B', rate: 16, installment: 5000)]);
      expect(p.extraDebtLoanId, 'B');
      expect(p.save, fromRupees(10000));
      expect(line(p, 'fun').suggested, fromRupees(21000));
      expect(p.save + p.extraDebt + p.emis + p.lines.fold<Paisa>(0, (s, l) => s + l.suggested), p.income);
    });

    test('recommended method follows the habits', () {
      HabitReport h({List<Loan> loans = const [], num income = 100000}) =>
          habitCheck(txs: history(income: income), accounts: const [], loans: loans, categories: const [food, rent, fun, shop], today: today);
      expect(recommendedMethod(h(loans: [loan('A', installment: 40000)])), BudgetMethod.debtFirst);
      expect(recommendedMethod(h(income: 65000)), BudgetMethod.fiftyThirtyTwenty);
      expect(recommendedMethod(h()), BudgetMethod.zeroBased);
    });

    test('no income: nothing to plan', () {
      final p = buildBudgetPlan(method: BudgetMethod.fiftyThirtyTwenty, averages: monthlyAverages(const [], today), categories: const [food], loans: const []);
      expect(p.lines, isEmpty);
      expect(p.save, 0);
    });
  });

  group('plan vs reality', () {
    test('a finished month: saved against target, budgets over, missed EMI, and fixes', () {
      final r = monthReview(
        txs: [
          tx(TxType.income, 'bank', 100000, date: '2026-09-01'),
          tx(TxType.expense, 'bank', 15000, cat: 'fun', date: '2026-09-03'),
          tx(TxType.expense, 'bank', 75000, cat: 'food', date: '2026-09-04'),
        ],
        categories: const [
          ExpenseCategory(id: 'fun', name: 'Fun', icon: 't', monthlyBudget: 1000000),
          ExpenseCategory(id: 'food', name: 'Food', icon: 't', monthlyBudget: 5000000, essential: true),
        ],
        loans: [loan('A')],
        goals: const [],
        accounts: const [],
        month: '2026-09',
        today: today,
      );
      expect(r.complete, isTrue);
      expect((r.saveTarget, r.saved), (fromRupees(20000), fromRupees(10000)));
      expect((r.emisPaid, r.emisExpected), (0, 1));
      expect(r.budgetsOver, 2);
      expect(r.verdict, Level.bad);
      expect([for (final f in r.fixes) f.kind], [FixKind.cutCategory, FixKind.cutCategory, FixKind.saveFirst, FixKind.payEmi]);
      expect(r.fixes.first.categoryId, 'food');
      expect(r.fixes.first.amount, fromRupees(25000));
    });

    test('a month in progress is judged on pace, and unpaid EMIs are not missed yet', () {
      final r = monthReview(
        txs: [tx(TxType.income, 'bank', 100000, date: '2026-10-01'), tx(TxType.expense, 'bank', 80000, cat: 'x', date: '2026-10-02')],
        categories: const [],
        loans: [loan('A')],
        goals: const [],
        accounts: const [],
        month: '2026-10',
        today: today,
      );
      expect(r.complete, isFalse);
      expect(r.fraction, closeTo(14 / 31, 1e-9));
      expect(r.saved, fromRupees(20000));
      expect(r.verdict, Level.good);
      expect(r.fixes.map((f) => f.kind), [FixKind.setBudgets]);
    });

    test('BS month keys work', () {
      final r = monthReview(
          txs: const [], categories: const [], loans: const [], goals: const [], accounts: const [], month: 'B2083-05', today: today, cal: const BsCalendar());
      expect(r.complete, isTrue);
    });
  });
}
