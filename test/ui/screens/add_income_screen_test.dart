import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

Future<void> save(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(PaisaButton, label));
  await tester.pumpAndSettle();
}

Future<List<Txn>> txns(AppDatabase db) async => (await db.select(db.transactions).get()).map(txnFromRow).toList();

void main() {
  group('acceptance 14: Money in from an account page', () {
    testWidgets('Money in opens Add income with the account chosen; saving raises its balance', (tester) async {
      final db = await pumpPaisa(tester, location: '/accounts');
      await tester.tap(find.text('eSewa Wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Money in'));
      await tester.pumpAndSettle();

      expect(find.text('Add income'), findsOneWidget);
      final esewaChip = tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'eSewa'));
      expect(esewaChip.selected, isTrue);
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'Other Income')).selected, isTrue);

      await tester.enterText(fieldLabelled('Amount'), '1,000');
      await save(tester, 'Save income');

      expect(find.text('Income saved · NPR 1,000'), findsOneWidget);
      expect(find.text('NPR 9,420'), findsOneWidget, reason: 'back on the account page with the new balance');
      expect(await balanceOf(db, 'esewa'), fromRupees(9420));
      await tester.pump(kUndoWindow);
    });
  });

  group('Add income', () {
    testWidgets('opens on Monthly Salary into Nabil; take-home note shown', (tester) async {
      await pumpPaisa(tester, location: '/income/new');
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'Monthly Salary')).selected, isTrue);
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'Nabil ••4821')).selected, isTrue);
      expect(find.text('Take-home amount received'), findsOneWidget);
      expect(find.textContaining('won’t deduct them again'), findsOneWidget);
      expect(find.text('Business Income'), findsNothing, reason: 'inactive types are hidden');
    });

    testWidgets('gross mode shows the live breakdown and records take-home 92,789', (tester) async {
      final db = await pumpPaisa(tester, location: '/income/new');
      await tester.tap(find.text('Gross salary'));
      await tester.pumpAndSettle();
      expect(find.text('Gross monthly salary'), findsOneWidget);
      expect(find.text('NPR 92,789'), findsOneWidget);
      expect(find.text('− SSF — employee share'), findsOneWidget);
      expect(find.text('Sample defaults — verify for your fiscal year'), findsOneWidget);
      await save(tester, 'Save income');

      final salary = (await txns(db)).firstWhere((t) => t.title == 'Salary — Himal Tech Pvt. Ltd.');
      expect(salary.amount, fromRupees(92789));
      expect(salary.incomeTypeId, 'salary');
      expect(await balanceOf(db, 'nabil'), fromRupees(142350 + 92789));
      await tester.pump(kUndoWindow);
    });

    testWidgets('pending income is saved but does not change the balance', (tester) async {
      final db = await pumpPaisa(tester, location: '/income/new');
      await tester.tap(find.text('Freelance Income'));
      await tester.pump();
      await tester.enterText(fieldLabelled('Amount'), '5000');
      await scrollAndTap(tester, find.text('Pending'));
      expect(find.textContaining('not added to balances or totals'), findsOneWidget);
      await save(tester, 'Save income');
      expect(find.text('Pending income added · NPR 5,000'), findsOneWidget);
      final saved = (await txns(db)).firstWhere((t) => t.title == 'Freelance Income');
      expect(saved.status, TxStatus.pending);
      expect(await balanceOf(db, 'nabil'), fromRupees(142350));
      await tester.pump(kUndoWindow);
    });

    testWidgets('Undo removes the saved income', (tester) async {
      final db = await pumpPaisa(tester, location: '/income/new');
      await tester.enterText(fieldLabelled('Take-home amount received'), '92789');
      await save(tester, 'Save income');
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await balanceOf(db, 'nabil'), fromRupees(142350));
      expect(await txns(db), hasLength(17));
      await tester.pump(kUndoWindow);
    });
  });
}
