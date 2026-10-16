import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';

import 'fixtures.dart';

const today = '2026-10-14';
Challenge ch(ChallengeTemplate t, num target, {String month = '2026-10', String? cat, String? loan, bool accepted = true, String id = 'c1'}) =>
    Challenge(id: id, template: t, month: month, target: t == ChallengeTemplate.noSpendDays || t == ChallengeTemplate.categoryCut ? target.toInt() : fromRupees(target),
        categoryId: cat, loanId: loan, accepted: accepted);

final loanL1 = Loan(id: 'L1', loanTypeId: 'p', name: 'Scooter', lender: 'B', principal: fromRupees(100000), outstanding: fromRupees(50000),
    ratePct: 12, method: InterestMethod.reducing, installment: fromRupees(5000), frequency: LoanFrequency.monthly);

void main() {
  final txs = [
    tx(TxType.income, 'a', 50000, date: '2026-10-01'),
    tx(TxType.expense, 'a', 4000, cat: 'food', date: '2026-10-01'),
    tx(TxType.expense, 'a', 1000, cat: 'food', date: '2026-10-05'),
    tx(TxType.expense, 'a', 6000, cat: 'food', date: '2026-09-05'),
    tx(TxType.loanRepayment, 'a', 7000, loanId: 'L1', principal: 6500, interest: 500, date: '2026-10-13'),
  ];

  test('progress for each template', () {
    final save = challengeProgress(ch(ChallengeTemplate.saveAmount, 40000), txs, [loanL1], today);
    expect((save.current, save.met), (fromRupees(44500), true));
    final cap = challengeProgress(ch(ChallengeTemplate.categoryCap, 4500, cat: 'food'), txs, [loanL1], today);
    expect((cap.current, cap.met), (fromRupees(5000), false));
    final days = challengeProgress(ch(ChallengeTemplate.noSpendDays, 10), txs, [loanL1], today);
    expect((days.current, days.met), (12, true), reason: '14 days so far, spending on 2 of them');
    final extra = challengeProgress(ch(ChallengeTemplate.loanExtra, 2000, loan: 'L1'), txs, [loanL1], today);
    expect((extra.current, extra.met), (fromRupees(2000), true));
    final cut = challengeProgress(ch(ChallengeTemplate.categoryCut, 10, cat: 'food'), txs, [loanL1], today);
    expect((cut.current, cut.met), (16, true), reason: '6000 → 5000 is a 16% cut');
  });

  test('suggestions: save 110% of last month (min NPR 1,000) and the fastest-growing category', () {
    final hist = [
      tx(TxType.income, 'a', 30000, date: '2026-09-01'),
      tx(TxType.expense, 'a', 20000, cat: 'shopping', date: '2026-09-02'),
      tx(TxType.expense, 'a', 5000, cat: 'shopping', date: '2026-08-02'),
      tx(TxType.expense, 'a', 5000, cat: 'shopping', date: '2026-07-02'),
    ];
    final s = suggestChallenges(hist, [const ExpenseCategory(id: 'shopping', name: 'Shopping', icon: 'tag')], today);
    expect(s.map((c) => (c.template, c.target)), [
      (ChallengeTemplate.saveAmount, fromRupees(11000)),
      (ChallengeTemplate.categoryCut, 10),
    ]);
    expect(s.every((c) => !c.accepted && c.source == ChallengeSource.suggested && c.month == '2026-10'), isTrue);
    expect(suggestChallenges(const [], const [], today).single.target, fromRupees(1000));
  });

  test('roll over: finish last month, drop unaccepted and untracked, suggest once, streak and badges', () {
    final sept = [
      tx(TxType.income, 'a', 10000, date: '2026-09-01'),
      tx(TxType.expense, 'a', 2000, cat: 'food', date: '2026-09-02'),
    ];
    var s = ChallengeState(active: [
      ch(ChallengeTemplate.saveAmount, 5000, month: '2026-09', id: 'done'),
      ch(ChallengeTemplate.saveAmount, 99999, month: '2026-09', id: 'skipped', accepted: false),
      ch(ChallengeTemplate.categoryCap, 100, month: '2026-09', cat: 'deleted', id: 'gone'),
    ], history: [
      ChallengeResult(ch(ChallengeTemplate.saveAmount, 1, month: '2026-08', id: 'aug'), true),
      ChallengeResult(ch(ChallengeTemplate.saveAmount, 1, month: '2026-07', id: 'jul'), true),
    ]);
    s = rollOverChallenges(s, txs: sept, loans: const [], categories: const [ExpenseCategory(id: 'food', name: 'Food', icon: 't')], accounts: const [], today: today);
    expect(s.history.map((r) => (r.challenge.id, r.done)), [('aug', true), ('jul', true), ('done', true)]);
    expect(s.active.map((c) => c.id), everyElement(startsWith('sugg-')));
    expect(s.lastSuggestedMonth, '2026-10');
    expect(challengeStreak(s.history, '2026-10'), 3);
    expect(s.badges, containsAll([BadgeId.firstChallenge, BadgeId.streak3]));

    final again = rollOverChallenges(s.copyWith(active: const []), txs: sept, loans: const [], categories: const [], accounts: const [], today: today);
    expect(again.active, isEmpty, reason: 'suggestions are made once a month');
  });

  test('a challenge completed this month counts for praise; caps and cuts do not', () {
    final s = ChallengeState(active: [ch(ChallengeTemplate.saveAmount, 40000), ch(ChallengeTemplate.categoryCap, 9000, cat: 'food', id: 'c2')]);
    expect(challengeDoneThisMonth(s, txs, [loanL1], today), isTrue);
    final capOnly = ChallengeState(active: [ch(ChallengeTemplate.categoryCap, 9000, cat: 'food')]);
    expect(challengeDoneThisMonth(capOnly, txs, [loanL1], today), isFalse);
  });

  test('wire names round-trip', () {
    for (final t in ChallengeTemplate.values) {
      expect(ChallengeTemplate.fromWire(t.wire), t);
    }
    for (final b in BadgeId.values) {
      expect(BadgeId.fromWire(b.wire), b);
    }
  });
}
