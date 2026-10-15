import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';

import '../app_harness.dart';

void main() {
  group('History', () {
    testWidgets('defaults to this month, grouped by day with each day’s net', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      expect(find.text('Transactions'), findsOneWidget);
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'October 2026')).selected, isTrue);
      expect(find.text('YESTERDAY · 13 OCT 2026'), findsOneWidget);
      expect(find.text('−1,695'), findsOneWidget);
      expect(find.text('NPR 26,240'), findsOneWidget, reason: 'money in this month');
      expect(find.text('NPR 57,841'), findsOneWidget, reason: 'money out counts the whole repayment');
      expect(find.text('SMS · 16:05'), findsOneWidget, reason: 'History shows the time');
      expect(find.text('Salary — Bhadra'), findsNothing, reason: 'September is outside this month');
    });

    testWidgets('type filter narrows the list', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      await tapChip(tester, 'Transfers');
      expect(find.text('Load eSewa wallet'), findsOneWidget);
      expect(find.text('WorldLink internet'), findsNothing);
      expect(find.text('Transfer · Nabil ••4821 → eSewa'), findsOneWidget);
    });

    testWidgets('All time shows September too', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      await tapChip(tester, 'All time');
      await tester.scrollUntilVisible(find.text('Salary — Bhadra'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Salary — Bhadra'), findsOneWidget);
    });

    testWidgets('with nothing to show, offers to show everything', (tester) async {
      await pumpPaisa(tester, location: '/activity', seed: false);
      expect(find.text('No transactions here'), findsOneWidget);
      await tester.tap(find.text('Show all transactions'));
      await tester.pumpAndSettle();
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'All time')).selected, isTrue);
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'All')).selected, isTrue);
    });

    testWidgets('Last 30 days with Loans shows the repayment', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      await tapChip(tester, 'Loans');
      await tapChip(tester, 'Last 30 days');
      expect(find.text('Personal loan B installment'), findsOneWidget);
      expect(find.text('Principal 4,167 · Interest 1,000'), findsOneWidget);
    });

    testWidgets('deleting from History updates the list and the totals, and undo brings it back', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      await tester.tap(find.text('WorldLink internet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InkWell, 'Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('WorldLink internet'), findsNothing);
      expect(find.text('NPR 56,146'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('WorldLink internet'), findsOneWidget);
      await tester.pump(kUndoWindow);
    });

    testWidgets('+ opens Add expense', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      await tester.tap(find.bySemanticsLabel('Add expense'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Row, 'Add expense'), findsWidgets);
      expect(find.text('Save expense'), findsOneWidget);
    });
  });
}
