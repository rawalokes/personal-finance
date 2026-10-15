import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../records.dart';
import '../undo.dart';

/// A name already used by another item in the same list.
class DuplicateName implements Exception {
  DuplicateName(this.name);
  final String name;
  @override
  String toString() => 'DuplicateName: $name';
}

/// Income types, expense categories, loan types, the generic config lists,
/// recurring rules and loans: reading and editing.
class CatalogRepository {
  CatalogRepository(this._db, this._audit, {IdGen? newId}) : _newId = newId ?? const Uuid().v4;

  final AppDatabase _db;
  final AuditLog _audit;
  final IdGen _newId;

  Future<void> _log(String action, String entity, String? id, String summary, {AuditActor actor = AuditActor.user}) =>
      _audit.write(action: action, entity: entity, entityId: id, summary: summary, actor: actor);

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

  // ---- editing ----

  /// Sets (or with null clears) a category's monthly budget.
  /// [actor] is `ai` when the user applies an AI suggestion (spec §9.4).
  Future<void> setBudget(String categoryId, Paisa? limit, {AuditActor actor = AuditActor.user}) => _db.transaction(() async {
        await (_db.update(_db.expenseCategories)..where((c) => c.id.equals(categoryId)))
            .write(ExpenseCategoriesCompanion(monthlyBudget: Value(limit)));
        final name = (await (_db.select(_db.expenseCategories)..where((c) => c.id.equals(categoryId))).getSingle()).name;
        await _log('category.budget', 'category', categoryId,
            limit == null ? 'Removed $name budget' : '$name budget set to ${auditMoney(limit)}', actor: actor);
      });

  /// Adds (empty id) or updates a category; returns its id. Names are unique
  /// (case-insensitive).
  Future<String> saveCategory(ExpenseCategory c) => _db.transaction(() async {
        final all = (await _db.select(_db.expenseCategories).get()).map(categoryFromRow).toList();
        final name = c.name.trim();
        if (all.any((x) => x.id != c.id && x.name.toLowerCase() == name.toLowerCase())) throw DuplicateName(name);
        final isNew = c.id.isEmpty;
        final id = isNew ? _newId() : c.id;
        final order = isNew ? all.length : (await (_db.select(_db.expenseCategories)..where((r) => r.id.equals(id))).getSingle()).sortOrder;
        await _db.into(_db.expenseCategories).insertOnConflictUpdate(categoryToCompanion(
              ExpenseCategory(
                id: id,
                name: name,
                icon: c.icon,
                parentId: c.parentId,
                monthlyBudget: c.monthlyBudget,
                essential: c.essential,
                system: c.system,
                active: c.active,
                custom: isNew || c.custom,
              ),
              sortOrder: order,
            ));
        await _log(isNew ? 'category.add' : 'category.edit', 'category', id, '${isNew ? 'Added' : 'Edited'} category $name');
        return id;
      });

  Future<void> setCategoryActive(String id, bool active) => _db.transaction(() async {
        await (_db.update(_db.expenseCategories)..where((c) => c.id.equals(id)))
            .write(ExpenseCategoriesCompanion(active: Value(active)));
        await _log('category.toggle', 'category', id, '${active ? 'Enabled' : 'Disabled'} a category');
      });

  /// Deletes a category the user created. Its transactions keep their
  /// history and show as Uncategorised. Built-in categories can only be
  /// disabled.
  Future<void> deleteCategory(String id) => _db.transaction(() async {
        final row = await (_db.select(_db.expenseCategories)..where((c) => c.id.equals(id))).getSingle();
        if (!row.custom) throw StateError('Built-in categories can be disabled, not deleted');
        await (_db.delete(_db.expenseCategories)..where((c) => c.id.equals(id))).go();
        await _log('category.delete', 'category', id, 'Deleted category ${row.name}');
      });

  Future<String> saveIncomeType(IncomeType t) => _db.transaction(() async {
        final all = (await _db.select(_db.incomeTypes).get()).map(incomeTypeFromRow).toList();
        final name = t.name.trim();
        if (all.any((x) => x.id != t.id && x.name.toLowerCase() == name.toLowerCase())) throw DuplicateName(name);
        final isNew = t.id.isEmpty;
        final id = isNew ? _newId() : t.id;
        final order = isNew ? all.length : all.indexWhere((x) => x.id == id);
        await _db.into(_db.incomeTypes).insertOnConflictUpdate(incomeTypeToCompanion(
              IncomeType(
                id: id,
                name: name,
                description: t.description,
                icon: t.icon,
                color: t.color,
                defaultAccountId: t.defaultAccountId,
                recurring: t.recurring,
                expectedAmount: t.expectedAmount,
                frequency: t.frequency,
                expectedDay: t.expectedDay,
                applicableDeductionIds: t.applicableDeductionIds,
                active: t.active,
              ),
              sortOrder: order,
            ));
        await _log(isNew ? 'income_type.add' : 'income_type.edit', 'income_type', id, '${isNew ? 'Added' : 'Edited'} income type $name');
        return id;
      });

  Future<void> setIncomeTypeActive(String id, bool active) => _db.transaction(() async {
        await (_db.update(_db.incomeTypes)..where((t) => t.id.equals(id))).write(IncomeTypesCompanion(active: Value(active)));
        await _log('income_type.toggle', 'income_type', id, '${active ? 'Enabled' : 'Disabled'} an income type');
      });

  Future<String> saveLoanType(LoanType t) => _db.transaction(() async {
        final all = (await _db.select(_db.loanTypes).get()).map(loanTypeFromRow).toList();
        final name = t.name.trim();
        if (all.any((x) => x.id != t.id && x.name.toLowerCase() == name.toLowerCase())) throw DuplicateName(name);
        final isNew = t.id.isEmpty;
        final id = isNew ? _newId() : t.id;
        final order = isNew ? all.length : all.indexWhere((x) => x.id == id);
        await _db.into(_db.loanTypes).insertOnConflictUpdate(loanTypeToCompanion(
              LoanType(id: id, name: name, description: t.description, icon: t.icon, defaultMethod: t.defaultMethod, active: t.active),
              sortOrder: order,
            ));
        await _log(isNew ? 'loan_type.add' : 'loan_type.edit', 'loan_type', id, '${isNew ? 'Added' : 'Edited'} loan type $name');
        return id;
      });

  Future<void> addConfigItem(String listKey, String name, String description) => _db.transaction(() async {
        final count = (await (_db.select(_db.configItems)..where((c) => c.listKey.equals(listKey))).get()).length;
        await _db.into(_db.configItems).insert(configItemToCompanion(
              ConfigItem(id: _newId(), listKey: listKey, name: name.trim(), description: description.trim()),
              sortOrder: count,
            ));
        await _log('config.add', 'config', null, 'Added ${name.trim()}');
      });

  Future<void> setConfigActive(String id, bool active) => _db.transaction(() async {
        await (_db.update(_db.configItems)..where((c) => c.id.equals(id))).write(ConfigItemsCompanion(active: Value(active)));
        await _log('config.toggle', 'config', id, '${active ? 'Enabled' : 'Disabled'} a list entry');
      });

  /// Makes [id] the only default in its list.
  Future<void> setConfigDefault(String listKey, String id) => _db.transaction(() async {
        await (_db.update(_db.configItems)..where((c) => c.listKey.equals(listKey)))
            .write(const ConfigItemsCompanion(isDefault: Value(false)));
        await (_db.update(_db.configItems)..where((c) => c.id.equals(id)))
            .write(const ConfigItemsCompanion(isDefault: Value(true)));
        await _log('config.default', 'config', id, 'Changed a default');
      });

  Future<void> setRecurringActive(String id, bool active) => _db.transaction(() async {
        await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id)))
            .write(RecurringRulesCompanion(active: Value(active)));
        await _log('recurring.toggle', 'recurring', id, '${active ? 'Resumed' : 'Paused'} a recurring rule');
      });

  /// Removes a recurring rule if it exists (e.g. replacing the saved payoff
  /// plan's reminder).
  Future<void> removeRecurring(String id) =>
      (_db.delete(_db.recurringRules)..where((r) => r.id.equals(id))).go();
}
