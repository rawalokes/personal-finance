import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14';

void main() {
  group('future you', () {
    test('NPR 5,000 a month for 10 years at 8% grows to about NPR 9.15 lakh', () {
      final v = futureValue(monthly: fromRupees(5000), years: 10, annualRate: 0.08);
      expect(toWholeRupees(v), inInclusiveRange(914000, 916000));
    });
    test('nothing saved grows to nothing', () => expect(futureValue(monthly: 0, years: 10), 0));
  });

  test('the month plan knows what loans cost in interest this month', () {
    final loan = Loan(id: 'L', loanTypeId: 'p', name: 'Bike', lender: 'B', principal: fromRupees(200000), outstanding: fromRupees(120000),
        ratePct: 12, method: InterestMethod.reducing, installment: fromRupees(10000), frequency: LoanFrequency.monthly, nextDueDate: '2026-10-28');
    final p = monthPlan(txs: const [], accounts: const [], loans: [loan], categories: const [], goals: const [], today: today);
    expect(p.interestThisMonth, fromRupees(1200), reason: '1% a month of 1,20,000');
  });

  group('pay yourself first', () {
    List<Nudge> run(List<Txn> txs, {List<Account>? accounts}) => buildNudges(
          NudgeInput(today: today, txs: txs, accounts: accounts ?? [acct('bank', AccountGroup.liquid, 50000), acct('save', AccountGroup.reserved, 0)],
              categories: const [], loans: const [], goals: const []),
          const MoneyFormat(),
        );

    test('income in the last 7 days with nothing moved to savings since', () {
      final n = run([tx(TxType.income, 'bank', 60000, date: '2026-10-12')]).single;
      expect(n.kind, NudgeKind.payYourselfFirst);
      expect(n.title, 'Income came in — pay yourself first');
      expect(n.body, contains('NPR 12,000'));
    });

    test('quiet once you have moved money to a savings account', () {
      expect(run([
        tx(TxType.income, 'bank', 60000, date: '2026-10-12'),
        tx(TxType.transfer, 'bank', 12000, to: 'save', date: '2026-10-13'),
      ]), isEmpty);
    });

    test('quiet for small or old income', () {
      expect(run([tx(TxType.income, 'bank', 3000, date: '2026-10-12')]), isEmpty);
      expect(run([tx(TxType.income, 'bank', 60000, date: '2026-10-01')]), isEmpty);
    });
  });

  group('24-hour wait list', () {
    const item = WaitItem(id: 'w1', title: 'Headphones', amount: 850000, addedAt: '2026-10-14T10:00:00');
    test('ready after 24 hours', () {
      expect(item.readyAt, '2026-10-15T10:00:00');
      expect(item.isReady('2026-10-15T09:59:00'), isFalse);
      expect(item.isReady('2026-10-15T10:00:00'), isTrue);
      expect(item.hoursLeft('2026-10-14T22:30:00'), 12);
    });
    test('skipping adds to what waiting saved; buying does not', () {
      var w = const WaitList(items: [item]);
      w = w.skip('w1');
      expect(w.items, isEmpty);
      expect(w.savedByWaiting, 850000);
      expect((const WaitList(items: [item])).bought('w1').savedByWaiting, 0);
    });
    test('suggested for wants of NPR 5,000 or more only', () {
      expect(shouldSuggestWaiting(amount: fromRupees(5000), essential: false), isTrue);
      expect(shouldSuggestWaiting(amount: fromRupees(4999), essential: false), isFalse);
      expect(shouldSuggestWaiting(amount: fromRupees(9000), essential: true), isFalse);
    });
  });
}
