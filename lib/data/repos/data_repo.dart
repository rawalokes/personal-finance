import 'dart:convert';

import 'package:drift/drift.dart';

import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../records.dart';
import '../seed.dart';

/// Export and "Delete all data" (spec §10). Exports contain only database
/// contents: secrets (AI key, PIN) live in secure storage and are never read.
class DataRepository {
  DataRepository(this._db, this._audit, {required this._clock});

  final AppDatabase _db;
  final AuditLog _audit;
  final Clock _clock;

  /// A full JSON backup of every table.
  Future<String> exportJson() async {
    Future<List<Map<String, Object?>>> rows<T extends Table, D extends DataClass>(TableInfo<T, D> table) async =>
        [for (final r in await _db.select(table).get()) r.toJson()];
    final out = <String, Object?>{
      'app': 'Paisa',
      'schemaVersion': _db.schemaVersion,
      'exportedAt': _clock.stamp(),
      'accounts': await rows(_db.accounts),
      'transactions': await rows(_db.transactions),
      'loans': await rows(_db.loans),
      'goals': await rows(_db.goals),
      'incomeTypes': await rows(_db.incomeTypes),
      'expenseCategories': await rows(_db.expenseCategories),
      'loanTypes': await rows(_db.loanTypes),
      'recurringRules': await rows(_db.recurringRules),
      'configItems': await rows(_db.configItems),
      'settings': await rows(_db.settings),
      'auditEntries': await rows(_db.auditEntries),
    };
    await _audit.write(action: 'data.export', entity: 'data', summary: 'Exported a JSON backup');
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// Transactions as CSV for spreadsheets; amounts in rupees with 2 decimals.
  Future<String> exportTransactionsCsv() async {
    String cell(Object? v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final parties = {
      for (final p in await (_db.select(_db.configItems)..where((c) => c.listKey.equals(ConfigList.parties))).get()) p.id: p.name,
    };
    final txns = (await _db.select(_db.transactions).get()).map(txnFromRow).toList()
      ..sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'));
    final b = StringBuffer('date,time,title,type,account,counter_account,category,income_type,amount_npr,status,source,party\n');
    for (final t in txns) {
      b.writeln([
        t.date, t.time, t.title, t.type.wire, t.accountId, t.counterAccountId, t.categoryId, t.incomeTypeId,
        (t.amount / 100).toStringAsFixed(2), t.status.name, t.source.name,
        t.partyId == null ? null : parties[t.partyId],
      ].map(cell).join(','));
    }
    await _audit.write(action: 'data.export', entity: 'data', summary: 'Exported transactions as CSV');
    return b.toString();
  }

  /// Erases everything and restores a clean install's default lists.
  Future<void> deleteAllData() => _db.transaction(() async {
        for (final table in _db.allTables.toList().reversed) {
          await _db.delete(table).go();
        }
        await seedIfNeeded(_db);
      });
}
