import 'package:drift/drift.dart';

import '../finance/money.dart';
import 'clock.dart';
import 'db/database.dart';
import 'mappers.dart';
import 'records.dart';

/// Amounts in audit summaries are always unmasked lakh format: the audit
/// trail is a record, not a display, and must not depend on preferences.
String auditMoney(Paisa p) => const MoneyFormat().npr(p);

/// Writes the audit trail (spec §10: "Full audit history"). Repositories call
/// [write] inside the same database transaction as the change it describes.
class AuditLog {
  AuditLog(this._db, {required this._clock, required this._newId});

  final AppDatabase _db;
  final Clock _clock;
  final IdGen _newId;

  Future<void> write({
    required String action,
    required String entity,
    String? entityId,
    required String summary,
    AuditActor actor = AuditActor.user,
  }) =>
      _db.into(_db.auditEntries).insert(auditToCompanion(AuditEntry(
            id: _newId(),
            at: _clock.stamp(),
            actor: actor,
            action: action,
            entity: entity,
            entityId: entityId,
            summary: summary,
          )));

  /// Newest first. Ties (same second) keep insertion order, newest first.
  Stream<List<AuditEntry>> watchRecent({int limit = 200}) {
    final q = _db.select(_db.auditEntries)
      ..orderBy([
        (e) => OrderingTerm.desc(e.at),
        (e) => OrderingTerm.desc(e.rowId),
      ])
      ..limit(limit);
    return q.watch().map((rows) => rows.map(auditFromRow).toList());
  }
}
