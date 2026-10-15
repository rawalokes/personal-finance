import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/toast.dart';

import '../app_harness.dart';

void main() {
  testWidgets('shows net worth, account groups with totals, and the loans link', (tester) async {
    await pumpPaisa(tester, location: '/accounts');
    expect(find.text('Accounts'), findsWidgets);
    expect(find.text('Net worth'), findsOneWidget);
    expect(find.text('NPR 10,87,327'), findsOneWidget);
    expect(find.text('Available · liquid'), findsOneWidget);
    expect(find.text('NPR 1,84,020'), findsOneWidget);
    expect(find.text('Nabil Bank — Salary'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('View loans & schedules'), 200);
    expect(find.text('− NPR 18,640'), findsWidgets);
    expect(find.text('Tracked in Plans · 4 active'), findsOneWidget);
  });

  testWidgets('acceptance 12 setup: add a Khalti wallet from the + button', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts');
    await tester.tap(find.bySemanticsLabel('Add account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khalti').last);
    await tester.pump();
    expect(find.text('Khalti — personal'), findsOneWidget);
    await tester.enterText(fieldLabelled('Current balance (NPR)'), '3,500');
    await tester.tap(find.widgetWithText(PaisaButton, 'Add account'));
    await tester.pumpAndSettle();

    expect(find.text('Khalti — personal added · balance NPR 3,500'), findsOneWidget);
    final row = (await db.select(db.accounts).get())
        .map(accountFromRow)
        .firstWhere((a) => a.name == 'Khalti — personal');
    expect(row.balance, fromRupees(3500));
    expect(row.smsSender, 'Khalti');
    expect(row.autoUpdateFromSms, isTrue);
    await tester.pump(kUndoWindow);
  });

  testWidgets('add account validates name and balance and saves nothing', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts');
    await tester.tap(find.bySemanticsLabel('Add account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PaisaButton, 'Add account'));
    await tester.pump();
    expect(find.text('Enter an account name'), findsOneWidget);
    expect(find.text('Enter the opening balance'), findsOneWidget);
    expect(await db.select(db.accounts).get(), hasLength(10));
  });

  testWidgets('choosing Credit card asks for the amount owed', (tester) async {
    await pumpPaisa(tester, location: '/accounts');
    await tester.tap(find.bySemanticsLabel('Add account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Credit card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Credit card'));
    await tester.pump();
    expect(find.text('Amount owed now (NPR)'), findsOneWidget);
  });

  testWidgets('Undo on the toast removes the new account', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts');
    await tester.tap(find.bySemanticsLabel('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Account name'), 'Laxmi Sunrise — savings');
    await tester.enterText(fieldLabelled('Current balance (NPR)'), '1000');
    await tester.tap(find.widgetWithText(PaisaButton, 'Add account'));
    await tester.pumpAndSettle();
    expect(await db.select(db.accounts).get(), hasLength(11));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await db.select(db.accounts).get(), hasLength(10));
    await tester.pump(kUndoWindow);
  });

  testWidgets('review fix: an overpaid credit card shows as in credit, not owed', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts');
    await (db.update(db.accounts)..where((a) => a.id.equals('cc'))).write(const AccountsCompanion(balance: Value(-50000)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Nabil Visa Credit Card'), 200);
    expect(find.text('− NPR 500'), findsNothing);
    expect(find.text('NPR 500'), findsWidgets);
    expect(find.textContaining('in credit'), findsOneWidget);
  });
}
