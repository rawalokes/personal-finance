import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14'; // day 14 of 31 → 17 days left

ExpenseCategory c(String id, {num? budget, bool essential = false}) => ExpenseCategory(
    id: id, name: id[0].toUpperCase() + id.substring(1), icon: 'tag',
    monthlyBudget: budget == null ? null : fromRupees(budget), essential: essential);

List<Nudge> run({
  List<Txn> txs = const [],
  List<Account> accounts = const [],
  List<ExpenseCategory> categories = const [],
  List<Loan> loans = const [],
  List<Goal> goals = const [],
  Map<String, String> parties = const {},
  MoneyFormat money = const MoneyFormat(),
  Map<String, String> dismissed = const {},
  Set<NudgeKind> disabled = const {},
  bool challengeDone = false,
}) =>
    buildNudges(
      NudgeInput(today: today, txs: txs, accounts: accounts, categories: categories, loans: loans, goals: goals,
          parties: parties, challengeDoneThisMonth: challengeDone),
      money,
      dismissed: dismissed,
      disabled: disabled,
    );

Loan emiLoan({String due = '2026-10-16'}) => Loan(id: 'L1', loanTypeId: 'p', name: 'Smartloan', lender: 'X',
    principal: fromRupees(300000), outstanding: fromRupees(200000), ratePct: 12, method: InterestMethod.reducing,
    installment: fromRupees(12500), frequency: LoanFrequency.monthly, nextDueDate: due, repaymentAccountId: 'nimb');

void main() {
  test('no data: no nudges', () => expect(run(), isEmpty));

  test('EMI due in 2 days, and the repayment account is short', () {
    final n = run(loans: [emiLoan()], accounts: [acct('nimb', AccountGroup.liquid, 10000)]).single;
    expect(n.kind, NudgeKind.emiDue);
    expect(n.title, 'Smartloan EMI of NPR 12,500 due in 2 days');
    expect(n.body, 'nimb is short by NPR 2,500.');
    expect(n.route, '/loans/L1');
  });

  test('budget pace: 90% used with 17 days left', () {
    final n = run(categories: [c('food', budget: 10000)], txs: [tx(TxType.expense, 'a', 9000, cat: 'food', date: '2026-10-03')]).single;
    expect(n.kind, NudgeKind.budgetPace);
    expect(n.title, 'Food: 90% of budget used');
    expect(n.body, startsWith('17 days left'));
  });

  List<Txn> spike({required num now}) => [
        for (final m in ['07', '08', '09']) tx(TxType.expense, 'a', 3000, cat: 'dining', date: '2026-$m-20'),
        tx(TxType.expense, 'a', now, cat: 'dining', date: '2026-10-05'),
      ];

  test('category spike: well above the pro-rated 3-month average', () {
    final n = run(categories: [c('dining')], txs: spike(now: 6000)).single;
    expect(n.kind, NudgeKind.categorySpike);
    expect(n.title, startsWith('Dining is NPR'));
    expect(n.route, '/search?q=Dining');
  });

  test('a small spike under NPR 1,000 is not worth a nudge', () {
    expect(run(categories: [c('dining')], txs: spike(now: 2000)), isEmpty);
  });

  test('one nudge per topic: budget pace wins over a spike in the same category', () {
    final n = run(categories: [c('dining', budget: 6500)], txs: spike(now: 6000));
    expect(n.map((x) => x.kind), [NudgeKind.budgetPace]);
  });

  test('three payments to one party in a week', () {
    final txs = [for (final d in ['09', '11', '13']) tx(TxType.expense, 'a', 2600, party: 'p1', cat: 'x', date: '2026-10-$d')];
    final n = run(txs: txs, parties: {'p1': 'Daraz'}).single;
    expect(n.title, '3 payments to Daraz this week');
    expect(run(txs: txs.take(2).toList(), parties: {'p1': 'Daraz'}), isEmpty);
  });

  test('loan extra: 10% of last month surplus, rounded to NPR 500', () {
    final txs = [tx(TxType.income, 'a', 100000, date: '2026-09-01'), tx(TxType.expense, 'a', 60000, cat: 'x', date: '2026-09-02')];
    final n = run(txs: txs, loans: [emiLoan(due: '2026-11-20')]).where((x) => x.kind == NudgeKind.loanExtra).single;
    expect(n.title, 'Pay NPR 4,000 extra a month on Smartloan');
    expect(n.route, '/loans/planner?extra=4000');
  });

  test('surplus to goal and emergency fund', () {
    final txs = [tx(TxType.income, 'a', 50000, date: '2026-09-01'), tx(TxType.expense, 'a', 20000, cat: 'rent', date: '2026-09-02')];
    final n = run(
      txs: txs,
      categories: [c('rent', budget: 20000, essential: true)],
      accounts: [acct('save', AccountGroup.reserved, 30000)],
      goals: [Goal(id: 'g1', name: 'Bike', kind: 'Major purchase', target: fromRupees(100000), current: fromRupees(10000))],
    );
    expect(n.map((x) => x.kind), containsAll([NudgeKind.surplusToGoal, NudgeKind.emergencyFund]));
    expect(n.firstWhere((x) => x.kind == NudgeKind.emergencyFund).title, 'Your emergency fund covers 1.5 of 6 months');
  });

  test('praise when spending is 10%+ below the same point last month', () {
    final txs = [tx(TxType.expense, 'a', 10000, cat: 'x', date: '2026-09-10'), tx(TxType.expense, 'a', 5000, cat: 'x', date: '2026-10-10')];
    expect(run(txs: txs).single.title, 'You’ve spent 50% less than last month 🎉');
    expect(run(challengeDone: true).single.kind, NudgeKind.praise);
  });

  test('dismissed for 7 days, then back; disabled kinds never show', () {
    final n = run(loans: [emiLoan()]).single;
    expect(run(loans: [emiLoan()], dismissed: {n.id: '2026-10-20'}), isEmpty);
    expect(run(loans: [emiLoan()], dismissed: {n.id: '2026-10-13'}), hasLength(1));
    expect(run(loans: [emiLoan()], disabled: {NudgeKind.emiDue}), isEmpty);
  });

  test('masked money: no amounts leak when balances are hidden', () {
    final n = run(loans: [emiLoan()], accounts: [acct('nimb', AccountGroup.liquid, 10000)], money: const MoneyFormat(masked: true)).single;
    expect('${n.title} ${n.body}', isNot(contains('12,500')));
    expect('${n.title} ${n.body}', isNot(contains('2,500')));
  });

  test('review fix: a new user with one month of history is compared with that month, not a 3-month average', () {
    final txs = [tx(TxType.expense, 'a', 10000, cat: 'food', date: '2026-09-20'), tx(TxType.expense, 'a', 5000, cat: 'food', date: '2026-10-05')];
    expect(run(categories: [c('food')], txs: txs), isEmpty);
  });
}
