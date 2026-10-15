import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/ui/date_line.dart';

void main() {
  test('Bikram Sambat date line matches the mockup, with the AD date beside it', () {
    expect(homeDateLine(DateTime(2026, 10, 14), CalendarPref.bs), 'Wed, Asoj 28, 2083 · 14 Oct 2026');
  });

  test('Gregorian date line', () {
    expect(homeDateLine(DateTime(2026, 10, 14), CalendarPref.ad), 'Wednesday, 14 October 2026');
  });

  test('BS new year (Baisakh 1, 2083 = 14 Apr 2026)', () {
    expect(homeDateLine(DateTime(2026, 4, 14), CalendarPref.bs), startsWith('Tue, Baisakh 1, 2083'));
  });
}
