import 'package:drift/drift.dart';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../ledger_store.dart';
import '../mappers.dart';
import '../records.dart';
import '../undo.dart';

/// The only way transactions are written. Every write runs the finance
/// engine's [applyTransaction] inside one database transaction, so a row and
/// the balances it changes are saved together or not at all.
class TransactionRepository {
  TransactionRepository(this._db, this._audit, {required this._clock});

  final AppDatabase _db;
  final AuditLog _audit;
  final Clock _clock;

  List<OrderingTerm Function($TransactionsTable)> get _newestFirst => [
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.time),
        (t) => OrderingTerm.desc(t.createdAt),
      ];

  Stream<List<Txn>> watchAll() =>
      (_db.select(_db.transactions)..orderBy(_newestFirst)).watch().map((r) => r.map(txnFromRow).toList());

  /// Transactions on [accountId], either side (a transfer shows on both).
  Stream<List<Txn>> watchForAccount(String accountId) => (_db.select(_db.transactions)
        ..where((t) => t.accountId.equals(accountId) | t.counterAccountId.equals(accountId))
        ..orderBy(_newestFirst))
      .watch()
      .map((r) => r.map(txnFromRow).toList());

  Future<Txn?> find(String id) async {
    final row = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : txnFromRow(row);
  }

  /// Saves [tx] and applies its effect. Throws [LedgerError] (and saves
  /// nothing) when the engine rejects it. Undo deletes it again.
  Future<UndoAction> add(Txn tx, {required String summary, AuditActor actor = AuditActor.user}) async {
    await _db.transaction(() async {
      await _insertApplied(tx);
      await _audit.write(action: 'transaction.add', entity: 'transaction', entityId: tx.id, summary: summary, actor: actor);
    });
    return UndoAction(() => _db.transaction(() async {
          await _deleteReverted(tx.id);
          await _audit.write(action: 'transaction.undo', entity: 'transaction', entityId: tx.id, summary: 'Undid the last change');
        }));
  }

  /// Deletes the transaction and reverses its exact effect (acceptance
  /// test 11). Undo puts it back with the same id and effect.
  Future<UndoAction> delete(String id) async {
    late Txn removed;
    await _db.transaction(() async {
      removed = await _deleteReverted(id);
      await _audit.write(
        action: 'transaction.delete',
        entity: 'transaction',
        entityId: id,
        summary: 'Deleted ${removed.title} · ${auditMoney(removed.amount)}',
      );
    });
    return UndoAction(() => _db.transaction(() async {
          await _insertApplied(removed);
          await _audit.write(action: 'transaction.undo', entity: 'transaction', entityId: id, summary: 'Undid the last change');
        }));
  }

  Future<void> _insertApplied(Txn tx) async {
    final before = await loadLedger(_db);
    final after = applyTransaction(before, tx);
    await saveLedgerChanges(_db, before, after);
    await _db.into(_db.transactions).insert(txnToCompanion(tx, now: _clock.stamp()));
  }

  Future<Txn> _deleteReverted(String id) async {
    final tx = await find(id);
    if (tx == null) throw StateError('No transaction $id');
    final before = await loadLedger(_db);
    final after = revertTransaction(before, tx);
    await saveLedgerChanges(_db, before, after);
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    return tx;
  }
}
