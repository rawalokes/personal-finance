import 'dates.dart';
import 'models.dart';
import 'money.dart';

/// User-editable lists from spec §4. Icons are names from `PaisaIcons.byName`
/// (e.g. 'brief', 'cart'); the UI resolves them.

enum IncomeFrequency { monthly, quarterly, yearly, irregular }

class IncomeType {
  const IncomeType({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    this.defaultAccountId,
    required this.recurring,
    this.expectedAmount,
    required this.frequency,
    this.expectedDay,
    this.applicableDeductionIds = const [],
    this.active = true,
  });

  final String id;
  final String name;
  final String? description;
  final String icon;

  /// ARGB, e.g. 0xFF0B7A53.
  final int color;
  final String? defaultAccountId;
  final bool recurring;
  final Paisa? expectedAmount;
  final IncomeFrequency frequency;
  final String? expectedDay;
  final List<String> applicableDeductionIds;
  final bool active;
}

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
    this.monthlyBudget,
    this.essential = false,
    this.system,
    this.active = true,
    this.custom = false,
  });

  final String id;
  final String name;
  final String icon;

  /// Set for subcategories (e.g. Fuel under Transport).
  final String? parentId;
  final Paisa? monthlyBudget;
  final bool essential;

  /// [kLoanInterestCategoryId] for the automatic Loan Interest category.
  final String? system;
  final bool active;
  final bool custom;

  bool get isAutomatic => system != null;
  bool get isTopLevel => parentId == null;
}

class LoanType {
  const LoanType({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.defaultMethod,
    this.active = true,
  });

  final String id;
  final String name;
  final String? description;
  final String icon;
  final InterestMethod defaultMethod;
  final bool active;
}

enum RecurringKind {
  expense('expense'),
  income('income'),
  loanExtra('loan_extra');

  const RecurringKind(this.wire);
  final String wire;
  static RecurringKind fromWire(String w) => values.firstWhere((k) => k.wire == w);
}

enum RecurringFrequency { monthly, quarterly, yearly }

class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    this.categoryId,
    this.incomeTypeId,
    required this.accountId,
    required this.frequency,
    required this.nextDate,
    this.active = true,
  });

  final String id;
  final String name;
  final RecurringKind kind;
  final Paisa amount;
  final String? categoryId;

  /// The spec's `RecurringRule` has only `categoryId`; income rules need
  /// their income type too.
  final String? incomeTypeId;
  final String accountId;
  final RecurringFrequency frequency;
  final IsoDate nextDate;
  final bool active;
}
