import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

void main() {
  testWidgets('tapping an account on the Accounts tab opens its page; Back returns', (tester) async {
    await pumpPaisa(tester, location: '/accounts');
    await tester.tap(find.text('eSewa Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Current balance'), findsOneWidget);
    expect(find.text('NPR 8,420'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Net worth'), findsOneWidget);
  });

  testWidgets('credit card page shows amount owed, limit use, sender and activity', (tester) async {
    await pumpPaisa(tester, location: '/accounts/cc');
    expect(find.text('Nabil Visa Credit Card'), findsOneWidget);
    expect(find.text('Amount owed'), findsOneWidget);
    expect(find.text('Liability'), findsOneWidget);
    expect(find.text('Credit card'), findsOneWidget);
    expect(find.text('NPR 18,640 used of NPR 1,50,000 limit · statement due 18 Oct'), findsOneWidget);
    expect(find.text('Reads messages from sender “NABIL_ALERT” for ••5512'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Daraz order'), 200);
    expect(find.text('3 transactions'), findsOneWidget);
    expect(find.text('Liabilities'), findsOneWidget);
  });

  testWidgets('auto-update toggle saves and explains itself', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts/esewa');
    await tester.tap(find.byType(PaisaToggle));
    await tester.pumpAndSettle();
    expect(find.text('Confident SMS for eSewa will update the balance automatically'), findsOneWidget);
    final row = await (db.select(db.accounts)..where((a) => a.id.equals('esewa'))).getSingle();
    expect(row.autoUpdateFromSms, isTrue);
    await tester.pump(kUndoWindow);
  });

  testWidgets('reconcile books the difference as an adjustment, with undo', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts/esewa');
    await tester.tap(find.bySemanticsLabel('Reconcile'));
    await tester.pumpAndSettle();
    expect(find.text('Paisa shows NPR 8,420. Enter the balance from your bank app or statement.'), findsOneWidget);
    await tester.enterText(fieldLabelled('Actual balance (NPR)'), '8000');
    await tester.pump();
    expect(find.textContaining('Difference −NPR 420.'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Reconcile'));
    await tester.pumpAndSettle();

    expect(find.text('eSewa reconciled · adjustment −NPR 420'), findsOneWidget);
    expect(await balanceOf(db, 'esewa'), fromRupees(8000));
    expect(find.text('Reconciliation adjustment'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await balanceOf(db, 'esewa'), fromRupees(8420));
    await tester.pump(kUndoWindow);
  });

  testWidgets('reconcile with a matching balance just confirms', (tester) async {
    await pumpPaisa(tester, location: '/accounts/esewa');
    await tester.tap(find.bySemanticsLabel('Reconcile'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Actual balance (NPR)'), '8,420');
    await tester.pump();
    expect(find.text('Balances match — nothing to adjust.'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Reconcile'));
    await tester.pumpAndSettle();
    expect(find.text('eSewa reconciled — balances match'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('reconcile asks for a number', (tester) async {
    await pumpPaisa(tester, location: '/accounts/esewa');
    await tester.tap(find.bySemanticsLabel('Reconcile'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PaisaButton, 'Reconcile'));
    await tester.pump();
    expect(find.text('Enter the actual balance'), findsOneWidget);
  });

  testWidgets('archive asks first, returns to Accounts without the account, and can be undone', (tester) async {
    final db = await pumpPaisa(tester, location: '/accounts');
    await tester.tap(find.text('eSewa Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Archive eSewa Wallet?'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Archive account'));
    await tester.pumpAndSettle();

    expect(find.text('Net worth'), findsOneWidget);
    expect(find.text('eSewa Wallet'), findsNothing);
    expect(find.text('Account archived'), findsOneWidget);
    expect(find.text('NPR 1,75,600'), findsOneWidget, reason: 'liquid total drops by 8,420');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('eSewa Wallet'), findsOneWidget);
    final row = accountFromRow(await (db.select(db.accounts)..where((a) => a.id.equals('esewa'))).getSingle());
    expect(row.archived, isFalse);
    await tester.pump(kUndoWindow);
  });

  testWidgets('review fix: with balances hidden, the reconcile sheet does not reveal the balance', (tester) async {
    await pumpPaisa(tester, location: '/accounts/esewa', overrides: [hideBalancesProvider.overrideWith(_Hidden.new)]);
    await tester.tap(find.bySemanticsLabel('Reconcile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('8,420'), findsNothing);
    expect(find.textContaining('Paisa shows NPR ••••••'), findsOneWidget);
  });
}

class _Hidden extends HideBalances {
  @override
  bool build() => true;
}
