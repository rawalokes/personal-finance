import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:paisa/data/report_settings.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/store/reports.dart';

import 'data_providers_test.dart' show keepAlive, seededContainer;

void main() {
  test('the fiscal year starts on 1 Shrawan', () {
    final start = fiscalYearStart('2026-10-14');
    final bs = DateTime.parse(start).toNepaliDateTime();
    expect((bs.year, bs.month, bs.day), (2083, 4, 1));
    final before = DateTime.parse(fiscalYearStart('2026-07-01')).toNepaliDateTime();
    expect((before.year, before.month, before.day), (2082, 4, 1), reason: '1 July is still in Asar 2083 → FY 2082/83');
  });

  test('dashboard is the default until saved; nudges and score load from the sample data', () async {
    final c = await seededContainer();
    keepAlive(c, [dashboardProvider, nudgesProvider, savingsScoreProvider]);
    expect((await c.read(dashboardProvider.future)).widgets.first.type, ReportWidgetType.savingsScore);
    expect(await c.read(nudgesProvider.future), isA<List<Nudge>>());
    final scores = await c.read(savingsScoreProvider.future);
    expect(scores, hasLength(6));
    expect(scores.last.month, '2026-10');
  });

  test('dismissing a nudge hides it', () async {
    final c = await seededContainer();
    keepAlive(c, [nudgesProvider]);
    final before = await c.read(nudgesProvider.future);
    expect(before, isNotEmpty, reason: 'the sample data has loans due and budgets in use');
    await c.read(nudgeControllerProvider).dismiss(before.first.id);
    await pumpEventQueue();
    expect((await c.read(nudgesProvider.future)).map((n) => n.id), isNot(contains(before.first.id)));
  });

  test('roll over suggests once; accepting counts toward the limit of 5', () async {
    final c = await seededContainer();
    keepAlive(c, [challengeStateProvider, reportInputsProvider]);
    final inputs = await c.read(reportInputsProvider.future);
    final ctl = c.read(challengeControllerProvider);
    await ctl.rollOver(inputs);
    await ctl.rollOver(inputs);
    var s = await c.read(settingsRepoProvider).challengeState();
    expect(s.suggestionsIn('2026-10'), isNotEmpty);
    expect(await ctl.accept(s.suggestionsIn('2026-10').first.id), isNull);
    for (var k = 0; k < 4; k++) {
      expect(await ctl.add(Challenge(id: '', template: ChallengeTemplate.noSpendDays, month: '2026-10', target: 5 + k)), isNull);
    }
    expect(await ctl.add(const Challenge(id: '', template: ChallengeTemplate.noSpendDays, month: '2026-10', target: 9)), contains('up to 5'));
    s = await c.read(settingsRepoProvider).challengeState();
    expect(s.acceptedIn('2026-10'), hasLength(5));
  });
}
