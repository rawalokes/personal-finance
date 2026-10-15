import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/app.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/top_bar.dart';
import 'package:paisa/ui/shell/nav_bar.dart';

import 'helpers.dart';

Finder navLabel(String text) => find.descendant(of: find.byType(PaisaNavBar), matching: find.text(text));

void main() {
  testWidgets('shows five tabs and switches between them', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaisaApp()));
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Activity', 'Accounts', 'Plans', 'More']) {
      expect(navLabel(label), findsOneWidget);
    }
    expect(find.widgetWithText(PaisaTopBar, 'Home'), findsOneWidget);

    await tester.tap(navLabel('Activity'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PaisaTopBar, 'Transactions'), findsOneWidget);

    await tester.tap(navLabel('More'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PaisaTopBar, 'Settings'), findsOneWidget);
  });

  testWidgets('dark Night theme is the default', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaisaApp()));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(PaisaNavBar))).brightness, Brightness.dark);
  });

  testWidgets('switching theme mode to light applies the light palette', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const PaisaApp()));
    container.read(themeModeProvider.notifier).set(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(PaisaNavBar))).brightness, Brightness.light);
  });

  testWidgets('Activity shows the pending-review badge', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(ProviderScope(
      overrides: [inboxPendingCountProvider.overrideWith((ref) => 3)],
      child: const PaisaApp(),
    ));
    await tester.pumpAndSettle();
    expect(navLabel('3'), findsOneWidget);
    expect(find.bySemanticsLabel('Activity, 3 to review'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('detail top bar shows Back and calls onBack', (tester) async {
    var back = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(PaisaTopBar(title: 'Review transaction', onBack: () => back++)));
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(back, 1);
    handle.dispose();
  });
}
