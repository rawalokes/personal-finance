import 'package:drift/drift.dart';
import 'dart:io';

import 'package:drift/native.dart' show NativeDatabase, SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/seed.dart';

import 'test_db.dart';

AccountsCompanion _account(String id) => AccountsCompanion.insert(
      id: id,
      name: 'Test $id',
      shortName: id,
      accountGroup: 'liquid',
      kind: 'bank',
      openingBalance: 0,
      balance: 0,
    );

void main() {
  test('creates every table at schema version 3', () async {
    final db = openTestDb();
    expect(db.schemaVersion, 3);
    final names = (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get())
        .map((r) => r.read<String>('name'))
        .toSet();
    expect(
      names,
      containsAll([
        'accounts', 'transactions', 'loans', 'income_types', 'expense_categories', 'loan_types',
        'recurring_rules', 'config_items', 'audit_entries', 'app_meta', 'goals', 'settings', 'sms_messages',
      ]),
    );
  });

  test('foreign keys are enforced: a transaction needs a real account', () async {
    final db = openTestDb();
    final insert = db.into(db.transactions).insert(TransactionsCompanion.insert(
          id: 't1', date: '2026-10-14', time: '09:00', title: 'X', type: 'expense',
          accountId: 'missing', amount: 100, status: 'posted', source: 'manual',
          createdAt: '2026-10-14T09:00:00', updatedAt: '2026-10-14T09:00:00',
        ));
    await expectLater(insert, throwsA(isA<SqliteException>()));
  });

  test('money columns round-trip exact integers', () async {
    final db = openTestDb();
    await db.into(db.accounts).insert(_account('a').copyWith(balance: const Value(999999999999)));
    final row = await (db.select(db.accounts)..where((a) => a.id.equals('a'))).getSingle();
    expect(row.balance, 999999999999);
    expect(row.archived, isFalse);
    expect(row.autoUpdateFromSms, isFalse);
  });

  test('a version-1 database upgrades to v2 and keeps its data', () async {
    final dir = Directory.systemTemp.createTempSync('paisa_mig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/paisa.sqlite');
    // Build what a v1 install looks like: v1 tables and data, no goals/settings.
    var db = AppDatabase(NativeDatabase(file));
    await db.into(db.accounts).insert(_account('cash'));
    await db.customStatement('DROP TABLE goals');
    await db.customStatement('DROP TABLE settings');
    await db.customStatement('DROP TABLE sms_messages');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final names = (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get())
        .map((r) => r.read<String>('name'))
        .toSet();
    expect(names, containsAll(['goals', 'settings', 'sms_messages']));
    expect(await db.select(db.accounts).get(), hasLength(1));
  });

  test('a version-2 database upgrades to v3 (SMS inbox) and keeps its data', () async {
    final dir = Directory.systemTemp.createTempSync('paisa_mig3');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/paisa.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    await db.into(db.accounts).insert(_account('cash'));
    await db.customStatement('DROP TABLE sms_messages');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await db.select(db.smsMessages).get(), isEmpty);
    expect(await db.select(db.accounts).get(), hasLength(1));
  });

  test('existing installs get the real bank sender IDs once, keeping banks the user changed', () async {
    final db = openTestDb();
    addTearDown(db.close);
    await seedIfNeeded(db);
    // As 1.3.1 and earlier seeded them; the user edited Nabil's.
    Future<void> setDesc(String id, String d) =>
        (db.update(db.configItems)..where((c) => c.id.equals(id))).write(ConfigItemsCompanion(description: Value(d)));
    await setDesc('b1', 'Sender MY_NABIL');
    await setDesc('b3', 'Sender GIBL');
    await setDesc('b5', 'Sender eSewa · wallet notifications');
    await (db.delete(db.configItems)..where((c) => c.id.isIn(['b8', 'b9']))).go();
    await (db.delete(db.appMeta)..where((m) => m.key.equals(kBankSendersKey))).go();

    await updateBankSenders(db);
    await updateBankSenders(db);
    Future<String> desc(String id) async =>
        (await (db.select(db.configItems)..where((c) => c.id.equals(id))).getSingle()).description;
    expect(await desc('b1'), 'Sender MY_NABIL', reason: 'the user changed it');
    expect(await desc('b3'), startsWith('Sender GBIME_ALERT, GIBL'));
    expect(await desc('b5'), startsWith('Sender eSewa, eSewa_Alert'));
    expect(await desc('b8'), startsWith('Sender NIMB, NIMB_ALERT'));
    expect(await (db.select(db.configItems)..where((c) => c.id.equals('b8'))).get(), hasLength(1));
  });
}
