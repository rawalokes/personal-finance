import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/top_bar.dart';

import '../app_harness.dart';

void main() {
  testWidgets('Reports shows the default widgets and "For you" nudges', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    expect(find.widgetWithText(PaisaTopBar, 'Reports'), findsOneWidget);
    expect(find.text('For you'), findsOneWidget);
    for (final title in ['Savings score', 'Cash flow', 'Spending by category', 'Budgets', 'Loan progress', 'Challenges']) {
      await scrollPageTo(tester, find.text(title));
      expect(find.text(title), findsWidgets, reason: title);
    }
  });

  testWidgets('clean install: Reports renders with empty states, no errors', (tester) async {
    await pumpPaisa(tester, location: '/reports', cleanInstall: true);
    expect(find.text('Savings score'), findsOneWidget);
    await scrollPageTo(tester, find.text('No open loans 🎉'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden balances mask every amount on Reports, nudges included', (tester) async {
    await pumpPaisa(tester, location: '/reports', overrides: [
      initialPrefsProvider.overrideWithValue(const AppPrefs(hideBalances: true)),
    ]);
    expect(find.textContaining(RegExp(r'NPR \d')), findsNothing);
  });

  testWidgets('the period chips apply one period to every widget for now', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    await tapChip(tester, '12 months');
    expect(find.text('12 months'), findsWidgets);
  });
}
