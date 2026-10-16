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
  Goals,
  Settings,
  SmsMessages,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Bump this and add a step in [migration] whenever a table changes.
  /// v2: goals and settings. v3: SMS messages.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX idx_txn_date ON transactions (date, time)');
          await customStatement('CREATE INDEX idx_txn_account ON transactions (account_id)');
          await customStatement('CREATE INDEX idx_txn_counter ON transactions (counter_account_id)');
          await customStatement('CREATE INDEX idx_sms_status ON sms_messages (status, date, time)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(goals);
            await m.createTable(settings);
          }
          if (from < 3) {
            await m.createTable(smsMessages);
            await customStatement('CREATE INDEX idx_sms_status ON sms_messages (status, date, time)');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
