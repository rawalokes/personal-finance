import 'package:nepali_utils/nepali_utils.dart';

import '../data/settings_models.dart';
import '../finance/dates.dart';

/// Common spellings of the Bikram Sambat months.
const _bsMonths = [
  'Baisakh', 'Jestha', 'Asar', 'Shrawan', 'Bhadra', 'Asoj',
  'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra',
];
const _weekdaysLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// Home header date: 'Wed, Asoj 28, 2083 · 14 Oct 2026' (BS) or
/// 'Wednesday, 14 October 2026' (AD). Transactions always keep AD dates.
String homeDateLine(DateTime now, CalendarPref calendar) {
  final ad = toIsoDate(now);
  if (calendar == CalendarPref.ad) return '${_weekdaysLong[now.weekday - 1]}, ${now.day} ${monthNameYear(ad)}';
  final bs = DateTime(now.year, now.month, now.day).toNepaliDateTime();
  return '${weekdayName(ad)}, ${_bsMonths[bs.month - 1]} ${bs.day}, ${bs.year} · ${longDate(ad)}';
}
