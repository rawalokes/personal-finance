import 'package:drift/drift.dart';

// Spec §4 tables. Enums are stored as their wire strings ('loan_repayment',
// 'credit_card', 'liquid') and converted in mappers.dart, so the database
// stays readable and enum renames never corrupt data. Money columns are
// integer paisa. Row classes end in `Row` so they never clash with the
// engine's models (Account, Txn, Loan).

@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get shortName => text()();
  TextColumn get institution => text().nullable()();
  TextColumn get accountTypeId => text().nullable()();
  TextColumn get accountGroup => text()();
  TextColumn get kind => text()();
  TextColumn get maskedNumber => text().nullable()();
  TextColumn get smsSender => text().nullable()();
  BoolColumn get autoUpdateFromSms => boolean().withDefault(const Constant(false))();
  IntColumn get openingBalance => integer()();
  IntColumn get balance => integer()();
  IntColumn get creditLimit => integer().nullable()();
  TextColumn get statementDueDate => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get lastReconciled => text().nullable()();

  /// Display order (Home cards, Accounts groups). New accounts go last.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TxnRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get time => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get direction => text().nullable()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get counterAccountId => text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable()();
  TextColumn get incomeTypeId => text().nullable()();
  TextColumn get loanId => text().nullable()();

  /// Who paid or was paid: a ConfigItem in the 'parties' list. v4.
  TextColumn get partyId => text().nullable()();
  IntColumn get amount => integer()();
  IntColumn get principal => integer().nullable()();
  IntColumn get interest => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get source => text()();
  TextColumn get smsId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LoanRow')
class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get loanTypeId => text()();
  TextColumn get name => text()();
  TextColumn get lender => text()();
  IntColumn get principal => integer()();
  IntColumn get outstanding => integer()();
  RealColumn get ratePct => real().nullable()();
  TextColumn get method => text()();
  IntColumn get installment => integer()();
  TextColumn get frequency => text()();
  TextColumn get startDate => text().nullable()();
  TextColumn get maturityDate => text().nullable()();
  TextColumn get nextDueDate => text().nullable()();
  TextColumn get repaymentAccountId => text().nullable()();
  TextColumn get feesAndPrepayment => text().nullable()();
  BoolColumn get closed => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('IncomeTypeRow')
class IncomeTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get defaultAccountId => text().nullable()();
  BoolColumn get recurring => boolean()();
  IntColumn get expectedAmount => integer().nullable()();
  TextColumn get frequency => text()();
  TextColumn get expectedDay => text().nullable()();

  /// JSON array of deduction ids.
  TextColumn get applicableDeductionIds => text().withDefault(const Constant('[]'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class ExpenseCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get monthlyBudget => integer().nullable()();
  BoolColumn get essential => boolean().withDefault(const Constant(false))();

  /// 'loan_interest' for the automatic Loan Interest category.
  TextColumn get system => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  BoolColumn get custom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LoanTypeRow')
class LoanTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text()();
  TextColumn get defaultMethod => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurringRow')
class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get incomeTypeId => text().nullable()();
  TextColumn get accountId => text()();
  TextColumn get frequency => text()();
  TextColumn get nextDate => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generic configurable lists (spec §4 `ConfigItem`): account types,
/// contribution types, classification rules, banks & wallets.
@DataClassName('ConfigItemRow')
class ConfigItems extends Table {
  TextColumn get id => text()();
  TextColumn get listKey => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditRow')
class AuditEntries extends Table {
  TextColumn get id => text()();

  /// ISO date-time, 'YYYY-MM-DDTHH:mm:ss'.
  TextColumn get at => text()();
  TextColumn get actor => text()();
  TextColumn get action => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text().nullable()();

  /// What the Audit screen shows, e.g. "Added expense Big Mart · NPR 2,180".
  TextColumn get summary => text()();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value facts about the database itself, e.g. 'seed_version'.
@DataClassName('MetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Savings goals (spec §4 `Goal`). Schema v2.
@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  TextColumn get icon => text().withDefault(const Constant('flag'))();
  IntColumn get target => integer()();

  /// Saved so far; ignored when [linkedAccountId] tracks an account balance.
  IntColumn get current => integer().withDefault(const Constant(0))();
  TextColumn get linkedAccountId => text().nullable()();
  TextColumn get targetDate => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// App settings as JSON documents under a key: preferences, salary profile,
/// deductions, tax rules, security, AI settings, payoff plan, AI cache.
/// Secrets (API key, PIN) never go here; they live in secure storage. v2.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Detected bank and wallet SMS (spec §4 SmsMessage). Only the masked body
/// is stored. v3.
@DataClassName('SmsRow')
class SmsMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sender => text()();
  TextColumn get receivedAt => text()();
  TextColumn get maskedBody => text()();
  TextColumn get bodyHash => text()();
  TextColumn get sourceKey => text().nullable().unique()();
  TextColumn get institution => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get direction => text()();
  IntColumn get amount => integer()();
  TextColumn get merchant => text()();
  TextColumn get date => text()();
  TextColumn get time => text()();
  TextColumn get type => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get incomeTypeId => text().nullable()();
  TextColumn get counterAccountId => text().nullable()();
  TextColumn get loanId => text().nullable()();
  TextColumn get partyId => text().nullable()();
  TextColumn get confidence => text()();
  TextColumn get reason => text()();
  TextColumn get suggestedBy => text()();
  TextColumn get status => text()();
  TextColumn get duplicateOfId => text().nullable()();
  TextColumn get transactionId => text().nullable()();
  BoolColumn get edited => boolean().withDefault(const Constant(false))();
  BoolColumn get autoSaved => boolean().withDefault(const Constant(false))();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  /// One phone message is stored once, however it arrives (broadcast, scan).
  @override
  List<Set<Column>> get uniqueKeys => [
        {bodyHash, receivedAt},
      ];
}
