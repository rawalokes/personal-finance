import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/seed.dart';

import '../../data/sample_data.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/txn/txn_presentation.dart';
import 'package:paisa/ui/txn/txn_query.dart';

const today = '2026-10-14';
final lookup = TxnLookup(accounts: sampleAccounts, categories: seedCategories, incomeTypes: seedIncomeTypes);
final newestFirst = [...sampleTransactions]..sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'));

List<String> ids(Iterable<Txn> txns) => txns.map((t) => t.id).toList();

void main() {
  test('type filters follow the mockup groupings', () {
    expect(ids(sampleTransactions.where(TxnFilter.income.matches)), unorderedEquals(['t14', 't7', 't0']));
    expect(ids(sampleTransactions.where(TxnFilter.transfer.matches)), ['t12']);
    expect(ids(sampleTransactions.where(TxnFilter.loan.matches)), ['t5b']);
    expect(sampleTransactions.where(TxnFilter.all.matches), hasLength(17));
  });

  test('ranges: this month, last 30 days, all time', () {
    expect(TxnRange.month.label(today), 'October 2026');
    expect(sampleTransactions.where((t) => TxnRange.month.contains(t, today)), hasLength(15));
    Txn on(String date) => Txn(id: date, date: date, time: '09:00', title: 'x', type: TxType.expense, accountId: 'cash', amount: 1);
    expect(TxnRange.last30.contains(on('2026-09-14'), today), isTrue, reason: 'exactly 30 days back');
    expect(TxnRange.last30.contains(on('2026-09-13'), today), isFalse);
    expect(TxnRange.month.contains(on('2026-09-30'), today), isFalse);
    expect(TxnRange.all.contains(on('2020-01-01'), today), isTrue);
  });

  test('groupByDay keeps day order, labels Today/Yesterday, and nets each day', () {
    final groups = groupByDay(newestFirst, today);
    expect(groups.first.label, 'Yesterday · 13 Oct 2026');
    final oct12 = groups.firstWhere((g) => g.date == '2026-10-12');
    expect(oct12.label, 'Mon · 12 Oct 2026');
    expect(ids(oct12.items), ['t14', 't13']);
    expect(oct12.net, fromRupees(1240 - 2180));
    final oct5 = groups.firstWhere((g) => g.date == '2026-10-05');
    expect(oct5.net, fromRupees(-1860 - 1000), reason: 'loan repayment counts interest only');
    final oct11 = groups.firstWhere((g) => g.date == '2026-10-11');
    expect(oct11.net, 0, reason: 'a transfer is neither in nor out');
  });

  test('dayLabel says Today for today', () {
    expect(dayLabel(today, today), 'Today · 14 Oct 2026');
  });

  test('in/out totals skip pending and count the whole repayment as out', () {
    const pending = Txn(
      id: 'p', date: '2026-10-14', time: '09:00', title: 'Bonus', type: TxType.income, accountId: 'nabil',
      amount: 999999, status: TxStatus.pending,
    );
    final october = sampleTransactions.where((t) => TxnRange.month.contains(t, today)).toList()..add(pending);
    final (moneyIn, moneyOut) = inOutTotals(october);
    expect(moneyIn, fromRupees(1240 + 25000));
    expect(moneyOut, fromRupees(1695 + 2180 + 4500 + 2180 + 1499 + 1140 + 1860 + 5167 + 10000 + 1240 + 4380 + 22000));
  });

  group('search', () {
    List<String> search(String q) => ids(sampleTransactions.where((t) => matchesQuery(t, q, lookup)));

    test('matches merchant names case-insensitively', () {
      expect(search('bhat-bhateni'), ['t3']);
    });
    test('matches category, income type and account names', () {
      expect(search('groceries'), unorderedEquals(['t10', 't3']));
      expect(search('freelance'), ['t7']);
      expect(search('khalti'), ['t4']);
    });
    test('matches amounts typed with or without commas', () {
      expect(search('22,000'), ['t2']);
      expect(search('22000'), ['t2']);
    });
    test('matches the type name; empty query matches all', () {
      expect(search('loan repayment'), ['t5b']);
      expect(search('  '), hasLength(17));
    });
    test('never matches a fallback name such as Uncategorised', () {
      expect(search('uncategorised'), isEmpty);
    });
  });
}
