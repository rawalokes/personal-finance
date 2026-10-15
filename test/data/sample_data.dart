import 'package:drift/drift.dart' show Value;
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/records.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/salary_settings.dart';

// The spec §12 / mockup sample data. Tests use it as a realistic fixture; the
// app itself ships none of it (a clean install starts empty, see seed.dart).

Paisa _r(num rupees) => fromRupees(rupees);

/// Seeds the defaults, then adds the sample accounts, loans, history,
/// recurring rules, budgets, income-type defaults and audit samples.
Future<void> seedWithSampleData(AppDatabase db) async {
  await seedIfNeeded(db);
  await db.transaction(() async {
    await db.batch((b) {
      b.insertAll(db.accounts, [for (final (i, a) in sampleAccounts.indexed) accountToCompanion(a, sortOrder: i)]);
      b.insertAll(db.loans, [for (final (i, l) in sampleLoans.indexed) loanToCompanion(l, sortOrder: i)]);
      b.insertAll(db.recurringRules, [for (final r in sampleRecurring) recurringToCompanion(r)]);
      b.insertAll(db.transactions, [for (final t in sampleTransactions) txnToCompanion(t, now: '${t.date}T${t.time}:00')]);
      b.insertAll(db.auditEntries, [for (final e in sampleAudit) auditToCompanion(e)]);
    });
    for (final (id, budget) in sampleBudgets) {
      await (db.update(db.expenseCategories)..where((c) => c.id.equals(id)))
          .write(ExpenseCategoriesCompanion(monthlyBudget: Value(_r(budget))));
    }
    for (final (id, account, expected) in sampleIncomeDefaults) {
      await (db.update(db.incomeTypes)..where((t) => t.id.equals(id))).write(IncomeTypesCompanion(
            defaultAccountId: Value(account),
            expectedAmount: Value(expected == null ? null : _r(expected)),
          ));
    }
  });
}

/// Spec §12 monthly budgets.
const sampleBudgets = [
  ('housing', 22000), ('groceries', 12000), ('transport', 6000), ('family', 15000), ('utilities', 5000),
  ('education', 3000), ('health', 3000), ('subs', 2000), ('fun', 5000), ('charges', 500), ('other', 3000),
];

/// Income type → default account and expected amount, from the mockup.
const List<(String, String, num?)> sampleIncomeDefaults = [
  ('salary', 'nabil', 92789), ('bonus', 'nabil', 120000), ('freelance', 'nabil', null), ('business', 'nabil', null),
  ('rental', 'nabil', null), ('interest', 'nic', 1200), ('dividend', 'nabil', null), ('other_inc', 'nabil', null),
];

/// Spec §12 salary: gross 1,20,000 at Himal Tech, basic 60%.
final sampleSalarySettings = SalarySettings(
  employer: 'Himal Tech Pvt. Ltd.',
  grossMonthly: fromRupees(120000),
  basicPct: 60,
  taxCategory: 'individual',
  deductions: sampleDeductions(),
  rules: sampleTaxRules(),
);

Account _account(
  String id,
  String name,
  String short,
  String institution,
  String typeId,
  AccountGroup group,
  AccountKind kind,
  num balance,
  num opening,
  String reconciled, {
  String? mask,
  String? sender,
  String? note,
  num? limit,
  String? due,
}) =>
    Account(
      id: id,
      name: name,
      shortName: short,
      institution: institution,
      accountTypeId: typeId,
      group: group,
      kind: kind,
      maskedNumber: mask,
      smsSender: sender,
      openingBalance: _r(opening),
      balance: _r(balance),
      creditLimit: limit == null ? null : _r(limit),
      statementDueDate: due,
      note: note,
      lastReconciled: reconciled,
    );

/// Auto-update is off for every sample account (spec §12).
final List<Account> sampleAccounts = [
  _account('nabil', 'Nabil Bank — Salary', 'Nabil ••4821', 'Nabil Bank', 'a1', AccountGroup.liquid, AccountKind.bank,
      142350, 58200, '2026-09-30', mask: '4821', sender: 'NABIL_ALERT'),
  _account('gibl', 'Global IME — Current', 'Global IME ••3307', 'Global IME Bank', 'a1', AccountGroup.liquid,
      AccountKind.bank, 24600, 20000, '2026-09-30',
      mask: '3307', sender: 'GIBL', note: 'Used for scooter-loan EMI recovery'),
  _account('esewa', 'eSewa Wallet', 'eSewa', 'eSewa', 'a4', AccountGroup.liquid, AccountKind.wallet, 8420, 3000,
      '2026-10-10', sender: 'eSewa'),
  _account('khalti', 'Khalti Wallet', 'Khalti', 'Khalti', 'a4', AccountGroup.liquid, AccountKind.wallet, 2150, 1500,
      '2026-10-01', sender: 'Khalti'),
  _account('cash', 'Cash in hand', 'Cash', '—', 'a3', AccountGroup.liquid, AccountKind.cash, 6500, 5000, '2026-10-12'),
  _account('nic', 'NIC Asia — Savings', 'NIC Asia ••2290', 'NIC Asia Bank', 'a2', AccountGroup.reserved,
      AccountKind.savings, 385000, 250000, '2026-09-30',
      mask: '2290', sender: 'NIC_ASIA', note: 'Earmarked for the emergency fund'),
  _account('fd', 'Global IME — Fixed Deposit', 'FD ••0915', 'Global IME Bank', 'a5', AccountGroup.locked,
      AccountKind.fixedDeposit, 500000, 500000, '2026-09-15',
      mask: '0915', note: '6.75% p.a. · matures 15 Mar 2027'),
  _account('cit', 'CIT — Retirement fund', 'CIT', 'Citizen Investment Trust', 'a7', AccountGroup.locked,
      AccountKind.cit, 286400, 180000, '2026-07-16', note: 'Retirement savings — not withdrawable now'),
  _account('ssf', 'Social Security Fund', 'SSF', 'Social Security Fund', 'a8', AccountGroup.locked, AccountKind.ssf,
      194800, 90000, '2026-07-16', note: 'Employee + employer contributions'),
  _account('cc', 'Nabil Visa Credit Card', 'Nabil Visa ••5512', 'Nabil Bank', 'a6', AccountGroup.liability,
      AccountKind.creditCard, 18640, 0, '2026-10-01',
      mask: '5512', sender: 'NABIL_ALERT', note: 'Statement due 18 Oct', limit: 150000, due: '2026-10-18'),
];

final List<Loan> sampleLoans = [
  Loan(
    id: 'L1', loanTypeId: 'vehicle', name: 'Scooter loan', lender: 'Global IME Bank',
    principal: _r(350000), outstanding: _r(228640), ratePct: 11.25, method: InterestMethod.reducing,
    installment: _r(11501), frequency: LoanFrequency.monthly, startDate: '2025-08-13', maturityDate: '2028-07-13',
    nextDueDate: '2026-10-13', repaymentAccountId: 'gibl',
    feesAndPrepayment: '1% fee on prepaid amount; free after 24 installments',
  ),
  Loan(
    id: 'L2', loanTypeId: 'personal', name: 'Personal loan A', lender: 'NIC Asia Bank',
    principal: _r(200000), outstanding: _r(131450), ratePct: 13.5, method: InterestMethod.reducing,
    installment: _r(6790), frequency: LoanFrequency.monthly, startDate: '2025-06-20', maturityDate: '2028-06-20',
    nextDueDate: '2026-10-20', repaymentAccountId: 'nabil',
    feesAndPrepayment: 'Prepayment allowed after 12 months, 0.5% fee',
  ),
  Loan(
    id: 'L3', loanTypeId: 'personal', name: 'Personal loan B', lender: 'Siddhartha Bank',
    principal: _r(100000), outstanding: _r(54163), ratePct: 12, method: InterestMethod.flat,
    installment: _r(5167), frequency: LoanFrequency.monthly, startDate: '2025-11-05', maturityDate: '2027-11-05',
    nextDueDate: '2026-11-05', repaymentAccountId: 'nabil',
  ),
  Loan(
    id: 'L4', loanTypeId: 'family', name: 'Borrowed from Kiran', lender: 'Kiran (brother)',
    principal: _r(50000), outstanding: _r(30000), ratePct: 0, method: InterestMethod.none,
    installment: _r(5000), frequency: LoanFrequency.flexible, startDate: '2026-04-01',
    nextDueDate: '2026-10-01', repaymentAccountId: 'esewa', feesAndPrepayment: 'Interest-free; flexible timing',
  ),
];

RecurringRule _rec(String id, String name, num amount, String account, String next,
        {String? category, String? incomeType, RecurringFrequency frequency = RecurringFrequency.monthly}) =>
    RecurringRule(
      id: id,
      name: name,
      kind: incomeType == null ? RecurringKind.expense : RecurringKind.income,
      amount: _r(amount),
      categoryId: category,
      incomeTypeId: incomeType,
      accountId: account,
      frequency: frequency,
      nextDate: next,
    );

final List<RecurringRule> sampleRecurring = [
  _rec('r1', 'House rent', 22000, 'nabil', '2026-11-01', category: 'housing'),
  _rec('r2', 'Family support — Pokhara', 10000, 'nabil', '2026-11-04', category: 'family'),
  _rec('r3', 'WorldLink internet', 1695, 'esewa', '2026-11-13', category: 'utilities'),
  _rec('r4', 'Streaming subscription', 1499, 'cc', '2026-11-08', category: 'subs'),
  _rec('r5', 'Monthly salary', 92789, 'nabil', '2026-10-17', incomeType: 'salary'),
  _rec('r6', 'Health insurance premium', 14500, 'nabil', '2027-01-10',
      category: 'health', frequency: RecurringFrequency.yearly),
];

Txn _t(String id, String date, String time, String title, TxType type, String account, num amount,
        {String? category, String? incomeType, bool sms = false, String? counter, Direction? direction,
        String? loan, num? principal, num? interest}) =>
    Txn(
      id: id,
      date: date,
      time: time,
      title: title,
      type: type,
      direction: direction,
      accountId: account,
      counterAccountId: counter,
      categoryId: category,
      incomeTypeId: incomeType,
      loanId: loan,
      amount: _r(amount),
      principal: principal == null ? null : _r(principal),
      interest: interest == null ? null : _r(interest),
      source: sms ? TxSource.sms : TxSource.manual,
    );

/// History from the mockup. Already reflected in the sample balances.
final List<Txn> sampleTransactions = [
  _t('t15', '2026-10-13', '18:20', 'WorldLink internet', TxType.expense, 'esewa', 1695, category: 'utilities'),
  _t('t14', '2026-10-12', '16:05', 'NIC Asia interest credit', TxType.income, 'nic', 1240, incomeType: 'interest', sms: true),
  _t('t13', '2026-10-12', '09:30', 'Nepal Oil — petrol', TxType.expense, 'cash', 2180, category: 'transport'),
  _t('t12', '2026-10-11', '20:10', 'Load eSewa wallet', TxType.transfer, 'nabil', 5000,
      sms: true, counter: 'esewa', direction: Direction.debit),
  _t('t11', '2026-10-10', '19:45', 'QFX Cinemas — movie night', TxType.expense, 'esewa', 4500, category: 'fun'),
  _t('t10', '2026-10-09', '18:02', 'Big Mart', TxType.expense, 'esewa', 2180, category: 'groceries', sms: true),
  _t('t9', '2026-10-08', '07:00', 'Streaming subscription', TxType.expense, 'cc', 1499, category: 'subs', sms: true),
  _t('t8', '2026-10-07', '15:22', 'Himalayan Java', TxType.expense, 'cc', 1140, category: 'fun', sms: true),
  _t('t7', '2026-10-06', '11:00', 'Freelance — product audit', TxType.income, 'nabil', 25000, incomeType: 'freelance', sms: true),
  _t('t6', '2026-10-05', '10:15', 'NEA electricity bill', TxType.expense, 'esewa', 1860, category: 'utilities'),
  _t('t5b', '2026-10-05', '06:00', 'Personal loan B installment', TxType.loanRepayment, 'nabil', 5167,
      sms: true, loan: 'L3', principal: 4167, interest: 1000),
  _t('t5', '2026-10-04', '12:30', 'Sent to family — Pokhara', TxType.expense, 'nabil', 10000, category: 'family'),
  _t('t4', '2026-10-03', '08:50', 'Pathao rides', TxType.expense, 'khalti', 1240, category: 'transport'),
  _t('t3', '2026-10-02', '17:40', 'Bhat-Bhateni Supermarket', TxType.expense, 'nabil', 4380, category: 'groceries', sms: true),
  _t('t2', '2026-10-01', '09:00', 'House rent — October', TxType.expense, 'nabil', 22000, category: 'housing'),
  _t('t1', '2026-09-28', '13:10', 'Daraz order', TxType.expense, 'cc', 3240, category: 'other', sms: true),
  _t('t0', '2026-09-16', '10:05', 'Salary — Bhadra', TxType.income, 'nabil', 92789, incomeType: 'salary', sms: true),
];

const List<AuditEntry> sampleAudit = [
  AuditEntry(id: 'seed-a5', at: '2026-10-05T06:10:00', actor: AuditActor.user, action: 'sms.confirm', entity: 'transaction',
      entityId: 't5b', summary: 'Confirmed SMS: Personal loan B installment · NPR 5,167'),
  AuditEntry(id: 'seed-a4', at: '2026-10-10T20:02:00', actor: AuditActor.user, action: 'account.reconcile', entity: 'account',
      entityId: 'esewa', summary: 'Reconciled eSewa wallet — no difference'),
  AuditEntry(id: 'seed-a3', at: '2026-10-12T09:30:00', actor: AuditActor.user, action: 'transaction.add', entity: 'transaction',
      entityId: 't13', summary: 'Added expense Nepal Oil — petrol · NPR 2,180'),
  AuditEntry(id: 'seed-a2', at: '2026-10-13T18:20:00', actor: AuditActor.user, action: 'transaction.add', entity: 'transaction',
      entityId: 't15', summary: 'Added expense WorldLink internet · NPR 1,695'),
  AuditEntry(id: 'seed-a1', at: '2026-10-14T08:00:00', actor: AuditActor.sms, action: 'sms.scan', entity: 'sms',
      summary: 'Daily SMS scan found 7 bank and wallet messages'),
];
