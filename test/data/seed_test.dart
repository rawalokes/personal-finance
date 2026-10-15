import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';

import 'test_db.dart';

void main() {
  test('first launch seeds spec §12 accounts with auto-update off', () async {
    final db = openTestDb();
    expect(await seedIfNeeded(db), isTrue);
    final accounts = {for (final r in await db.select(db.accounts).get()) r.id: accountFromRow(r)};
    expect(accounts, hasLength(10));
    expect(accounts['nabil']!.balance, fromRupees(142350));
    expect(accounts['nabil']!.maskedNumber, '4821');
    expect(accounts['nic']!.group, AccountGroup.reserved);
    expect(accounts['fd']!.group, AccountGroup.locked);
    expect(accounts['cc']!.group, AccountGroup.liability);
    expect(accounts['cc']!.balance, fromRupees(18640));
    expect(accounts['cc']!.creditLimit, fromRupees(150000));
    expect(accounts['cc']!.statementDueDate, '2026-10-18');
    expect(accounts.values.where((a) => a.autoUpdateFromSms), isEmpty);
  });

  test('seeded totals: available 1,84,020; net worth matches the mockup', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final accounts = (await db.select(db.accounts).get()).map(accountFromRow);
    final loans = (await db.select(db.loans).get()).map(loanFromRow);
    final s = summarizeBalances(accounts, loans);
    expect(s.availableToSpend, fromRupees(142350 + 24600 + 8420 + 2150 + 6500));
    expect(s.loans, fromRupees(228640 + 131450 + 54163 + 30000));
    expect(s.netWorth, fromRupees(184020 + 385000 + 981200 - 18640 - 444253));
  });

  test('categories carry spec budgets; Loan Interest is the automatic system category', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final cats = {for (final r in await db.select(db.expenseCategories).get()) r.id: categoryFromRow(r)};
    expect(cats['housing']!.monthlyBudget, fromRupees(22000));
    expect(cats['charges']!.monthlyBudget, fromRupees(500));
    expect(cats[kLoanInterestCategoryId]!.isAutomatic, isTrue);
    expect(cats[kLoanInterestCategoryId]!.monthlyBudget, isNull);
    expect(cats['transport_fuel']!.parentId, 'transport');
    expect(cats.values.where((c) => c.isTopLevel), hasLength(12));
  });

  test('income types, loan types, loans, recurring rules and config lists are seeded', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final types = (await db.select(db.incomeTypes).get()).map(incomeTypeFromRow).toList();
    expect(types.map((t) => t.name), contains('Monthly Salary'));
    expect(types.where((t) => !t.active).map((t) => t.id), unorderedEquals(['business', 'rental']));
    expect(await db.select(db.loanTypes).get(), hasLength(7));
    final kiran = loanFromRow(await (db.select(db.loans)..where((l) => l.id.equals('L4'))).getSingle());
    expect(kiran.method, InterestMethod.none);
    expect(kiran.frequency, LoanFrequency.flexible);
    final loanB = loanFromRow(await (db.select(db.loans)..where((l) => l.id.equals('L3'))).getSingle());
    expect(loanB.feesAndPrepayment, isNull, reason: 'shown as "Not entered"');
    expect(await db.select(db.recurringRules).get(), hasLength(6));
    expect(await db.select(db.configItems).get(), hasLength(10 + 5 + 8 + 7));
  });

  test('seeded October history gives the mockup month totals', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final txns = (await db.select(db.transactions).get()).map(txnFromRow).toList();
    expect(txns, hasLength(17));
    final oct = monthlyTotals(txns, '2026-10');
    expect(oct.income, fromRupees(1240 + 25000));
    expect(oct.expenses, fromRupees(1695 + 2180 + 4500 + 2180 + 1499 + 1140 + 1860 + 1000 + 10000 + 1240 + 4380 + 22000));
    expect(oct.byCategory[kLoanInterestCategoryId], fromRupees(1000));
  });

  test('review focus: seeding runs exactly once, even after the user deletes data', () async {
    final db = openTestDb();
    expect(await seedIfNeeded(db), isTrue);
    await db.delete(db.transactions).go();
    expect(await seedIfNeeded(db), isFalse);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.accounts).get(), hasLength(10));
  });
}
