import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Accounts,
  Transactions,
  Loans,
  IncomeTypes,
  ExpenseCategories,
  LoanTypes,
  RecurringRules,
  ConfigItems,
  AuditEntries,
  AppMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Bump this and add a step in [migration] whenever a table changes.
  /// Later plans add the SMS, goals, salary and integration tables.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX idx_txn_date ON transactions (date, time)');
          await customStatement('CREATE INDEX idx_txn_account ON transactions (account_id)');
          await customStatement('CREATE INDEX idx_txn_counter ON transactions (counter_account_id)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
