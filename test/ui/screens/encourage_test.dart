import 'package:flutter/material.dart';
import 'package:paisa/data/clock.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/ui/tokens.dart';
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

  testWidgets('a negative net worth is shown in red, not green', (tester) async {
    final db = await pumpPaisa(tester, cleanInstall: true);
    await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'cc', name: 'Card', shortName: 'Card', accountGroup: 'liability', kind: 'credit_card', openingBalance: 0, balance: 1900000));
    await tester.pumpAndSettle();
    final label = tester.widget<Text>(find.text('Net worth'));
    final c = Theme.of(tester.element(find.text('Net worth'))).extension<PaisaColors>()!;
    expect(label.style!.color, c.red);
  });

  testWidgets('a new month on resume finishes last month and suggests new challenges', (tester) async {
    var now = DateTime(2026, 10, 14, 10, 30);
    await pumpPaisa(tester, location: '/plans?seg=challenges', clock: Clock(() => now));
    expect(find.text('Suggested for October'), findsOneWidget);
    now = DateTime(2026, 11, 2, 9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Suggested for November'), findsOneWidget);
  });
}
