/// Calendar dates as ISO strings ('YYYY-MM-DD'). All maths is done in UTC so
/// daylight-saving and device time zones never shift a day.
typedef IsoDate = String;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime parseIsoDate(IsoDate s) {
  final p = s.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

IsoDate toIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Adds [months] (may be negative). The day is clamped to the target
/// month's length: 31 Jan + 1 month = 28 Feb (29 in leap years).
IsoDate addMonths(IsoDate date, int months) {
  final d = parseIsoDate(date);
  final zeroBased = d.month - 1 + months;
  final month = zeroBased % 12; // Dart's % is never negative for a positive divisor
  final year = d.year + (zeroBased - month) ~/ 12;
  final daysInMonth = DateTime.utc(year, month + 2, 0).day;
  final day = d.day < daysInMonth ? d.day : daysInMonth;
  return toIsoDate(DateTime.utc(year, month + 1, day));
}

/// a − b in whole days.
int daysBetween(IsoDate a, IsoDate b) => parseIsoDate(a).difference(parseIsoDate(b)).inDays;

/// Calendar months from [from] to [to], ignoring the day of month.
int monthsUntil(IsoDate from, IsoDate to) {
  final a = parseIsoDate(from);
  final b = parseIsoDate(to);
  return (b.year - a.year) * 12 + (b.month - a.month);
}

String monthKey(IsoDate date) => date.substring(0, 7);

String shortDate(IsoDate? date) {
  if (date == null || date.isEmpty) return '—';
  final d = parseIsoDate(date);
  return '${d.day} ${_months[d.month - 1]}';
}

String longDate(IsoDate? date) {
  if (date == null || date.isEmpty) return '—';
  final d = parseIsoDate(date);
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String monthYear(IsoDate date) {
  final d = parseIsoDate(date);
  return '${_months[d.month - 1]} ${d.year}';
}

/// 'October' — used in "October so far".
String monthName(IsoDate date) => _monthsLong[parseIsoDate(date).month - 1];

/// 'October 2026' — the History range chip.
String monthNameYear(IsoDate date) => '${monthName(date)} ${parseIsoDate(date).year}';

String weekdayName(IsoDate date) => _weekdays[parseIsoDate(date).weekday - 1];

String relativeDay(IsoDate date, IsoDate today) => switch (daysBetween(date, today)) {
      0 => 'Today',
      -1 => 'Yesterday',
      1 => 'Tomorrow',
      _ => shortDate(date),
    };

String dueText(IsoDate? due, IsoDate today) {
  if (due == null || due.isEmpty) return 'No date';
  final d = daysBetween(due, today);
  if (d < 0) return '${-d} ${d == -1 ? 'day' : 'days'} overdue';
  if (d == 0) return 'Due today';
  if (d == 1) return 'Due tomorrow';
  return 'Due in $d days';
}
