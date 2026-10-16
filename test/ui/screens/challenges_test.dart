import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/toast.dart';

import '../app_harness.dart';

void main() {
  testWidgets('suggestions appear once a month; Accept moves one to This month', (tester) async {
    await pumpPaisa(tester, location: '/plans?seg=challenges');
    expect(find.text('Suggested for October'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Accept').first);
    await tester.pumpAndSettle();
    expect(find.text('Challenge accepted'), findsOneWidget);
    expect(find.text('No challenges yet. Accept a suggestion or add your own.'), findsNothing);
    await tester.pump(kUndoWindow);
  });

  testWidgets('add a no-spend-days challenge', (tester) async {
    await pumpPaisa(tester, location: '/plans?seg=challenges');
    await scrollAndTap(tester, find.text('New challenge'));
    await tester.tap(find.text('No-spend days'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Target (days)'), '5');
    await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
    await tester.pumpAndSettle();
    await scrollPageTo(tester, find.text('5 no-spend days'));
    expect(find.text('5 no-spend days'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('badges are listed', (tester) async {
    await pumpPaisa(tester, location: '/plans?seg=challenges');
    await scrollPageTo(tester, find.text('Badges'));
    expect(find.text('First challenge done'), findsOneWidget);
  });
}
