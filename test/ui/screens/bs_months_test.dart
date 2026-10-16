import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/settings_models.dart';

import '../app_harness.dart';

// The test clock is 14 Oct 2026 = 28 Asoj 2083.
const bs = AppPrefs(calendar: CalendarPref.bs);

void main() {
  testWidgets('Home counts this month as Asoj so far', (tester) async {
    await pumpPaisa(tester, prefs: bs);
    await scrollPageTo(tester, find.text('Asoj so far'));
    expect(find.text('Asoj so far'), findsOneWidget);
    expect(find.text('October so far'), findsNothing);
  });

  testWidgets('History groups by the BS month and labels days in BS', (tester) async {
    await pumpPaisa(tester, location: '/activity', prefs: bs);
    expect(find.text('Asoj 2083'), findsWidgets);
    expect(find.textContaining('Asoj 2083'), findsWidgets);
    expect(find.textContaining('Oct 2026'), findsNothing);
  });

  testWidgets('transaction details show the BS date', (tester) async {
    await pumpPaisa(tester, location: '/activity', prefs: bs);
    await tester.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'TransactionTile').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Asoj 2083,'), findsOneWidget);
  });

  testWidgets('challenges are suggested for the BS month', (tester) async {
    await pumpPaisa(tester, location: '/plans?seg=challenges', prefs: bs);
    expect(find.text('Suggested for Asoj'), findsOneWidget);
  });

  testWidgets('budgets name the BS month', (tester) async {
    await pumpPaisa(tester, location: '/plans', prefs: bs);
    expect(find.text('Asoj budget'), findsOneWidget);
  });

  testWidgets('the Home plan is for the BS month', (tester) async {
    await pumpPaisa(tester, prefs: bs);
    expect(find.text('ASOJ PLAN'), findsOneWidget);
  });
}
