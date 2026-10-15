import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/repos/catalog_repo.dart';
import 'package:paisa/data/undo.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/store/ui_state.dart';
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
  group('acceptance 14: Money out from an account page', () {
    testWidgets('Money out opens Add expense with the account chosen; saving lowers its balance', (tester) async {
      final db = await pumpPaisa(tester, location: '/accounts/khalti');
      await tester.tap(find.bySemanticsLabel('Money out'));
      await tester.pumpAndSettle();
      expect(find.text('Add expense'), findsOneWidget);
      expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'Khalti')).selected, isTrue);

      await tester.enterText(fieldLabelled('Amount'), '450');
      await save(tester, 'Save expense');

      expect(find.text('Expense saved · NPR 450'), findsOneWidget);
      expect(await balanceOf(db, 'khalti'), fromRupees(2150 - 450));
      final saved = (await txns(db)).firstWhere((t) => t.title == 'Groceries');
      expect(saved.categoryId, 'groceries');
      expect(saved.accountId, 'khalti');
      expect(saved.date, '2026-10-14');
      expect(saved.time, '10:30');
      await tester.pump(kUndoWindow);
    });
  });

  group('Add expense', () {
    testWidgets('budget hint updates as you type and warns when over', (tester) async {
      await pumpPaisa(tester, location: '/expense/new');
      expect(find.text('Groceries: NPR 6,560 of NPR 12,000 after this'), findsOneWidget);
      await tester.enterText(fieldLabelled('Amount'), '6000');
      await tester.pump();
      expect(find.text('Groceries: NPR 12,560 of NPR 12,000 after this — over budget'), findsOneWidget);
    });

    testWidgets('Loan Interest is not offered; the merchant becomes the title', (tester) async {
      final db = await pumpPaisa(tester, location: '/expense/new');
      expect(find.text('Loan Interest'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Transport'));
      await tester.pump();
      await tester.enterText(fieldLabelled('Amount'), '380');
      await tester.enterText(fieldLabelled('Merchant'), 'Pathao ride');
      await save(tester, 'Save expense');
      final saved = (await txns(db)).firstWhere((t) => t.title == 'Pathao ride');
      expect(saved.categoryId, 'transport');
      expect(saved.accountId, 'nabil');
      await tester.pump(kUndoWindow);
    });

    testWidgets('Repeat monthly adds a recurring rule; Undo removes both', (tester) async {
      final db = await pumpPaisa(tester, location: '/expense/new');
      await tester.enterText(fieldLabelled('Amount'), '1695');
      await tester.enterText(fieldLabelled('Merchant'), 'WorldLink');
      await scrollAndTap(tester, find.byType(PaisaToggle));
      await save(tester, 'Save expense');
      expect(find.text('Expense saved · NPR 1,695 · repeats monthly'), findsOneWidget);
      final rules = await db.select(db.recurringRules).get();
      expect(rules.where((r) => r.name == 'WorldLink').single.nextDate, '2026-11-14');

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await db.select(db.recurringRules).get()).where((r) => r.name == 'WorldLink'), isEmpty);
      expect(await balanceOf(db, 'nabil'), fromRupees(142350));
      await tester.pump(kUndoWindow);
    });

    testWidgets('review focus: amounts that are not clean positive numbers are refused', (tester) async {
      final db = await pumpPaisa(tester, location: '/expense/new');
      for (final bad in ['', '0', '-5', '1.505', 'abc', '12345678901234567890']) {
        await tester.enterText(fieldLabelled('Amount'), bad);
        await save(tester, 'Save expense');
        expect(find.text('Enter an amount greater than zero'), findsOneWidget, reason: '"$bad"');
      }
      expect(await txns(db), hasLength(17));

      await tester.enterText(fieldLabelled('Amount'), 'Rs. 1,500.50');
      await save(tester, 'Save expense');
      final saved = (await txns(db)).firstWhere((t) => t.title == 'Groceries');
      expect(saved.amount, 150050);
      await tester.pump(kUndoWindow);
    });
  });

  testWidgets('review fix: if saving the repeat rule fails, the expense is not saved either', (tester) async {
    final db = await pumpPaisa(tester, location: '/expense/new', overrides: [
      catalogRepoProvider.overrideWith((ref) => _FailingRecurring(ref.watch(databaseProvider), ref.watch(auditLogProvider))),
    ]);
    await tester.enterText(fieldLabelled('Amount'), '1695');
    await scrollAndTap(tester, find.byType(PaisaToggle));
    await save(tester, 'Save expense');
    expect(find.text('Couldn’t save — nothing was changed'), findsOneWidget);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect(await txns(db), hasLength(17));
  });
  testWidgets('review fix: with no account to use, Add expense asks you to add one instead of crashing', (tester) async {
    final db = await pumpPaisa(tester, location: '/expense/new');
    await (db.update(db.accounts)..where((a) => a.accountGroup.isIn(['liquid', 'liability'])))
        .write(const AccountsCompanion(archived: Value(true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Add an account first'), findsOneWidget);
    final saveLabel = 'Save expense';
    expect(tester.widget<PaisaButton>(find.widgetWithText(PaisaButton, saveLabel)).onPressed, isNull);
  });
  testWidgets('review fix: with balances hidden, the budget hint masks spending and the budget', (tester) async {
    await pumpPaisa(tester, location: '/expense/new', overrides: [hideBalancesProvider.overrideWith(_Hidden.new)]);
    expect(find.textContaining('6,560'), findsNothing);
    expect(find.textContaining('12,000'), findsNothing);
    expect(find.textContaining('Groceries: NPR ••••••'), findsOneWidget);
  });
}

/// A catalog whose recurring-rule write fails, like a database error would.
class _FailingRecurring extends CatalogRepository {
  _FailingRecurring(super.db, super.audit);

  @override
  Future<UndoAction> addRecurring(RecurringRule rule) => Future.error(StateError('disk full'));
}

class _Hidden extends HideBalances {
  @override
  bool build() => true;
}
