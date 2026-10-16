import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/report_settings.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/finance/finance.dart';

import 'data_fixtures.dart';
import 'test_db.dart';

void main() {
  test('a widget config round-trips every field', () {
    final w = ReportWidgetConfig.create('w1', ReportWidgetType.incomeBySource).copyWith(
      period: ReportPeriod.thisFy, accountIds: ['a'], categoryIds: ['c'], loanIds: ['l'],
      groupBy: IncomeGrouping.party, chart: ReportChart.bar, size: WidgetSize.half, compare: true,
    );
    final back = DashboardConfig.fromJson(jsonDecode(jsonEncode(DashboardConfig([w]).toJson())) as Map<String, Object?>).widgets.single;
    expect(back.toJson(), w.toJson());
  });

  test('unknown widget types are skipped; a chart the type cannot draw falls back to its default', () {
    final d = DashboardConfig.fromJson({
      'version': 1,
      'widgets': [
        {'id': 'x', 'type': 'crystal_ball'},
        {'id': 'n', 'type': 'net_worth', 'chart': 'donut'},
      ],
    });
    expect(d.widgets.single.chart, ReportChart.line);
  });

  test('the default layout and defaults per type', () {
    expect(defaultDashboard().widgets.map((w) => w.type), [
      ReportWidgetType.savingsScore, ReportWidgetType.cashFlow, ReportWidgetType.spendingByCategory,
      ReportWidgetType.budgetPerformance, ReportWidgetType.loanProgress, ReportWidgetType.challenges,
    ]);
    expect(defaultDashboard().widgets[1].period, ReportPeriod.last6m);
    expect(defaultDashboard().widgets[2].size, WidgetSize.half);
  });

  test('normalising drops deleted accounts, categories and loans', () {
    final d = DashboardConfig([
      ReportWidgetConfig.create('w', ReportWidgetType.spendingByCategory).copyWith(accountIds: ['a', 'gone'], categoryIds: ['old']),
    ]);
    final n = normaliseDashboard(d, accountIds: {'a'}, categoryIds: {'food'}, loanIds: {});
    expect(n.widgets.single.accountIds, ['a']);
    expect(n.widgets.single.categoryIds, isEmpty);
  });

  test('a dismissal lasts 7 days including today and expired ones are pruned', () {
    var s = const NudgeState(dismissed: {'old': '2026-10-01'});
    s = s.dismiss('n1', '2026-10-14');
    expect(s.dismissed, {'n1': '2026-10-20'});
    s = s.withKind(NudgeKind.praise, enabled: false);
    final back = NudgeState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>);
    expect(back.disabled, {NudgeKind.praise});
    expect(back.dismissed, {'n1': '2026-10-20'});
  });

  test('challenge state round-trips', () {
    const c = Challenge(id: 'c', template: ChallengeTemplate.categoryCap, month: '2026-10', target: 500000, categoryId: 'food', accepted: false, source: ChallengeSource.suggested);
    const s = ChallengeState(active: [c], history: [ChallengeResult(c, true)], badges: {BadgeId.streak3}, lastSuggestedMonth: '2026-10');
    final back = challengeStateFromJson(jsonDecode(jsonEncode(challengeStateToJson(s))) as Map<String, Object?>);
    expect(jsonEncode(challengeStateToJson(back)), jsonEncode(challengeStateToJson(s)));
  });

  group('settings repository', () {
    late AppDatabase db;
    late SettingsRepository repo;
    setUp(() {
      db = openTestDb();
      repo = SettingsRepository(db, AuditLog(db, clock: testClock, newId: counterIds('audit')));
    });
    tearDown(() => db.close());

    test('missing documents mean defaults', () async {
      expect(await repo.dashboard(), isNull);
      expect((await repo.nudgeState()).dismissed, isEmpty);
      expect((await repo.challengeState()).active, isEmpty);
    });

    test('save and load', () async {
      await repo.saveDashboard(defaultDashboard());
      expect((await repo.dashboard())!.widgets, hasLength(6));
      await repo.saveChallengeState(const ChallengeState(lastSuggestedMonth: '2026-10'), summary: 'Started challenge');
      expect((await repo.challengeState()).lastSuggestedMonth, '2026-10');
      expect((await db.select(db.auditEntries).get()).single.summary, 'Started challenge');
    });

    test('an unreadable document is reset to defaults and the old value is kept in the audit log', () async {
      await db.into(db.settings).insert(SettingsCompanion.insert(key: SettingKey.reportsDashboard, value: '{"widgets": 5}'));
      expect(await repo.dashboard(), isNull);
      await pumpEventQueue();
      expect(await (db.select(db.settings)..where((s) => s.key.equals(SettingKey.reportsDashboard))).getSingleOrNull(), isNull);
      final audit = (await db.select(db.auditEntries).get()).single;
      expect(audit.summary, contains('Reset unreadable reports.dashboard'));
      expect(audit.summary, contains('"widgets":5'));
    });
  });

  test('wish list items round-trip; old saved items read as 24-hour waits with normal priority', () {
    const w = WaitList(items: [
      WaitItem(id: 'a', title: 'Perfume', amount: 650000, addedAt: '2026-10-14T10:00:00', wish: true, priority: 1),
      WaitItem(id: 'b', title: 'Phone', amount: 9000000, addedAt: '2026-10-14T10:00:00'),
    ], savedByWaiting: 5);
    final back = waitListFromJson(jsonDecode(jsonEncode(waitListToJson(w))) as Map<String, Object?>);
    expect([for (final i in back.items) (i.id, i.wish, i.priority)], [('a', true, 1), ('b', false, 2)]);
    final old = waitListFromJson({
      'items': [
        {'id': 'o', 'title': 'Old', 'amount': 1, 'addedAt': '2026-10-01T00:00:00'},
      ],
    });
    expect((old.items.single.wish, old.items.single.priority), (false, 2));
  });
}
