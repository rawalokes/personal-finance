import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14';
const cats = [
  ExpenseCategory(id: 'food', name: 'Food', icon: 't', monthlyBudget: 1000000),
  ExpenseCategory(id: 'dining', name: 'Dining', icon: 't', parentId: 'food'),
  ExpenseCategory(id: 'rent', name: 'Rent', icon: 't'),
];

void main() {
  final txs = [
    tx(TxType.expense, 'a', 3000, cat: 'food', date: '2026-10-02'),
    tx(TxType.expense, 'a', 2000, cat: 'dining', date: '2026-10-05'),
    tx(TxType.refund, 'a', 500, cat: 'food', date: '2026-10-06'),
    tx(TxType.expense, 'a', 9000, cat: 'rent', date: '2026-10-01'),
    tx(TxType.expense, 'a', 4000, cat: 'food', date: '2026-09-03'),
    tx(TxType.expense, 'a', 1000, cat: 'food', date: '2026-10-09', status: TxStatus.pending),
  ];
  const range = DateRange('2026-10-01', today);

  test('a category includes its subcategories, nets refunds and skips pending', () {
    final d = categoryDetail(txs, cats, 'food', range, today: today);
    expect(d.total, fromRupees(4500));
    expect(d.transactions.map((t) => t.categoryId), everyElement(isIn(['food', 'dining'])));
    expect(d.transactions, hasLength(3));
    expect(d.transactions.first.date, '2026-10-06', reason: 'newest first');
  });

  test('previous period and a 6-month trend ending this month', () {
    final d = categoryDetail(txs, cats, 'food', range, today: today);
    expect(d.previousTotal, fromRupees(4000));
    expect(d.trend.map((p) => p.label), ['2026-05', '2026-06', '2026-07', '2026-08', '2026-09', '2026-10']);
    expect(d.trend.last.value, fromRupees(4500));
    expect(d.budget, fromRupees(10000));
  });

  test('where the money went: top places by amount', () {
    final more = [
      ...txs,
      tx(TxType.expense, 'a', 2500, cat: 'food', date: '2026-10-10'),
    ];
    final d = categoryDetail(more, cats, 'food', range, today: today);
    expect(d.places.first.value, greaterThanOrEqualTo(d.places.last.value));
    expect(d.places.fold<int>(0, (s, p) => s + p.value), fromRupees(7500), reason: 'refunds are not places');
  });

  test('all categories with share and change for the overview', () {
    final rows = categoryOverview(txs, cats, range, today: today);
    expect(rows.map((r) => r.id), ['rent', 'food']);
    expect(rows.first.share, closeTo(9000 / 13500, 1e-9));
    expect(rows.last.previous, fromRupees(4000));
  });
}
