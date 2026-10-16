import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

// 14 Oct 2026 = 28 Asoj 2083 (B2083-06, which began 17 Sep 2026).
const today = '2026-10-14';
const bs = BsCalendar();

void main() {
  test('monthly totals follow BS month boundaries', () {
    final txs = [
      tx(TxType.expense, 'a', 100, cat: 'x', date: '2026-09-16'), // 31 Bhadra
      tx(TxType.expense, 'a', 200, cat: 'x', date: '2026-09-17'), // 1 Asoj
      tx(TxType.expense, 'a', 400, cat: 'x', date: '2026-10-14'),
    ];
    expect(monthlyTotals(txs, 'B2083-06', cal: bs).expenses, fromRupees(600));
    expect(monthlyTotals(txs, '2026-09').expenses, fromRupees(300), reason: 'AD unchanged');
  });

  test('report periods start on the 1st of the BS month', () {
    final r = resolvePeriod(ReportPeriod.thisMonth, today, fyStart: '2026-07-17', cal: bs);
    expect(r, const DateRange('2026-09-17', today));
    expect(r.months(bs), ['B2083-06']);
    final last = resolvePeriod(ReportPeriod.lastMonth, today, fyStart: '2026-07-17', cal: bs);
    expect(bs.key(last.start), 'B2083-05');
    expect(addDays(last.end, 1), '2026-09-17');
    final prev = previousRange(r, cal: bs);
    expect(bs.key(prev.start), 'B2083-05');
    expect(bs.dayOf(prev.end), 28, reason: 'same point last month');
  });

  test('cash flow labels and forecast months are BS keys', () {
    final pts = cashFlow(const [], const DateRange('2026-09-17', today), today: today, cal: bs);
    expect(pts.map((p) => p.month), ['B2083-06', 'B2083-07', 'B2083-08', 'B2083-09']);
  });

  test('score and nudges count days in the BS month', () {
    final s = scoreTrend(txs: const [], categories: const [], loans: const [], today: today, cal: bs);
    expect(s.last.month, 'B2083-06');
    final n = buildNudges(
      NudgeInput(
        today: today,
        txs: [tx(TxType.expense, 'a', 9000, cat: 'food', date: '2026-09-20')],
        accounts: const [],
        categories: [ExpenseCategory(id: 'food', name: 'Food', icon: 't', monthlyBudget: fromRupees(10000))],
        loans: const [],
        goals: const [],
      ),
      const MoneyFormat(),
      cal: bs,
    ).single;
    final left = bs.daysIn('B2083-06') - 28;
    expect(n.body, startsWith('$left days left'));
  });

  test('switching to BS drops AD challenges without counting them as missed; the streak carries over', () {
    final s = rollOverChallenges(
      ChallengeState(active: [
        Challenge(id: 'ad', template: ChallengeTemplate.saveAmount, month: '2026-10', target: 100),
      ], history: [
        ChallengeResult(Challenge(id: 'aug', template: ChallengeTemplate.saveAmount, month: '2026-08', target: 1), true),
        ChallengeResult(Challenge(id: 'sep', template: ChallengeTemplate.saveAmount, month: 'B2083-05', target: 1), true),
      ]),
      txs: const [],
      loans: const [],
      categories: const [],
      accounts: const [],
      today: today,
      cal: bs,
    );
    expect(s.active.map((c) => c.id), everyElement(startsWith('sugg-')));
    expect(s.active.first.month, 'B2083-06');
    expect(s.history.map((r) => r.challenge.id), ['aug', 'sep'], reason: 'the AD challenge is not recorded as missed');
    // AD August ended on 31 Aug 2026, which is in Bhadra 2083 — the same BS
    // month as 'sep', so together they make a 1-month streak (Shrawan has none).
    expect(challengeStreak(s.history, 'B2083-06'), 1);
  });
}
