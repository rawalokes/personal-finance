import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/top_bar.dart';
import 'package:paisa/ui/shell/nav_bar.dart';

import 'app_harness.dart';
import 'helpers.dart';

Finder navLabel(String text) => find.descendant(of: find.byType(PaisaNavBar), matching: find.text(text));

void main() {
  testWidgets('shows five tabs and switches between them', (tester) async {
    await pumpPaisa(tester);
    for (final label in ['Home', 'Activity', 'Plans', 'Reports', 'More']) {
      expect(navLabel(label), findsOneWidget);
    }
    expect(find.text('FREE TO SPEND'), findsOneWidget);

    await tester.tap(navLabel('Activity'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PaisaTopBar, 'Transactions'), findsOneWidget);

    await tester.tap(navLabel('More'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PaisaTopBar, 'Settings'), findsOneWidget);
  });

  testWidgets('the bottom nav is a bar along the bottom, not a full-screen layer', (tester) async {
    await pumpPaisa(tester);
    final nav = tester.getRect(find.byType(PaisaNavBar));
    expect(nav.height, lessThan(100));
    expect(nav.bottom, 844);
  });

  testWidgets('dark Night theme is the default', (tester) async {
    await pumpPaisa(tester);
    expect(Theme.of(tester.element(find.byType(PaisaNavBar))).brightness, Brightness.dark);
  });

  testWidgets('switching theme mode to light applies the light palette', (tester) async {
    await pumpPaisa(tester);
    ProviderScope.containerOf(tester.element(find.byType(PaisaNavBar)))
        .read(themeModeProvider.notifier)
        .set(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(PaisaNavBar))).brightness, Brightness.light);
  });

  testWidgets('Activity shows the pending-review badge', (tester) async {
    await pumpPaisa(tester, overrides: [inboxPendingCountProvider.overrideWith((ref) => 3)]);
    expect(navLabel('3'), findsOneWidget);
    expect(find.bySemanticsLabel('Activity, 3 to review'), findsOneWidget);
  });

  testWidgets('detail top bar shows Back and calls onBack', (tester) async {
    var back = 0;
    await tester.pumpWidget(wrap(PaisaTopBar(title: 'Review transaction', onBack: () => back++)));
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(back, 1);
  });

  testWidgets('Accounts moved off the tab bar: Home → See all opens it, Back returns', (tester) async {
    await pumpPaisa(tester);
    expect(navLabel('Accounts'), findsNothing);
    await tester.tap(find.text('See all').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PaisaTopBar, 'Accounts'), findsOneWidget);
    expect(find.byType(PaisaNavBar), findsNothing, reason: 'a detail page, outside the tab shell');
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('FREE TO SPEND'), findsOneWidget);
  });

  testWidgets('the Reports tab opens', (tester) async {
    await pumpPaisa(tester);
    await tester.tap(navLabel('Reports'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PaisaTopBar, 'Reports'), findsOneWidget);
  });
}
