import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/records.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';

import 'test_db.dart';

void main() {
  test('a clean install has no accounts, money, loans, recurring rules or history', () async {
    final db = openTestDb();
    expect(await seedIfNeeded(db), isTrue);
    expect(await db.select(db.accounts).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.loans).get(), isEmpty);
    expect(await db.select(db.recurringRules).get(), isEmpty);
    expect(await db.select(db.auditEntries).get(), isEmpty);
  });

  test('a clean install still has the default lists the forms need', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final types = (await db.select(db.incomeTypes).get()).map(incomeTypeFromRow).toList();
    expect(types.map((t) => t.name), containsAll(['Monthly Salary', 'Bonus', 'Freelance Income', 'Other Income']));
    expect(types.where((t) => !t.active).map((t) => t.id), unorderedEquals(['business', 'rental']));
    final cats = {for (final r in await db.select(db.expenseCategories).get()) r.id: categoryFromRow(r)};
    expect(cats.values.where((c) => c.isTopLevel), hasLength(12));
    expect(cats[kLoanInterestCategoryId]!.isAutomatic, isTrue);
    expect(cats['transport_fuel']!.parentId, 'transport');
    expect(await db.select(db.loanTypes).get(), hasLength(7));
    expect(await db.select(db.configItems).get(), hasLength(10 + 5 + 8 + 7));
  });

  test('no personal sample values: no budgets, expected amounts, default accounts or account numbers', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final cats = (await db.select(db.expenseCategories).get()).map(categoryFromRow);
    expect(cats.where((c) => c.monthlyBudget != null), isEmpty);
    final types = (await db.select(db.incomeTypes).get()).map(incomeTypeFromRow);
    expect(types.where((t) => t.expectedAmount != null || t.defaultAccountId != null), isEmpty);
    final banks = (await db.select(db.configItems).get())
        .map(configItemFromRow)
        .where((c) => c.listKey == ConfigList.banks);
    expect(banks.where((b) => b.description.contains('##')), isEmpty, reason: 'no account or card numbers');
    expect(banks.map((b) => b.description), contains('Sender NABIL_ALERT'));
  });

  test('review focus: seeding runs exactly once, even after the user changes the defaults', () async {
    final db = openTestDb();
    expect(await seedIfNeeded(db), isTrue);
    await db.delete(db.expenseCategories).go();
    expect(await seedIfNeeded(db), isFalse);
    expect(await db.select(db.expenseCategories).get(), isEmpty);
  });
}
