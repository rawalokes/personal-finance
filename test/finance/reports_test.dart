import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14';
const fy = '2026-07-17';

ExpenseCategory cat(String id, {String? parent, num? budget, bool essential = false}) => ExpenseCategory(
      id: id, name: id[0].toUpperCase() + id.substring(1), icon: 'tag', parentId: parent,
      monthlyBudget: budget == null ? null : fromRupees(budget), essential: essential,
    );

Loan loan(String id, {num principal = 100000, num outstanding = 25000, num installment = 5000, double? rate, InterestMethod method = InterestMethod.none}) => Loan(
      id: id, loanTypeId: 'personal', name: 'Loan $id', lender: 'Bank', principal: fromRupees(principal),
      outstanding: fromRupees(outstanding), ratePct: rate, method: method, installment: fromRupees(installment),
      frequency: LoanFrequency.monthly,
    );

void main() {
  group('periods', () {
    test('resolve to inclusive calendar ranges ending today', () {
      expect(resolvePeriod(ReportPeriod.thisMonth, today, fyStart: fy), const DateRange('2026-10-01', today));
      expect(resolvePeriod(ReportPeriod.lastMonth, today, fyStart: fy), const DateRange('2026-09-01', '2026-09-30'));
      expect(resolvePeriod(ReportPeriod.last3m, today, fyStart: fy), const DateRange('2026-08-01', today));
      expect(resolvePeriod(ReportPeriod.last12m, today, fyStart: fy), const DateRange('2025-11-01', today));
      expect(resolvePeriod(ReportPeriod.thisFy, today, fyStart: fy), const DateRange(fy, today));
      expect(const DateRange('2026-08-01', today).months(), ['2026-08', '2026-09', '2026-10']);
    });

    test('the previous range has the same number of months just before', () {
      expect(previousRange(const DateRange('2026-10-01', today)), const DateRange('2026-09-01', '2026-09-14'), reason: 'same point last month');
      expect(previousRange(const DateRange('2026-08-01', today)), const DateRange('2026-05-01', '2026-07-14'));
      expect(previousRange(const DateRange('2026-09-01', '2026-09-30')), const DateRange('2026-08-01', '2026-08-31'));
      expect(previousRange(const DateRange(fy, today)), const DateRange('2025-07-17', '2025-10-14'), reason: 'same span of last fiscal year');
    });

    test('wire names round-trip and unknown falls back to this month', () {
      for (final p in ReportPeriod.values) {
        expect(ReportPeriod.fromWire(p.wire), p);
      }
      expect(ReportPeriod.fromWire('nonsense'), ReportPeriod.thisMonth);
    });
  });

  test('cash flow: actual months, pending and other accounts excluded, forecast from recurring rules', () {
    final txs = [
      tx(TxType.income, 'a', 50000, date: '2026-09-05'),
      tx(TxType.expense, 'a', 2000, date: '2026-09-06', cat: 'food'),
      tx(TxType.expense, 'a', 3000, date: '2026-10-02', cat: 'food'),
      tx(TxType.income, 'a', 9999, date: '2026-10-03', status: TxStatus.pending),
      tx(TxType.expense, 'b', 700, date: '2026-10-04', cat: 'food'),
    ];
    final rules = [
      const RecurringRule(id: 'r1', name: 'Salary', kind: RecurringKind.income, amount: 4000000, accountId: 'a', frequency: RecurringFrequency.monthly, nextDate: '2026-11-01'),
      const RecurringRule(id: 'r2', name: 'Rent', kind: RecurringKind.expense, amount: 1200000, accountId: 'a', frequency: RecurringFrequency.yearly, nextDate: '2026-11-01'),
    ];
    final points = cashFlow(txs, const DateRange('2026-08-01', today), accountIds: {'a'}, recurring: rules, today: today);
    expect(points.map((p) => p.month), ['2026-08', '2026-09', '2026-10', '2026-11', '2026-12', '2027-01']);
    expect(points[1].income, fromRupees(50000));
    expect(points[1].expenses, fromRupees(2000));
    expect(points[2].income, 0, reason: 'pending income is not actual');
    expect(points[2].expenses, fromRupees(3000), reason: 'account b is filtered out');
    expect(points[3].kind, PointKind.forecast);
    expect(points[3].income, fromRupees(40000));
    expect(points[3].expenses, fromRupees(1000), reason: 'a yearly rule counts one twelfth a month');
    expect(cashFlow(txs, const DateRange('2026-09-01', '2026-09-30'), today: today), hasLength(1), reason: 'no forecast for past ranges');
  });

  test('spending by category rolls subcategories up, nets refunds and honours the category filter', () {
    final cats = [cat('food'), cat('dining', parent: 'food'), cat('rent')];
    final txs = [
      tx(TxType.expense, 'a', 500, cat: 'dining', date: '2026-10-02'),
      tx(TxType.expense, 'a', 300, cat: 'food', date: '2026-10-03'),
      tx(TxType.refund, 'a', 100, cat: 'food', date: '2026-10-04'),
      tx(TxType.expense, 'a', 1000, cat: 'rent', date: '2026-10-05'),
    ];
    final slices = spendingByCategory(txs, const DateRange('2026-10-01', today), cats);
    expect(slices.map((s) => (s.id, s.value)), [('rent', fromRupees(1000)), ('food', fromRupees(700))]);
    expect(slices.last.label, 'Food');
    expect(spendingByCategory(txs, const DateRange('2026-10-01', today), cats, categoryIds: {'food'}).single.id, 'food');
  });

  test('income by party labels money with no party', () {
    final txs = [
      tx(TxType.income, 'a', 20000, party: 'p1', date: '2026-10-01'),
      tx(TxType.income, 'a', 5000, date: '2026-10-02'),
    ];
    final s = incomeBySource(txs, const DateRange('2026-10-01', today), groupBy: IncomeGrouping.party, parties: {'p1': 'Smartloan'});
    expect(s.map((x) => x.label), ['Smartloan', 'No party set']);
    expect(s.last.id, kNoParty);
  });

  test('net worth is rebuilt month by month from today backwards', () {
    final accounts = [acct('a', AccountGroup.liquid, 100000)];
    final txs = [
      tx(TxType.expense, 'a', 2000, cat: 'food', date: '2026-10-05'),
      tx(TxType.income, 'a', 50000, date: '2026-09-10'),
    ];
    final s = netWorthSeries(accounts, const [], txs, const DateRange('2026-08-01', today), today);
    expect(s.where((p) => p.kind == PointKind.actual).map((p) => p.value), [fromRupees(52000), fromRupees(102000), fromRupees(100000)]);
  });

  test('interest paid per month with a loan filter', () {
    final txs = [
      tx(TxType.loanRepayment, 'a', 6000, loanId: 'L1', principal: 4800, interest: 1200, date: '2026-09-13'),
      tx(TxType.loanRepayment, 'a', 2000, loanId: 'L2', principal: 1700, interest: 300, date: '2026-09-20'),
    ];
    final s = interestPaid(txs, const DateRange('2026-09-01', today), loanIds: {'L1'});
    expect(s.map((p) => (p.label, p.value)), [('2026-09', fromRupees(1200)), ('2026-10', 0)]);
  });

  test('budgets, loans, savings and top payees', () {
    final txs = [
      tx(TxType.income, 'a', 10000, date: '2026-09-01'),
      tx(TxType.expense, 'a', 8000, cat: 'food', party: 'p1', date: '2026-09-02'),
      tx(TxType.income, 'a', 10000, date: '2026-10-01'),
      tx(TxType.expense, 'a', 1000, cat: 'food', party: 'p2', date: '2026-10-02'),
      tx(TxType.expense, 'a', 500, cat: 'food', party: 'p2', date: '2026-10-03'),
    ];
    final b = budgetPerformance(txs, [cat('food', budget: 1200), cat('rent')], '2026-10');
    expect(b.single.spent, fromRupees(1500));
    expect(b.single.state, BudgetState.over);

    final lp = loanProgress([loan('L1'), loan('L2', outstanding: 0)]).single;
    expect(lp.repaidRatio, closeTo(0.75, 1e-9));
    expect(lp.monthsLeft, 5);

    final sv = savingsSeries(txs, const DateRange('2026-09-01', today));
    expect(sv.map((p) => p.saved), [fromRupees(2000), fromRupees(8500)]);
    expect(sv.last.cumulative, fromRupees(10500));
    expect(sv.first.rate, closeTo(0.2, 1e-9));

    final top = topPayees(txs, const DateRange('2026-09-01', today), {'p1': 'Daraz', 'p2': 'Bhatbhateni'});
    expect(top.map((s) => s.label), ['Daraz', 'Bhatbhateni']);
  });

  test('review fix: net worth forecasts the next 3 months from recurring rules', () {
    final accounts = [acct('a', AccountGroup.liquid, 100000)];
    const rules = [RecurringRule(id: 'r', name: 'Salary', kind: RecurringKind.income, amount: 1000000, accountId: 'a', frequency: RecurringFrequency.monthly, nextDate: '2026-11-01')];
    final s = netWorthSeries(accounts, const [], const [], const DateRange('2026-10-01', today), today, recurring: rules);
    expect(s.map((p) => (p.label, p.value, p.kind)), [
      ('2026-10', fromRupees(100000), PointKind.actual),
      ('2026-11', fromRupees(110000), PointKind.forecast),
      ('2026-12', fromRupees(120000), PointKind.forecast),
      ('2027-01', fromRupees(130000), PointKind.forecast),
    ]);
  });
}
