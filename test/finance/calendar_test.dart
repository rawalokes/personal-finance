import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

void main() {
  const bs = BsCalendar();
  const ad = AdCalendar();

  test('AD months are the plain YYYY-MM keys used before', () {
    expect(ad.key('2026-10-14'), '2026-10');
    expect((ad.start('2026-10'), ad.end('2026-10')), ('2026-10-01', '2026-10-31'));
    expect(ad.shift('2026-01', -1), '2025-12');
    expect(ad.daysIn('2026-02'), 28);
    expect(ad.dayOf('2026-10-14'), 14);
    expect((ad.monthShort('2026-10'), ad.monthYear('2026-10')), ('Oct', 'October 2026'));
    expect((ad.shortDate('2026-10-14'), ad.longDate('2026-10-14')), ('14 Oct', '14 Oct 2026'));
  });

  test('14 Oct 2026 is 28 Asoj 2083', () {
    expect(bs.key('2026-10-14'), 'B2083-06');
    expect(bs.dayOf('2026-10-14'), 28);
    expect(bs.start('B2083-06'), '2026-09-17');
    expect(bs.monthLong('B2083-06'), 'Asoj');
    expect(bs.monthYear('B2083-06'), 'Asoj 2083');
    expect(bs.shortDate('2026-10-14'), '28 Asoj');
    expect(bs.longDate('2026-10-14'), '28 Asoj 2083');
  });

  test('BS months tile the AD calendar with no gaps, 29–32 days each', () {
    var k = 'B2083-01';
    for (var i = 0; i < 24; i++) {
      final next = bs.shift(k, 1);
      expect(addDays(bs.end(k), 1), bs.start(next), reason: k);
      expect(bs.daysIn(k), inInclusiveRange(29, 32), reason: k);
      expect(bs.key(bs.start(k)), k);
      expect(bs.key(bs.end(k)), k);
      k = next;
    }
  });

  test('Chaitra rolls into Baisakh of the next year, and back', () {
    expect(bs.shift('B2083-12', 1), 'B2084-01');
    expect(bs.shift('B2084-01', -1), 'B2083-12');
    expect(bs.shift('B2083-06', -18), 'B2081-12');
  });

  test('keys sort in time order within one calendar', () {
    expect('B2083-06'.compareTo('B2083-07') < 0, isTrue);
    expect('B2083-12'.compareTo('B2084-01') < 0, isTrue);
  });
}
