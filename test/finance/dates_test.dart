import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/dates.dart';

void main() {
  const today = '2026-10-14';

  test('round-trips ISO dates in UTC', () {
    expect(toIsoDate(parseIsoDate('2026-10-14')), '2026-10-14');
    expect(parseIsoDate('2026-10-14').isUtc, isTrue);
  });

  group('addMonths (Review Focus 4)', () {
    test('moves by whole months', () {
      expect(addMonths('2026-10-13', 1), '2026-11-13');
      expect(addMonths('2026-12-05', 1), '2027-01-05');
      expect(addMonths('2026-11-13', -1), '2026-10-13');
      expect(addMonths('2026-01-15', -1), '2025-12-15');
      expect(addMonths('2026-10-31', 12), '2027-10-31');
    });
    test('clamps to the last day of shorter months', () {
      expect(addMonths('2026-01-31', 1), '2026-02-28');
      expect(addMonths('2028-01-31', 1), '2028-02-29');
      expect(addMonths('2026-03-31', -1), '2026-02-28');
      expect(addMonths('2026-10-31', 1), '2026-11-30');
    });
  });

  test('daysBetween and monthsUntil', () {
    expect(daysBetween('2026-10-14', '2026-10-01'), 13);
    expect(daysBetween('2026-10-01', '2026-10-14'), -13);
    expect(monthsUntil('2026-10-14', '2026-12-20'), 2);
    expect(monthsUntil('2026-10-14', '2027-03-31'), 5);
  });

  test('labels', () {
    expect(monthKey('2026-10-14'), '2026-10');
    expect(shortDate('2026-10-14'), '14 Oct');
    expect(shortDate(null), '—');
    expect(shortDate(''), '—');
    expect(longDate('2027-03-15'), '15 Mar 2027');
    expect(monthYear('2028-03-01'), 'Mar 2028');
    expect(weekdayName('2026-10-14'), 'Wed');
  });

  test('relativeDay', () {
    expect(relativeDay('2026-10-14', today), 'Today');
    expect(relativeDay('2026-10-13', today), 'Yesterday');
    expect(relativeDay('2026-10-15', today), 'Tomorrow');
    expect(relativeDay('2026-10-01', today), '1 Oct');
  });

  test('dueText', () {
    expect(dueText('2026-10-01', today), '13 days overdue');
    expect(dueText('2026-10-13', today), '1 day overdue');
    expect(dueText('2026-10-14', today), 'Due today');
    expect(dueText('2026-10-15', today), 'Due tomorrow');
    expect(dueText('2026-10-18', today), 'Due in 4 days');
    expect(dueText(null, today), 'No date');
  });
}
