import '../finance/dates.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// The app's idea of "now". Production uses the device clock; tests fix it
/// at the mockup's TODAY (2026-10-14) so dates and greetings are stable.
class Clock {
  const Clock(this._now);
  Clock.fixed(DateTime at) : _now = (() => at);

  final DateTime Function() _now;

  DateTime now() => _now();
  IsoDate today() => toIsoDate(now());

  /// 'HH:mm', the time stored on transactions.
  String hhmm() {
    final n = now();
    return '${_two(n.hour)}:${_two(n.minute)}';
  }

  /// 'YYYY-MM-DDTHH:mm:ss', used for createdAt / updatedAt and audit times.
  String stamp() {
    final n = now();
    return '${toIsoDate(n)}T${_two(n.hour)}:${_two(n.minute)}:${_two(n.second)}';
  }
}

const Clock systemClock = Clock(DateTime.now);

/// New row ids. Production: UUID v4. Tests may pass a counter.
typedef IdGen = String Function();
