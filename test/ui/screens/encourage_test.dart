import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/ui/encourage/nudge_card.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

void main() {
  testWidgets('Home shows the savings score and at most two nudges; dismiss hides one', (tester) async {
    await pumpPaisa(tester);
    await scrollPageTo(tester, find.text('Savings score'));
    expect(find.text('Savings score'), findsOneWidget);
    await scrollPageTo(tester, find.text('For you'));
    final cards = find.byType(NudgeCard);
    expect(cards.evaluate().length, inInclusiveRange(1, 2));
    final first = tester.widget<NudgeCard>(cards.first).nudge;
    await tester.tap(find.bySemanticsLabel('Dismiss: ${first.title}'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden for 7 days'), findsOneWidget);
    expect(find.text(first.title), findsNothing);
    await tester.pump(kUndoWindow);
  });

  testWidgets('Settings → Nudges turns a kind off', (tester) async {
    final db = await pumpPaisa(tester, location: '/settings/nudges');
    await tester.tap(find.bySemanticsLabel('EMI reminders'));
    await tester.pumpAndSettle();
    final state = await SettingsRepository(db, AuditLog(db, clock: testClock, newId: counterIds('x'))).nudgeState();
    expect(state.disabled, {NudgeKind.emiDue});
  });

  testWidgets('a nudge link to search fills the search box', (tester) async {
    await pumpPaisa(tester, location: '/search?q=Daraz');
    expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, 'Daraz');
  });

  testWidgets('a nudge link to the payoff planner fills the extra amount', (tester) async {
    await pumpPaisa(tester, location: '/loans/planner?extra=4000');
    expect(find.text('4000'), findsOneWidget);
  });
}
