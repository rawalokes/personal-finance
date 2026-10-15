import 'package:drift/drift.dart';

import '../finance/finance.dart';
import 'db/database.dart';
import 'mappers.dart';

/// Loads every account and loan as the engine's [LedgerState]. The data set
/// is small (tens of rows), so loading all keeps the engine the only place
/// that decides which balances a transaction touches.
Future<LedgerState> loadLedger(AppDatabase db) async {
  final accounts = (await db.select(db.accounts).get()).map(accountFromRow);
  final loans = (await db.select(db.loans).get()).map(loanFromRow);
  return LedgerState.from(accounts, loans);
}

/// Writes back only the balances, outstandings and due dates that changed
/// between [before] and [after]. Call inside a database transaction.
Future<void> saveLedgerChanges(AppDatabase db, LedgerState before, LedgerState after) async {
  for (final a in after.accounts.values) {
    if (before.accounts[a.id]?.balance == a.balance) continue;
    await (db.update(db.accounts)..where((r) => r.id.equals(a.id)))
        .write(AccountsCompanion(balance: Value(a.balance)));
  }
  for (final l in after.loans.values) {
    final old = before.loans[l.id];
    if (old?.outstanding == l.outstanding && old?.nextDueDate == l.nextDueDate) continue;
    await (db.update(db.loans)..where((r) => r.id.equals(l.id))).write(LoansCompanion(
          outstanding: Value(l.outstanding),
          nextDueDate: Value(l.nextDueDate),
        ));
  }
}
