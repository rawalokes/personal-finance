import 'package:drift/drift.dart';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../records.dart';
import '../undo.dart';

/// Income types, expense categories, loan types, the generic config lists,
/// recurring rules and loans. Editing screens for these arrive in later
/// plans; Plan 2 reads them and adds recurring rules.
class CatalogRepository {
  CatalogRepository(this._db, this._audit);

  final AppDatabase _db;
  final AuditLog _audit;

  Stream<List<IncomeType>> watchIncomeTypes() =>
      (_db.select(_db.incomeTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch()
          .map((r) => r.map(incomeTypeFromRow).toList());

  Stream<List<ExpenseCategory>> watchCategories() =>
      (_db.select(_db.expenseCategories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch()
          .map((r) => r.map(categoryFromRow).toList());

  Stream<List<LoanType>> watchLoanTypes() =>
      (_db.select(_db.loanTypes)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch()
          .map((r) => r.map(loanTypeFromRow).toList());

  Stream<List<ConfigItem>> watchConfig(String listKey) => (_db.select(_db.configItems)
        ..where((c) => c.listKey.equals(listKey))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch()
      .map((r) => r.map(configItemFromRow).toList());

  Stream<List<Loan>> watchLoans() => (_db.select(_db.loans)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch()
      .map((r) => r.map(loanFromRow).toList());

  Stream<List<RecurringRule>> watchRecurring() =>
      (_db.select(_db.recurringRules)..orderBy([(t) => OrderingTerm.asc(t.nextDate)]))
          .watch()
          .map((r) => r.map(recurringFromRow).toList());

  Future<UndoAction> addRecurring(RecurringRule rule) async {
    await _db.transaction(() async {
      await _db.into(_db.recurringRules).insert(recurringToCompanion(rule));
      await _audit.write(
        action: 'recurring.add',
        entity: 'recurring',
        entityId: rule.id,
        summary: 'Added recurring ${rule.name} · ${auditMoney(rule.amount)}',
      );
    });
    return UndoAction(() => _db.transaction(() async {
          await (_db.delete(_db.recurringRules)..where((r) => r.id.equals(rule.id))).go();
          await _audit.write(action: 'recurring.undo', entity: 'recurring', entityId: rule.id, summary: 'Undid the last change');
        }));
  }
}
