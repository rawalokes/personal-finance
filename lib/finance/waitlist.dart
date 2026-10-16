import 'money.dart';

/// Wants this big get the "wait 24 hours" suggestion (spec: 24-hour rule).
const Paisa kWaitThreshold = 500000;
const kWaitHours = 24;

bool shouldSuggestWaiting({required Paisa amount, required bool essential}) => !essential && amount >= kWaitThreshold;

String _stamp(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

/// Something the user wants to buy: either waiting out the 24 hours, or
/// kept on the wish list (no timer) until they can afford it.
class WaitItem {
  const WaitItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.addedAt,
    this.categoryId,
    this.accountId,
    this.wish = false,
    this.priority = 2,
  });

  final String id;
  final String title;
  final Paisa amount;

  /// 'YYYY-MM-DDTHH:mm:ss' (local time, as the clock stamps it).
  final String addedAt;
  final String? categoryId;
  final String? accountId;

  /// On the wish list rather than the 24-hour wait.
  final bool wish;

  /// 1 = must have, 2 = normal, 3 = someday.
  final int priority;

  WaitItem copyWith({int? priority}) => WaitItem(
        id: id,
        title: title,
        amount: amount,
        addedAt: addedAt,
        categoryId: categoryId,
        accountId: accountId,
        wish: wish,
        priority: priority ?? this.priority,
      );

  String get readyAt => _stamp(DateTime.parse(addedAt).add(const Duration(hours: kWaitHours)));
  bool isReady(String now) => wish || now.compareTo(readyAt) >= 0;

  /// Whole hours until ready, rounded up; 0 when ready.
  int hoursLeft(String now) {
    if (wish) return 0;
    final m = DateTime.parse(readyAt).difference(DateTime.parse(now)).inMinutes;
    return m <= 0 ? 0 : (m + 59) ~/ 60;
  }
}

class WaitList {
  const WaitList({this.items = const [], this.savedByWaiting = 0});
  final List<WaitItem> items;

  /// Everything skipped after waiting: money not spent.
  final Paisa savedByWaiting;

  /// Items still in their 24 hours (or ready to decide), oldest first.
  List<WaitItem> get waiting => [for (final i in items) if (!i.wish) i];

  /// The wish list: must-haves first, then oldest first.
  List<WaitItem> get wishes {
    final w = [for (final i in items) if (i.wish) i];
    return w..sort((a, b) => a.priority != b.priority ? a.priority.compareTo(b.priority) : a.addedAt.compareTo(b.addedAt));
  }

  WaitList setPriority(String id, int priority) =>
      WaitList(items: [for (final i in items) i.id == id ? i.copyWith(priority: priority) : i], savedByWaiting: savedByWaiting);

  WaitList add(WaitItem item) => WaitList(items: [...items, item], savedByWaiting: savedByWaiting);

  /// Decided not to buy it: counts as saved.
  WaitList skip(String id) {
    final item = items.where((i) => i.id == id).firstOrNull;
    return WaitList(items: [for (final i in items) if (i.id != id) i], savedByWaiting: savedByWaiting + (item?.amount ?? 0));
  }

  /// Bought it after all.
  WaitList bought(String id) => WaitList(items: [for (final i in items) if (i.id != id) i], savedByWaiting: savedByWaiting);
}
