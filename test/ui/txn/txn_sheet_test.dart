import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/ui/theme.dart';
import 'package:paisa/ui/tokens.dart';
import 'package:paisa/ui/txn/txn_sheet.dart';

import '../../data/data_fixtures.dart';
import '../../data/sample_data.dart';
import '../../data/test_db.dart';

Future<AppDatabase> pumpSheetHost(WidgetTester tester, String txnId) async {
  final db = openTestDb();
  await seedWithSampleData(db);
  final txn = sampleTransactions.firstWhere((t) => t.id == txnId);
  await tester.pumpWidget(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(testClock)],
    child: MaterialApp(
      theme: paisaTheme(PaisaColors.night),
      builder: (context, child) => PaisaToastHost(child: child!),
      home: Scaffold(body: Builder(builder: (context) {
        return TextButton(onPressed: () => showTxnSheet(context, txn), child: const Text('open'));
      })),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return db;
}

void main() {
  testWidgets('sheet shows amount, facts and the accounting note', (tester) async {
    await pumpSheetHost(tester, 't5b');
    expect(find.text('Personal loan B installment'), findsOneWidget);
    expect(find.text('− NPR 5,167'), findsOneWidget);
    expect(find.text('Loan repayment'), findsOneWidget);
    expect(find.text('NPR 4,167'), findsOneWidget);
    expect(find.text('Approved from SMS'), findsOneWidget);
    expect(find.text('Principal reduced the loan; only interest is an expense.'), findsOneWidget);
  });

  testWidgets('acceptance 11 (UI): delete asks first, reverses the balance, and Undo restores it', (tester) async {
    final db = await pumpSheetHost(tester, 't15');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this transaction?'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, 'Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('WorldLink internet'), findsNothing, reason: 'sheet closed');
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(await balanceOf(db, 'esewa'), fromRupees(8420 + 1695));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Change undone'), findsOneWidget);
    expect(await balanceOf(db, 'esewa'), fromRupees(8420));
    await tester.pump(kUndoWindow);
  });

  testWidgets('cancelling the confirm dialog keeps the transaction', (tester) async {
    final db = await pumpSheetHost(tester, 't15');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('WorldLink internet'), findsOneWidget);
    expect(await balanceOf(db, 'esewa'), fromRupees(8420));
  });
}
