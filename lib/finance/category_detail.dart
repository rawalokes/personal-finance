import 'calendar.dart';
import 'catalog.dart';
import 'dates.dart';
import 'models.dart';
import 'money.dart';
import 'reports.dart';

/// One expense category over a period: what was spent, how it compares,
/// where it went and every transaction behind it.
class CategoryDetail {
  const CategoryDetail({
    required this.category,
    required this.total,
    required this.previousTotal,
    required this.trend,
    required this.places,
    required this.transactions,
  });

  final ExpenseCategory? category;

  /// Spending net of refunds, subcategories included.
  final Paisa total;
  final Paisa previousTotal;

  /// The last 6 months, oldest first, ending this month.
  final List<ReportPoint> trend;

  /// Where the money went (by merchant / title), biggest first, up to 5.
  final List<ReportSlice> places;

  /// Expenses and refunds in the period, newest first.
  final List<Txn> transactions;

  Paisa? get budget => category?.monthlyBudget;
}

/// [id] and every subcategory under it.
Set<String> categoryFamily(Iterable<ExpenseCategory> categories, String id) {
  final out = {id};
  var grew = true;
  while (grew) {
    grew = false;
    for (final c in categories) {
      if (c.parentId != null && out.contains(c.parentId) && out.add(c.id)) grew = true;
    }
  }
  return out;
}

Paisa _net(Iterable<Txn> txs) =>
    txs.fold<Paisa>(0, (s, t) => s + (t.type == TxType.refund ? -t.amount : t.type == TxType.expense ? t.amount : 0));

CategoryDetail categoryDetail(
  Iterable<Txn> txs,
  Iterable<ExpenseCategory> categories,
  String id,
  DateRange range, {
  required IsoDate today,
  MonthCalendar cal = const AdCalendar(),
}) {
  final family = categoryFamily(categories, id);
  final mine = [
    for (final t in txs)
      if (t.isPosted && (t.type == TxType.expense || t.type == TxType.refund) && family.contains(t.categoryId)) t,
  ];
  final inRange = [for (final t in mine) if (range.contains(t.date)) t]
    ..sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'));
  final prev = previousRange(range, cal: cal);
  final month = cal.key(today);
  final places = <String, Paisa>{};
  for (final t in inRange) {
    if (t.type != TxType.expense) continue;
    final name = t.title.trim().isEmpty ? 'Other' : t.title.trim();
    places[name] = (places[name] ?? 0) + t.amount;
  }
  return CategoryDetail(
    category: categories.where((c) => c.id == id).firstOrNull,
    total: _net(inRange),
    previousTotal: _net(mine.where((t) => prev.contains(t.date))),
    trend: [
      for (var k = 5; k >= 0; k--)
        () {
          final m = cal.shift(month, -k);
          return ReportPoint(m, _net(mine.where((t) => cal.key(t.date) == m)), PointKind.actual);
        }(),
    ],
    places: ([for (final e in places.entries) ReportSlice(e.key, e.key, e.value)]..sort((a, b) => b.value.compareTo(a.value))).take(5).toList(),
    transactions: inRange,
  );
}

class CategorySpend {
  const CategorySpend({required this.id, required this.name, required this.total, required this.previous, required this.share});
  final String id;
  final String name;
  final Paisa total;
  final Paisa previous;

  /// Of all spending in the period, 0–1.
  final double share;
}

/// Every category with spending in [range], biggest first, with its share
/// and last period's figure.
List<CategorySpend> categoryOverview(
  Iterable<Txn> txs,
  Iterable<ExpenseCategory> categories,
  DateRange range, {
  required IsoDate today,
  Set<String> accountIds = const {},
  MonthCalendar cal = const AdCalendar(),
}) {
  final now = spendingByCategory(txs, range, categories, accountIds: accountIds, cal: cal);
  final before = {
    for (final s in spendingByCategory(txs, previousRange(range, cal: cal), categories, accountIds: accountIds, cal: cal)) s.id: s.value,
  };
  final sum = now.fold<Paisa>(0, (s, x) => s + x.value);
  return [
    for (final s in now) CategorySpend(id: s.id, name: s.label, total: s.value, previous: before[s.id] ?? 0, share: sum > 0 ? s.value / sum : 0),
  ];
}
