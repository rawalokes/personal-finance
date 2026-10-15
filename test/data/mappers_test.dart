import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/records.dart';
import 'package:paisa/finance/finance.dart';

import 'test_db.dart';

void main() {
  test('Account survives a database round trip, liability and card fields included', () async {
    final db = openTestDb();
    const card = Account(
      id: 'cc', name: 'Nabil Visa Credit Card', shortName: 'Nabil Visa ••5512', institution: 'Nabil Bank',
      accountTypeId: 'a6', group: AccountGroup.liability, kind: AccountKind.creditCard, maskedNumber: '5512',
      smsSender: 'NABIL_ALERT', autoUpdateFromSms: true, openingBalance: 0, balance: 1864000,
      creditLimit: 15000000, statementDueDate: '2026-10-18', note: 'Statement due 18 Oct',
      lastReconciled: '2026-10-01',
    );
    await db.into(db.accounts).insert(accountToCompanion(card, sortOrder: 9));
    final back = accountFromRow(await db.select(db.accounts).getSingle());
    expect(back.kind, AccountKind.creditCard);
    expect(back.group, AccountGroup.liability);
    expect(back.creditLimit, 15000000);
    expect(back.statementDueDate, '2026-10-18');
    expect(back.autoUpdateFromSms, isTrue);
    expect(back.maskedNumber, '5512');
  });

  test('Txn keeps wire type, direction, split and fills timestamps', () async {
    final db = openTestDb();
    await db.into(db.accounts).insert(accountToCompanion(const Account(
          id: 'nabil', name: 'Nabil', shortName: 'Nabil', group: AccountGroup.liquid, kind: AccountKind.bank,
          openingBalance: 0, balance: 0,
        )));
    const tx = Txn(
      id: 't1', date: '2026-10-05', time: '06:00', title: 'Personal loan B installment',
      type: TxType.loanRepayment, direction: Direction.debit, accountId: 'nabil', loanId: 'L3',
      amount: 516700, principal: 416700, interest: 100000, source: TxSource.sms,
    );
    await db.into(db.transactions).insert(txnToCompanion(tx, now: '2026-10-14T10:30:00'));
    final row = await db.select(db.transactions).getSingle();
    expect(row.type, 'loan_repayment');
    final back = txnFromRow(row);
    expect(back.type, TxType.loanRepayment);
    expect(back.direction, Direction.debit);
    expect(back.principal, 416700);
    expect(back.interest, 100000);
    expect(back.source, TxSource.sms);
    expect(back.status, TxStatus.posted);
    expect(back.createdAt, '2026-10-14T10:30:00');
  });

  test('Loan keeps a missing rate as null ("Not entered"), not 0', () async {
    final db = openTestDb();
    const loan = Loan(
      id: 'L9', loanTypeId: 'personal', name: 'X', lender: 'Y', principal: 100, outstanding: 50,
      ratePct: null, method: InterestMethod.reducing, installment: 10, frequency: LoanFrequency.flexible,
    );
    await db.into(db.loans).insert(loanToCompanion(loan));
    final back = loanFromRow(await db.select(db.loans).getSingle());
    expect(back.ratePct, isNull);
    expect(back.frequency, LoanFrequency.flexible);
  });

  test('catalog rows round-trip: income type deductions list, category budget, recurring kind', () async {
    final db = openTestDb();
    await db.into(db.incomeTypes).insert(incomeTypeToCompanion(const IncomeType(
          id: 'salary', name: 'Monthly Salary', icon: 'brief', color: 0xFF0B7A53, recurring: true,
          frequency: IncomeFrequency.monthly, applicableDeductionIds: ['tax', 'ssf'],
        )));
    await db.into(db.expenseCategories).insert(categoryToCompanion(const ExpenseCategory(
          id: 'loan_interest', name: 'Loan Interest', icon: 'percent', system: kLoanInterestCategoryId,
        )));
    await db.into(db.recurringRules).insert(recurringToCompanion(const RecurringRule(
          id: 'r1', name: 'Extra', kind: RecurringKind.loanExtra, amount: 500000, accountId: 'nabil',
          frequency: RecurringFrequency.monthly, nextDate: '2026-11-01',
        )));
    expect(incomeTypeFromRow(await db.select(db.incomeTypes).getSingle()).applicableDeductionIds, ['tax', 'ssf']);
    final cat = categoryFromRow(await db.select(db.expenseCategories).getSingle());
    expect(cat.isAutomatic, isTrue);
    expect(cat.monthlyBudget, isNull);
    expect(recurringFromRow(await db.select(db.recurringRules).getSingle()).kind, RecurringKind.loanExtra);
  });

  test('audit entry round-trips its actor', () async {
    final db = openTestDb();
    await db.into(db.auditEntries).insert(auditToCompanion(const AuditEntry(
          id: 'e1', at: '2026-10-14T08:00:00', actor: AuditActor.sms, action: 'sms.scan',
          entity: 'sms', summary: 'Daily SMS scan found 7 bank and wallet messages',
        )));
    expect(auditFromRow(await db.select(db.auditEntries).getSingle()).actor, AuditActor.sms);
  });
}
