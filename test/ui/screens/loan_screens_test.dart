import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

void main() {
  group('Loan detail', () {
    testWidgets('shows outstanding, terms, the next split and the schedule', (tester) async {
      await pumpPaisa(tester, location: '/loans/L1');
      expect(find.text('Scooter loan'), findsOneWidget);
      expect(find.text('NPR 2,28,640'), findsOneWidget);
      expect(find.text('11.25% · reducing'), findsOneWidget);
      expect(find.text('Next installment split'), findsOneWidget);
      expect(find.text('NPR 9,357'), findsOneWidget);
      expect(find.text('NPR 2,144'), findsOneWidget);
      await scrollPageTo(tester, find.text('13 Oct'));
      expect(find.text('Repayment schedule'), findsOneWidget);
    });

    testWidgets('a loan with a too-small installment warns it is never repaid', (tester) async {
      final db = await pumpPaisa(tester, location: '/loans/L2');
      await (db.update(db.loans)..where((l) => l.id.equals('L2'))).write(const LoansCompanion(installment: Value(100)));
      await tester.pumpAndSettle();
      expect(find.textContaining('would never be repaid'), findsOneWidget);
    });

    testWidgets('acceptance 4 (UI): recording the scooter EMI splits it and moves the due date', (tester) async {
      final db = await pumpPaisa(tester, location: '/loans/L1');
      await tester.tap(find.text('Record repayment'));
      await tester.pumpAndSettle();
      expect(find.text('Split: NPR 9,357 principal · NPR 2,144 interest. Only interest counts as an expense.'), findsOneWidget);
      await tester.tap(find.widgetWithText(PaisaButton, 'Record payment'));
      await tester.pumpAndSettle();
      expect(find.text('Repayment recorded · principal and interest split'), findsOneWidget);
      final row = await (db.select(db.loans)..where((l) => l.id.equals('L1'))).getSingle();
      expect(row.outstanding, fromRupees(228640 - 9357));
      expect(row.nextDueDate, '2026-11-13');
      expect(await balanceOf(db, 'gibl'), fromRupees(24600 - 11501));
      await tester.pump(kUndoWindow);
    });
  });

  group('Loan form', () {
    testWidgets('validates required fields and outstanding ≤ principal', (tester) async {
      final db = await pumpPaisa(tester, location: '/loans/new');
      await tester.enterText(fieldLabelled('Original principal'), '100000');
      await tester.enterText(fieldLabelled('Outstanding now'), '200000');
      await tester.tap(find.widgetWithText(PaisaButton, 'Save loan'));
      await tester.pumpAndSettle();
      expect(find.text('Give this loan a name'), findsOneWidget);
      expect(find.text('Who lent the money?'), findsOneWidget);
      expect(find.text('Can’t exceed the original principal'), findsOneWidget);
      expect(find.text('Enter the installment'), findsOneWidget);
      expect(await db.select(db.loans).get(), hasLength(4));
      await tester.pump(kUndoWindow);
    });

    testWidgets('a new loan with no rate is saved as "Rate not entered" and opens its page', (tester) async {
      final db = await pumpPaisa(tester, location: '/loans/new?type=education');
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'Education Loan')).selected, isTrue);
      await tester.enterText(fieldLabelled('Loan name'), 'Study loan');
      await tester.enterText(fieldLabelled('Lender'), 'NMB Bank');
      await tester.enterText(fieldLabelled('Original principal'), '300000');
      await tester.enterText(fieldLabelled('Outstanding now'), '300000');
      await tester.enterText(fieldLabelled('Installment'), '9000');
      await tester.pump();
      expect(find.textContaining('interest not entered — estimate excludes interest'), findsOneWidget);
      await tester.tap(find.widgetWithText(PaisaButton, 'Save loan'));
      await tester.pumpAndSettle();
      expect(find.text('Loan added under Education Loan'), findsOneWidget);
      expect(find.text('Rate not entered'), findsOneWidget);
      final saved = (await db.select(db.loans).get()).map(loanFromRow).firstWhere((l) => l.name == 'Study loan');
      expect(saved.ratePct, isNull);
      await tester.pump(kUndoWindow);
    });

    testWidgets('editing changes the installment; undo restores it', (tester) async {
      final db = await pumpPaisa(tester, location: '/loans/L2');
      await tester.tap(find.bySemanticsLabel('Edit loan'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('Installment'), '8000');
      await tester.tap(find.widgetWithText(PaisaButton, 'Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Loan updated'), findsOneWidget);
      expect((await (db.select(db.loans)..where((l) => l.id.equals('L2'))).getSingle()).installment, fromRupees(8000));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await (db.select(db.loans)..where((l) => l.id.equals('L2'))).getSingle()).installment, fromRupees(6790));
      await tester.pump(kUndoWindow);
    });
  });

  testWidgets('loan types: add a new type and disable one', (tester) async {
    final db = await pumpPaisa(tester, location: '/loans/types');
    await tester.tap(find.text('New type'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Name'), 'Gold Loan');
    await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Gold Loan'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Disable Home Loan'));
    await tester.pumpAndSettle();
    final home = await (db.select(db.loanTypes)..where((t) => t.id.equals('home'))).getSingle();
    expect(home.active, isFalse);
    await tester.pump(kUndoWindow);
  });

  group('Payoff planner', () {
    testWidgets('acceptance 10 (UI): +5,000 avalanche finishes sooner and saves interest', (tester) async {
      await pumpPaisa(tester, location: '/loans/planner');
      expect(find.text('You still owe'), findsOneWidget);
      await tester.tap(find.text('+ 5K'));
      await tester.pumpAndSettle();
      expect(find.textContaining('sooner · saves about NPR'), findsOneWidget);
      await scrollPageTo(tester, find.text('What to pay next month'));
      expect(find.text('Payoff order'), findsOneWidget);
    });

    testWidgets('saving the plan stores it and adds a monthly reminder', (tester) async {
      final db = await pumpPaisa(tester, location: '/loans/planner');
      await tester.tap(find.text('+ 5K'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.text('Save plan & remind me monthly'));
      expect(find.textContaining('Plan saved · debt-free by'), findsOneWidget);
      final rule = await (db.select(db.recurringRules)..where((r) => r.id.equals('payoff-extra'))).getSingle();
      expect(rule.amount, fromRupees(5000));
      expect(rule.type, 'loan_extra');
      expect(rule.nextDate, '2026-11-01');
      await tester.pump(kUndoWindow);
    });

    testWidgets('reopening the planner restores the saved plan without errors', (tester) async {
      await pumpPaisa(tester, location: '/loans/planner');
      await tester.tap(find.text('+ 5K'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.text('Save plan & remind me monthly'));
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.pump(kUndoWindow);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.push('/loans/planner');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, '+ 5K')).selected, isTrue);
    });

    testWidgets('with no loans there is nothing to plan', (tester) async {
      await pumpPaisa(tester, location: '/loans/planner', cleanInstall: true);
      expect(find.text('Nothing to pay off'), findsOneWidget);
    });
  });
}
