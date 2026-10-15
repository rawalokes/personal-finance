import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';

import 'sample_data.dart';
import 'test_db.dart';

/// The test fixture (spec §12 / mockup sample data) stays faithful to the
/// spec's numbers, which many screen tests rely on.
void main() {
  test('the sample data has the spec §12 accounts with auto-update off', () async {
    final db = openTestDb();
    await seedWithSampleData(db);
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

  test('sample totals: available 1,84,020; net worth matches the mockup', () async {
    final db = openTestDb();
    await seedWithSampleData(db);
    final accounts = (await db.select(db.accounts).get()).map(accountFromRow);
    final loans = (await db.select(db.loans).get()).map(loanFromRow);
    final s = summarizeBalances(accounts, loans);
    expect(s.availableToSpend, fromRupees(142350 + 24600 + 8420 + 2150 + 6500));
    expect(s.loans, fromRupees(228640 + 131450 + 54163 + 30000));
    expect(s.netWorth, fromRupees(184020 + 385000 + 981200 - 18640 - 444253));
  });

  test('the sample October history gives the mockup month totals', () async {
    final db = openTestDb();
    await seedWithSampleData(db);
    final txns = (await db.select(db.transactions).get()).map(txnFromRow).toList();
    expect(txns, hasLength(17));
    final oct = monthlyTotals(txns, '2026-10');
    expect(oct.income, fromRupees(1240 + 25000));
    expect(oct.expenses, fromRupees(1695 + 2180 + 4500 + 2180 + 1499 + 1140 + 1860 + 1000 + 10000 + 1240 + 4380 + 22000));
    expect(oct.byCategory[kLoanInterestCategoryId], fromRupees(1000));
  });
}
