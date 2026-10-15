import 'package:drift/drift.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/clock.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/finance/finance.dart';

import 'test_db.dart';

/// The mockup's TODAY, at 10:30.
final testClock = Clock.fixed(DateTime(2026, 10, 14, 10, 30));

/// Deterministic ids: id1, id2, …
IdGen counterIds([String prefix = 'id']) {
  var n = 0;
  return () => '$prefix${++n}';
}

Account acct(String id, AccountGroup group, Paisa balance, {AccountKind kind = AccountKind.bank, bool archived = false}) =>
    Account(
      id: id, name: id, shortName: id, group: group, kind: kind,
      openingBalance: balance, balance: balance, archived: archived,
    );

const loanB = Loan(
  id: 'L3', loanTypeId: 'personal', name: 'Personal loan B', lender: 'Siddhartha Bank',
  principal: 10000000, outstanding: 5416300, ratePct: 12, method: InterestMethod.flat,
  installment: 516700, frequency: LoanFrequency.monthly, nextDueDate: '2026-11-05',
);

/// A small ledger: Nabil 1,42,350 · NIC 3,85,000 · eSewa 8,420 · card owes 18,640 · loan B.
Future<AppDatabase> ledgerDb() async {
  final db = openTestDb();
  await db.batch((b) {
    b.insertAll(db.accounts, [
      accountToCompanion(acct('nabil', AccountGroup.liquid, fromRupees(142350)), sortOrder: 0),
      accountToCompanion(acct('nic', AccountGroup.reserved, fromRupees(385000), kind: AccountKind.savings), sortOrder: 1),
      accountToCompanion(acct('esewa', AccountGroup.liquid, fromRupees(8420), kind: AccountKind.wallet), sortOrder: 2),
      accountToCompanion(acct('cc', AccountGroup.liability, fromRupees(18640), kind: AccountKind.creditCard), sortOrder: 3),
    ]);
    b.insert(db.loans, loanToCompanion(loanB));
  });
  return db;
}

AuditLog testAudit(AppDatabase db) => AuditLog(db, clock: testClock, newId: counterIds('audit'));

Future<Paisa> balanceOf(AppDatabase db, String id) async =>
    (await (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle()).balance;

Future<LoanRow> loanRow(AppDatabase db, String id) =>
    (db.select(db.loans)..where((l) => l.id.equals(id))).getSingle();

Future<List<String>> auditSummaries(AppDatabase db) async =>
    (await (db.select(db.auditEntries)..orderBy([(e) => OrderingTerm.asc(e.rowId)])).get())
        .map((e) => e.summary)
        .toList();
