import 'money.dart';

/// Wants this big get the "wait 24 hours" suggestion (spec: 24-hour rule).
const Paisa kWaitThreshold = 500000;
const kWaitHours = 24;

bool shouldSuggestWaiting({required Paisa amount, required bool essential}) => !essential && amount >= kWaitThreshold;

String _stamp(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

/// Something the user decided to wait 24 hours on before buying.
class WaitItem {
  const WaitItem({required this.id, required this.title, required this.amount, required this.addedAt, this.categoryId, this.accountId});

  final String id;
  final String title;
  final Paisa amount;

  /// 'YYYY-MM-DDTHH:mm:ss' (local time, as the clock stamps it).
  final String addedAt;
  final String? categoryId;
  final String? accountId;

  String get readyAt => _stamp(DateTime.parse(addedAt).add(const Duration(hours: kWaitHours)));
  bool isReady(String now) => now.compareTo(readyAt) >= 0;

  /// Whole hours until ready, rounded up; 0 when ready.
  int hoursLeft(String now) {
    final m = DateTime.parse(readyAt).difference(DateTime.parse(now)).inMinutes;
    return m <= 0 ? 0 : (m + 59) ~/ 60;
  }
}

class WaitList {
  const WaitList({this.items = const [], this.savedByWaiting = 0});
  final List<WaitItem> items;

  /// Everything skipped after waiting: money not spent.
  final Paisa savedByWaiting;

  WaitList add(WaitItem item) => WaitList(items: [...items, item], savedByWaiting: savedByWaiting);

  /// Decided not to buy it: counts as saved.
  WaitList skip(String id) {
    final item = items.where((i) => i.id == id).firstOrNull;
    return WaitList(items: [for (final i in items) if (i.id != id) i], savedByWaiting: savedByWaiting + (item?.amount ?? 0));
  }

  /// Bought it after all.
  WaitList bought(String id) => WaitList(items: [for (final i in items) if (i.id != id) i], savedByWaiting: savedByWaiting);
}
