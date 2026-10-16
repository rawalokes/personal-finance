import 'package:nepali_utils/nepali_utils.dart';

import 'dates.dart';

/// Which calendar months follow: Gregorian (AD) or Bikram Sambat (BS).
/// Transactions always keep AD dates; only month boundaries and labels change.
abstract class MonthCalendar {
  const MonthCalendar();

  /// Month key for [d]. AD keys are 'YYYY-MM' (as stored before 1.6.0); BS
  /// keys are prefixed, 'B2083-06', so the two never collide.
  String key(IsoDate d);

  /// First and last AD day of the month [key].
  IsoDate start(String key);
  IsoDate end(String key) => addDays(start(shift(key, 1)), -1);

  /// The month [months] after (or before, when negative) [key].
  String shift(String key, int months);

  int daysIn(String key) => daysBetween(end(key), start(key)) + 1;

  /// 1-based day of [d] within its month.
  int dayOf(IsoDate d) => daysBetween(d, start(key(d))) + 1;

  /// 'Oct' / 'Kar' — chart axes.
  String monthShort(String key);

  /// 'October' / 'Kartik' — "Kartik so far".
  String monthLong(String key);

  /// 'October 2026' / 'Kartik 2083'.
  String monthYear(String key);

  /// '14 Oct' / '28 Asoj'.
  String shortDate(IsoDate d);

  /// '14 Oct 2026' / '28 Asoj 2083'.
  String longDate(IsoDate d);
}

const _adShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _adLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class AdCalendar extends MonthCalendar {
  const AdCalendar();

  @override
  String key(IsoDate d) => monthKey(d);
  @override
  IsoDate start(String key) => '$key-01';
  @override
  String shift(String key, int months) => monthKey(addMonths('$key-01', months));
  @override
  String monthShort(String key) => _adShort[int.parse(key.substring(5, 7)) - 1];
  @override
  String monthLong(String key) => _adLong[int.parse(key.substring(5, 7)) - 1];
  @override
  String monthYear(String key) => '${monthLong(key)} ${key.substring(0, 4)}';
  @override
  String shortDate(IsoDate d) => '${parseIsoDate(d).day} ${_adShort[parseIsoDate(d).month - 1]}';
  @override
  String longDate(IsoDate d) => '${shortDate(d)} ${parseIsoDate(d).year}';
}

/// Common spellings of the Bikram Sambat months.
const kBsMonths = [
  'Baisakh', 'Jestha', 'Asar', 'Shrawan', 'Bhadra', 'Asoj',
  'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
];
const _bsShort = ['Bai', 'Jes', 'Asa', 'Shr', 'Bha', 'Aso', 'Kar', 'Man', 'Pou', 'Mag', 'Fal', 'Cha'];

class BsCalendar extends MonthCalendar {
  const BsCalendar();

  static NepaliDateTime _bs(IsoDate d) {
    final a = parseIsoDate(d);
    return DateTime(a.year, a.month, a.day).toNepaliDateTime();
  }

  static (int, int) _parts(String key) => (int.parse(key.substring(1, 5)), int.parse(key.substring(6, 8)));
  static String _key(int year, int month) => 'B$year-${month.toString().padLeft(2, '0')}';

  @override
  String key(IsoDate d) {
    final b = _bs(d);
    return _key(b.year, b.month);
  }

  @override
  IsoDate start(String key) {
    final (y, m) = _parts(key);
    final a = NepaliDateTime(y, m, 1).toDateTime();
    return toIsoDate(DateTime.utc(a.year, a.month, a.day));
  }

  @override
  String shift(String key, int months) {
    final (y, m) = _parts(key);
    final zero = m - 1 + months;
    final month = zero % 12;
    return _key(y + (zero - month) ~/ 12, month + 1);
  }

  @override
  String monthShort(String key) => _bsShort[_parts(key).$2 - 1];
  @override
  String monthLong(String key) => kBsMonths[_parts(key).$2 - 1];
  @override
  String monthYear(String key) => '${monthLong(key)} ${_parts(key).$1}';
  @override
  String shortDate(IsoDate d) {
    final b = _bs(d);
    return '${b.day} ${kBsMonths[b.month - 1]}';
  }

  @override
  String longDate(IsoDate d) => '${shortDate(d)} ${_bs(d).year}';
}
