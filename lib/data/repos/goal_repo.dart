import 'package:drift/drift.dart';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../undo.dart';
import 'transaction_repo.dart';

/// Savings goals. Adding money to a goal is never spending: when it moves
/// between two of your accounts it is recorded as a transfer.
class GoalRepository {
  GoalRepository(this._db, this._audit, this._transactions, {required this._clock, required this._newId});

  final AppDatabase _db;
  final AuditLog _audit;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGen _newId;

  Stream<List<Goal>> watchAll() => (_db.select(_db.goals)..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
      .watch()
      .map((rows) => rows.map(goalFromRow).toList());

  Future<Goal> _get(String id) async =>
      goalFromRow(await (_db.select(_db.goals)..where((g) => g.id.equals(id))).getSingle());

  Future<Goal> add(Goal draft) async {
    final goal = Goal(
      id: _newId(),
      name: draft.name.trim(),
      kind: draft.kind,
      icon: draft.icon,
      target: draft.target,
      current: draft.current,
      linkedAccountId: draft.linkedAccountId,
      targetDate: draft.targetDate,
    );
    await _db.transaction(() async {
      final count = (await _db.select(_db.goals).get()).length;
      await _db.into(_db.goals).insert(goalToCompanion(goal, sortOrder: count));
      await _audit.write(action: 'goal.add', entity: 'goal', entityId: goal.id, summary: 'Created goal ${goal.name}');
    });
    return goal;
  }

  /// Adds [amount] to the goal. With a [toAccountId] different from
  /// [fromAccountId], the money is also moved there as a transfer.
  Future<UndoAction> contribute(
    String goalId, {
    required Paisa amount,
    required String fromAccountId,
    String? toAccountId,
  }) async {
    final goal = await _get(goalId);
    final undos = <UndoAction>[];
    await _db.transaction(() async {
      if (toAccountId != null && toAccountId != fromAccountId) {
        undos.add(await _transactions.add(
          Txn(
            id: _newId(),
            date: _clock.today(),
            time: _clock.hhmm(),
            title: 'Saved to ${goal.name}',
            type: TxType.transfer,
            direction: Direction.debit,
            accountId: fromAccountId,
            counterAccountId: toAccountId,
            amount: amount,
          ),
          summary: 'Moved ${auditMoney(amount)} to goal ${goal.name}',
        ));
      }
      await _setCurrent(goalId, goal.current + amount);
      await _audit.write(
        action: 'goal.contribute',
        entity: 'goal',
        entityId: goalId,
        summary: 'Added ${auditMoney(amount)} to ${goal.name}',
      );
    });
    undos.add(UndoAction(() => _setCurrent(goalId, goal.current)));
    return UndoAction.combine(undos);
  }

  Future<UndoAction> delete(String goalId) async {
    final row = await (_db.select(_db.goals)..where((g) => g.id.equals(goalId))).getSingle();
    await _db.transaction(() async {
      await (_db.delete(_db.goals)..where((g) => g.id.equals(goalId))).go();
      await _audit.write(action: 'goal.delete', entity: 'goal', entityId: goalId, summary: 'Deleted goal ${row.name}');
    });
    return UndoAction(() => _db.into(_db.goals).insert(row));
  }

  Future<void> _setCurrent(String goalId, Paisa value) =>
      (_db.update(_db.goals)..where((g) => g.id.equals(goalId))).write(GoalsCompanion(current: Value(value)));
}
