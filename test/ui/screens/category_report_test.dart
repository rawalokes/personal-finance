import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/ui/components/surfaces.dart';
import 'package:paisa/ui/reports/report_charts.dart';
import 'package:paisa/ui/txn/transaction_tile.dart';

import '../app_harness.dart';

void main() {
  testWidgets('Reports opens with an In / Spent / Saved / Rate summary', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    for (final label in ['In', 'Spent', 'Saved', 'Rate']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('tapping a category in Spending by category opens its own report', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    await scrollPageTo(tester, find.text('See all categories'));
    final row = find.descendant(of: find.byType(SliceList), matching: find.byType(InkWell)).first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Last 6 months'), findsOneWidget);
    expect(find.textContaining(RegExp('vs last period|New this period')), findsWidgets);
    await scrollPageTo(tester, find.text('Transactions'));
    expect(find.byType(TransactionTile), findsWidgets);
  });

  testWidgets('See all categories lists every category; each opens its report', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    await scrollAndTap(tester, find.text('See all categories'));
    expect(find.text('Spending by category'), findsWidgets);
    expect(find.textContaining('% of spending'), findsWidgets);
    await scrollAndTap(tester, find.ancestor(of: find.textContaining('% of spending'), matching: find.byType(PaisaCard)).first);
    expect(find.text('Last 6 months'), findsOneWidget);
  });

  testWidgets('a category report can switch periods', (tester) async {
    await pumpPaisa(tester, location: '/reports/category/groceries');
    expect(find.text('Spent · This month'), findsOneWidget);
    await tapChip(tester, '3 months');
    expect(find.text('Spent · 3 months'), findsOneWidget);
  });
}
