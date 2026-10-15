import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

void main() {
  group('Budgets', () {
    testWidgets('month summary, an over-budget category, and what is left', (tester) async {
      await pumpPaisa(tester, location: '/plans');
      expect(find.text('Plans'), findsWidgets);
      expect(find.text('October budget'), findsOneWidget);
      expect(find.text('1 over budget'), findsOneWidget);
      expect(find.text('NPR 23,826'), findsOneWidget);
      await scrollPageTo(tester, find.text('Entertainment'));
      expect(find.text('640 over'), findsOneWidget);
    });

    testWidgets('tapping a category edits its limit', (tester) async {
      final db = await pumpPaisa(tester, location: '/plans');
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.text('Groceries budget'), findsOneWidget);
      expect(find.text('Spent NPR 6,560 so far in October.'), findsOneWidget);
      await tester.enterText(fieldLabelled('Monthly limit (NPR)'), '15000');
      await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Groceries budget set to NPR 15,000'), findsOneWidget);
      final row = await (db.select(db.expenseCategories)..where((c) => c.id.equals('groceries'))).getSingle();
      expect(row.monthlyBudget, fromRupees(15000));
      await tester.pump(kUndoWindow);
    });

    testWidgets('a clean install invites setting budgets', (tester) async {
      await pumpPaisa(tester, location: '/plans', cleanInstall: true);
      expect(find.text('No budgets yet'), findsOneWidget);
    });
  });

  group('Loans', () {
    testWidgets('summary and one card per loan; a card opens the loan', (tester) async {
      await pumpPaisa(tester, location: '/plans?seg=loans');
      expect(find.text('You still owe'), findsOneWidget);
      expect(find.text('NPR 4,44,253'), findsOneWidget);
      expect(find.text('Plan how to pay it off'), findsOneWidget);
      await scrollPageTo(tester, find.text('Scooter loan'));
      await scrollPageTo(tester, find.text('Borrowed from Kiran'));
      await tester.tap(find.text('Borrowed from Kiran'));
      await tester.pumpAndSettle();
      expect(find.text('Outstanding principal'), findsOneWidget);
    });

    testWidgets('no loans: an empty state that adds one', (tester) async {
      await pumpPaisa(tester, location: '/plans?seg=loans', cleanInstall: true);
      expect(find.text('No loans'), findsOneWidget);
      await tester.tap(find.text('Add a loan'));
      await tester.pumpAndSettle();
      expect(find.text('Loan name'), findsOneWidget);
    });
  });

  group('Goals', () {
    testWidgets('emergency fund months from reserved savings and essential budgets', (tester) async {
      await pumpPaisa(tester, location: '/plans?seg=goals');
      expect(find.text('Emergency fund'), findsOneWidget);
      expect(find.text('6.1'), findsOneWidget);
      expect(find.text('Target met'), findsOneWidget);
    });

    testWidgets('a double tap on Create goal makes one goal', (tester) async {
      final db = await pumpPaisa(tester, location: '/plans?seg=goals');
      await tester.tap(find.text('New goal'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('Goal name'), 'Laptop');
      await tester.enterText(fieldLabelled('Target amount (NPR)'), '150000');
      final create = find.widgetWithText(PaisaButton, 'Create goal');
      await tester.tap(create);
      await tester.tap(create, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect((await db.select(db.goals).get()).where((g) => g.name == 'Laptop'), hasLength(1));
      await tester.pump(kUndoWindow);
    });

    testWidgets('a new goal shows progress; adding money is a transfer, never spending', (tester) async {
      final db = await pumpPaisa(tester, location: '/plans?seg=goals');
      await tester.tap(find.text('New goal'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('Goal name'), 'Mustang trip');
      await tester.enterText(fieldLabelled('Target amount (NPR)'), '80000');
      await tester.enterText(fieldLabelled('Already saved (NPR)'), '32000');
      await tester.tap(find.widgetWithText(PaisaButton, 'Create goal'));
      await tester.pumpAndSettle();
      expect(find.text('Mustang trip'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      await tester.pump(kUndoWindow); // let the "created" toast clear

      await tester.tap(find.widgetWithText(PaisaButton, 'Add money'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('Amount (NPR)'), '5000');
      await tester.ensureVisible(find.widgetWithText(PaisaChip, 'NIC Asia ••2290'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PaisaChip, 'NIC Asia ••2290'));
      await tester.pump();
      await tester.tap(find.widgetWithText(PaisaButton, 'Add money').last);
      await tester.pumpAndSettle();
      expect(find.text('NPR 5,000 added to Mustang trip · not an expense'), findsOneWidget);
      expect(find.text('46%'), findsOneWidget);
      expect(await balanceOf(db, 'nic'), fromRupees(385000 + 5000));
      final tx = (await db.select(db.transactions).get()).map(txnFromRow).firstWhere((t) => t.title == 'Saved to Mustang trip');
      expect(tx.type, TxType.transfer);
      await tester.pump(kUndoWindow);
    });
  });

  testWidgets('Home "Loans" opens the Loans segment', (tester) async {
    await pumpPaisa(tester);
    await tester.tap(find.bySemanticsLabel('Loans'));
    await tester.pumpAndSettle();
    expect(find.text('You still owe'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
