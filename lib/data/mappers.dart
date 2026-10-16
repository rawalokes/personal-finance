import 'dart:convert';

import 'package:drift/drift.dart';

import '../finance/finance.dart';
import 'db/database.dart';
import '../sms/sms_models.dart';
import 'records.dart';

// Rows ↔ models. Enum columns hold wire strings; `.name` is used for enums
// whose names already are the wire form (liquid, posted, reducing, …).

T _byName<T extends Enum>(List<T> values, String name) => values.firstWhere((v) => v.name == name);

Account accountFromRow(AccountRow r) => Account(
      id: r.id,
      name: r.name,
      shortName: r.shortName,
      institution: r.institution,
      accountTypeId: r.accountTypeId,
      group: _byName(AccountGroup.values, r.accountGroup),
      kind: AccountKind.fromWire(r.kind),
      maskedNumber: r.maskedNumber,
      smsSender: r.smsSender,
      autoUpdateFromSms: r.autoUpdateFromSms,
      openingBalance: r.openingBalance,
      balance: r.balance,
      creditLimit: r.creditLimit,
      statementDueDate: r.statementDueDate,
      note: r.note,
      archived: r.archived,
      lastReconciled: r.lastReconciled,
    );

AccountsCompanion accountToCompanion(Account a, {int sortOrder = 0}) => AccountsCompanion.insert(
      id: a.id,
      name: a.name,
      shortName: a.shortName,
      institution: Value(a.institution),
      accountTypeId: Value(a.accountTypeId),
      accountGroup: a.group.name,
      kind: a.kind.wire,
      maskedNumber: Value(a.maskedNumber),
      smsSender: Value(a.smsSender),
      autoUpdateFromSms: Value(a.autoUpdateFromSms),
      openingBalance: a.openingBalance,
      balance: a.balance,
      creditLimit: Value(a.creditLimit),
      statementDueDate: Value(a.statementDueDate),
      note: Value(a.note),
      archived: Value(a.archived),
      lastReconciled: Value(a.lastReconciled),
      sortOrder: Value(sortOrder),
    );

Txn txnFromRow(TxnRow r) => Txn(
      id: r.id,
      date: r.date,
      time: r.time,
      title: r.title,
      type: TxType.fromWire(r.type),
      direction: r.direction == null ? null : _byName(Direction.values, r.direction!),
      accountId: r.accountId,
      counterAccountId: r.counterAccountId,
      categoryId: r.categoryId,
      incomeTypeId: r.incomeTypeId,
      loanId: r.loanId,
      amount: r.amount,
      principal: r.principal,
      interest: r.interest,
      status: _byName(TxStatus.values, r.status),
      source: _byName(TxSource.values, r.source),
      smsId: r.smsId,
      note: r.note,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );

/// [now] fills createdAt / updatedAt when the model has none.
TransactionsCompanion txnToCompanion(Txn t, {required String now}) => TransactionsCompanion.insert(
      id: t.id,
      date: t.date,
      time: t.time,
      title: t.title,
      type: t.type.wire,
      direction: Value(t.direction?.name),
      accountId: t.accountId,
      counterAccountId: Value(t.counterAccountId),
      categoryId: Value(t.categoryId),
      incomeTypeId: Value(t.incomeTypeId),
      loanId: Value(t.loanId),
      amount: t.amount,
      principal: Value(t.principal),
      interest: Value(t.interest),
      status: t.status.name,
      source: t.source.name,
      smsId: Value(t.smsId),
      note: Value(t.note),
      createdAt: t.createdAt ?? now,
      updatedAt: t.updatedAt ?? now,
    );

Loan loanFromRow(LoanRow r) => Loan(
      id: r.id,
      loanTypeId: r.loanTypeId,
      name: r.name,
      lender: r.lender,
      principal: r.principal,
      outstanding: r.outstanding,
      ratePct: r.ratePct,
      method: _byName(InterestMethod.values, r.method),
      installment: r.installment,
      frequency: _byName(LoanFrequency.values, r.frequency),
      startDate: r.startDate,
      maturityDate: r.maturityDate,
      nextDueDate: r.nextDueDate,
      repaymentAccountId: r.repaymentAccountId,
      feesAndPrepayment: r.feesAndPrepayment,
      closed: r.closed,
    );

LoansCompanion loanToCompanion(Loan l, {int sortOrder = 0}) => LoansCompanion.insert(
      id: l.id,
      loanTypeId: l.loanTypeId,
      name: l.name,
      lender: l.lender,
      principal: l.principal,
      outstanding: l.outstanding,
      ratePct: Value(l.ratePct),
      method: l.method.name,
      installment: l.installment,
      frequency: l.frequency.name,
      startDate: Value(l.startDate),
      maturityDate: Value(l.maturityDate),
      nextDueDate: Value(l.nextDueDate),
      repaymentAccountId: Value(l.repaymentAccountId),
      feesAndPrepayment: Value(l.feesAndPrepayment),
      closed: Value(l.closed),
      sortOrder: Value(sortOrder),
    );

IncomeType incomeTypeFromRow(IncomeTypeRow r) => IncomeType(
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon,
      color: r.color,
      defaultAccountId: r.defaultAccountId,
      recurring: r.recurring,
      expectedAmount: r.expectedAmount,
      frequency: _byName(IncomeFrequency.values, r.frequency),
      expectedDay: r.expectedDay,
      applicableDeductionIds: (jsonDecode(r.applicableDeductionIds) as List<dynamic>).cast<String>(),
      active: r.active,
    );

IncomeTypesCompanion incomeTypeToCompanion(IncomeType t, {int sortOrder = 0}) => IncomeTypesCompanion.insert(
      id: t.id,
      name: t.name,
      description: Value(t.description),
      icon: t.icon,
      color: t.color,
      defaultAccountId: Value(t.defaultAccountId),
      recurring: t.recurring,
      expectedAmount: Value(t.expectedAmount),
      frequency: t.frequency.name,
      expectedDay: Value(t.expectedDay),
      applicableDeductionIds: Value(jsonEncode(t.applicableDeductionIds)),
      active: Value(t.active),
      sortOrder: Value(sortOrder),
    );

ExpenseCategory categoryFromRow(CategoryRow r) => ExpenseCategory(
      id: r.id,
      name: r.name,
      icon: r.icon,
      parentId: r.parentId,
      monthlyBudget: r.monthlyBudget,
      essential: r.essential,
      system: r.system,
      active: r.active,
      custom: r.custom,
    );

ExpenseCategoriesCompanion categoryToCompanion(ExpenseCategory c, {int sortOrder = 0}) =>
    ExpenseCategoriesCompanion.insert(
      id: c.id,
      name: c.name,
      icon: c.icon,
      parentId: Value(c.parentId),
      monthlyBudget: Value(c.monthlyBudget),
      essential: Value(c.essential),
      system: Value(c.system),
      active: Value(c.active),
      custom: Value(c.custom),
      sortOrder: Value(sortOrder),
    );

LoanType loanTypeFromRow(LoanTypeRow r) => LoanType(
      id: r.id,
      name: r.name,
      description: r.description,
      icon: r.icon,
      defaultMethod: _byName(InterestMethod.values, r.defaultMethod),
      active: r.active,
    );

LoanTypesCompanion loanTypeToCompanion(LoanType t, {int sortOrder = 0}) => LoanTypesCompanion.insert(
      id: t.id,
      name: t.name,
      description: Value(t.description),
      icon: t.icon,
      defaultMethod: t.defaultMethod.name,
      active: Value(t.active),
      sortOrder: Value(sortOrder),
    );

RecurringRule recurringFromRow(RecurringRow r) => RecurringRule(
      id: r.id,
      name: r.name,
      kind: RecurringKind.fromWire(r.type),
      amount: r.amount,
      categoryId: r.categoryId,
      incomeTypeId: r.incomeTypeId,
      accountId: r.accountId,
      frequency: _byName(RecurringFrequency.values, r.frequency),
      nextDate: r.nextDate,
      active: r.active,
    );

RecurringRulesCompanion recurringToCompanion(RecurringRule r) => RecurringRulesCompanion.insert(
      id: r.id,
      name: r.name,
      type: r.kind.wire,
      amount: r.amount,
      categoryId: Value(r.categoryId),
      incomeTypeId: Value(r.incomeTypeId),
      accountId: r.accountId,
      frequency: r.frequency.name,
      nextDate: r.nextDate,
      active: Value(r.active),
    );

ConfigItem configItemFromRow(ConfigItemRow r) => ConfigItem(
      id: r.id,
      listKey: r.listKey,
      name: r.name,
      description: r.description,
      active: r.active,
      isDefault: r.isDefault,
    );

ConfigItemsCompanion configItemToCompanion(ConfigItem c, {int sortOrder = 0}) => ConfigItemsCompanion.insert(
      id: c.id,
      listKey: c.listKey,
      name: c.name,
      description: Value(c.description),
      active: Value(c.active),
      isDefault: Value(c.isDefault),
      sortOrder: Value(sortOrder),
    );

AuditEntry auditFromRow(AuditRow r) => AuditEntry(
      id: r.id,
      at: r.at,
      actor: _byName(AuditActor.values, r.actor),
      action: r.action,
      entity: r.entity,
      entityId: r.entityId,
      summary: r.summary,
      beforeJson: r.beforeJson,
      afterJson: r.afterJson,
    );

AuditEntriesCompanion auditToCompanion(AuditEntry e) => AuditEntriesCompanion.insert(
      id: e.id,
      at: e.at,
      actor: e.actor.name,
      action: e.action,
      entity: e.entity,
      entityId: Value(e.entityId),
      summary: e.summary,
      beforeJson: Value(e.beforeJson),
      afterJson: Value(e.afterJson),
    );

Goal goalFromRow(GoalRow r) => Goal(
      id: r.id,
      name: r.name,
      kind: r.kind,
      icon: r.icon,
      target: r.target,
      current: r.current,
      linkedAccountId: r.linkedAccountId,
      targetDate: r.targetDate,
    );

GoalsCompanion goalToCompanion(Goal g, {int sortOrder = 0}) => GoalsCompanion.insert(
      id: g.id,
      name: g.name,
      kind: g.kind,
      icon: Value(g.icon),
      target: g.target,
      current: Value(g.current),
      linkedAccountId: Value(g.linkedAccountId),
      targetDate: Value(g.targetDate),
      sortOrder: Value(sortOrder),
    );

SmsMessage smsFromRow(SmsRow r) => SmsMessage(
      id: r.id,
      sender: r.sender,
      receivedAt: r.receivedAt,
      maskedBody: r.maskedBody,
      bodyHash: r.bodyHash,
      sourceKey: r.sourceKey,
      institution: r.institution,
      accountId: r.accountId,
      direction: _byName(Direction.values, r.direction),
      amount: r.amount,
      merchant: r.merchant,
      date: r.date,
      time: r.time,
      type: TxType.fromWire(r.type),
      categoryId: r.categoryId,
      incomeTypeId: r.incomeTypeId,
      counterAccountId: r.counterAccountId,
      loanId: r.loanId,
      confidence: _byName(SmsConfidence.values, r.confidence),
      reason: r.reason,
      suggestedBy: _byName(SmsSuggestedBy.values, r.suggestedBy),
      status: _byName(SmsStatus.values, r.status),
      duplicateOfId: r.duplicateOfId,
      transactionId: r.transactionId,
      edited: r.edited,
      autoSaved: r.autoSaved,
      description: r.description,
    );

SmsMessagesCompanion smsToCompanion(SmsMessage m) => SmsMessagesCompanion.insert(
      id: m.id,
      sender: m.sender,
      receivedAt: m.receivedAt,
      maskedBody: m.maskedBody,
      bodyHash: m.bodyHash,
      sourceKey: Value(m.sourceKey),
      institution: m.institution,
      accountId: Value(m.accountId),
      direction: m.direction.name,
      amount: m.amount,
      merchant: m.merchant,
      date: m.date,
      time: m.time,
      type: m.type.wire,
      categoryId: Value(m.categoryId),
      incomeTypeId: Value(m.incomeTypeId),
      counterAccountId: Value(m.counterAccountId),
      loanId: Value(m.loanId),
      confidence: m.confidence.name,
      reason: m.reason,
      suggestedBy: m.suggestedBy.name,
      status: m.status.name,
      duplicateOfId: Value(m.duplicateOfId),
      transactionId: Value(m.transactionId),
      edited: Value(m.edited),
      autoSaved: Value(m.autoSaved),
      description: Value(m.description),
    );
