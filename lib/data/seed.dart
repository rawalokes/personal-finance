import '../finance/finance.dart';
import 'db/database.dart';
import 'mappers.dart';
import 'records.dart';

/// Bump when the seed changes in a way existing installs should NOT get
/// (they keep their data); new installs always get the latest seed.
const String kSeedVersion = '1';
const String kSeedVersionKey = 'seed_version';

Paisa _r(num rupees) => fromRupees(rupees);

/// Seeds the sample data (spec §12, using the mockup's fuller `seed()`) on
/// first launch only. Returns true if it seeded. Balances are seeded as the
/// current cached values: they already include history from before the
/// seeded transactions, so they are not recomputed from them.
Future<bool> seedIfNeeded(AppDatabase db) async {
  final marker = await (db.select(db.appMeta)..where((m) => m.key.equals(kSeedVersionKey))).getSingleOrNull();
  if (marker != null) return false;
  await db.transaction(() async {
    await db.batch((b) {
      b.insertAll(db.accounts, [for (final (i, a) in seedAccounts.indexed) accountToCompanion(a, sortOrder: i)]);
      b.insertAll(db.loans, [for (final (i, l) in seedLoans.indexed) loanToCompanion(l, sortOrder: i)]);
      b.insertAll(db.incomeTypes, [for (final (i, t) in seedIncomeTypes.indexed) incomeTypeToCompanion(t, sortOrder: i)]);
      b.insertAll(db.expenseCategories, [for (final (i, c) in seedCategories.indexed) categoryToCompanion(c, sortOrder: i)]);
      b.insertAll(db.loanTypes, [for (final (i, t) in seedLoanTypes.indexed) loanTypeToCompanion(t, sortOrder: i)]);
      b.insertAll(db.recurringRules, [for (final r in seedRecurring) recurringToCompanion(r)]);
      b.insertAll(db.configItems, [
        for (final list in seedConfig.values)
          for (final (i, c) in list.indexed) configItemToCompanion(c, sortOrder: i),
      ]);
      b.insertAll(db.transactions, [for (final t in seedTransactions) txnToCompanion(t, now: '${t.date}T${t.time}:00')]);
      b.insertAll(db.auditEntries, [for (final e in seedAudit) auditToCompanion(e)]);
      b.insert(db.appMeta, AppMetaCompanion.insert(key: kSeedVersionKey, value: kSeedVersion));
    });
  });
  return true;
}

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

/// Auto-update is off for every seeded account (spec §12).
final List<Account> seedAccounts = [
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

final List<Loan> seedLoans = [
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

final List<IncomeType> seedIncomeTypes = [
  IncomeType(
    id: 'salary', name: 'Monthly Salary', description: 'Take-home pay from your employer', icon: 'brief',
    color: 0xFF0B7A53, defaultAccountId: 'nabil', recurring: true, expectedAmount: _r(92789),
    frequency: IncomeFrequency.monthly, expectedDay: 'End of BS month',
    applicableDeductionIds: const ['tax', 'ssf', 'cit', 'insurance'],
  ),
  IncomeType(
    id: 'bonus', name: 'Bonus', description: 'Dashain and performance bonus', icon: 'gift', color: 0xFFB7791F,
    defaultAccountId: 'nabil', recurring: false, expectedAmount: _r(120000), frequency: IncomeFrequency.yearly,
    expectedDay: 'Before Dashain', applicableDeductionIds: const ['tax'],
  ),
  const IncomeType(
    id: 'freelance', name: 'Freelance Income', description: 'Design and product consulting', icon: 'laptop',
    color: 0xFF1F4FC4, defaultAccountId: 'nabil', recurring: false, frequency: IncomeFrequency.irregular,
  ),
  const IncomeType(
    id: 'business', name: 'Business Income', icon: 'store', color: 0xFF7C3AED, defaultAccountId: 'nabil',
    recurring: false, frequency: IncomeFrequency.irregular, active: false,
  ),
  const IncomeType(
    id: 'rental', name: 'Rental Income', icon: 'key', color: 0xFF0E7490, defaultAccountId: 'nabil',
    recurring: true, frequency: IncomeFrequency.monthly, active: false,
  ),
  IncomeType(
    id: 'interest', name: 'Interest Income', description: 'Savings account and FD interest', icon: 'trend',
    color: 0xFF0B7A53, defaultAccountId: 'nic', recurring: true, expectedAmount: _r(1200),
    frequency: IncomeFrequency.monthly, expectedDay: 'Month end',
  ),
  const IncomeType(
    id: 'dividend', name: 'Dividend Income', description: 'Share dividends', icon: 'pie', color: 0xFFB42318,
    defaultAccountId: 'nabil', recurring: false, frequency: IncomeFrequency.yearly,
  ),
  const IncomeType(
    id: 'other_inc', name: 'Other Income', description: 'Gifts, cashback and anything else', icon: 'dots',
    color: 0xFF465365, defaultAccountId: 'nabil', recurring: false, frequency: IncomeFrequency.irregular,
  ),
];

ExpenseCategory _cat(String id, String name, String icon, num budget, {bool essential = false}) => ExpenseCategory(
      id: id,
      name: name,
      icon: icon,
      monthlyBudget: budget > 0 ? _r(budget) : null,
      essential: essential,
    );

ExpenseCategory _sub(String id, String name, String parent, String icon) =>
    ExpenseCategory(id: id, name: name, icon: icon, parentId: parent);

/// Budgets from spec §12. Subcategories (mockup `subs`) are child rows.
final List<ExpenseCategory> seedCategories = [
  _cat('housing', 'Housing & Rent', 'home', 22000, essential: true),
  _cat('groceries', 'Groceries', 'cart', 12000, essential: true),
  _cat('transport', 'Transport', 'car', 6000, essential: true),
  _cat('family', 'Family Support', 'heart', 15000, essential: true),
  _cat('utilities', 'Utilities', 'bolt', 5000, essential: true),
  _cat('education', 'Education', 'book', 3000),
  _cat('health', 'Healthcare', 'health', 3000, essential: true),
  _cat('subs', 'Subscriptions', 'play', 2000),
  _cat('fun', 'Entertainment', 'ticket', 5000),
  const ExpenseCategory(id: kLoanInterestCategoryId, name: 'Loan Interest', icon: 'percent', system: kLoanInterestCategoryId),
  _cat('charges', 'Bank Charges', 'bank', 500),
  _cat('other', 'Other Expenses', 'dots', 3000),
  _sub('housing_rent', 'Rent', 'housing', 'home'),
  _sub('housing_maint', 'Maintenance', 'housing', 'home'),
  _sub('transport_fuel', 'Fuel', 'transport', 'car'),
  _sub('transport_ride', 'Ride-hailing', 'transport', 'car'),
  _sub('utilities_power', 'Electricity', 'utilities', 'bolt'),
  _sub('utilities_net', 'Internet', 'utilities', 'bolt'),
  _sub('utilities_water', 'Water', 'utilities', 'bolt'),
  _sub('fun_dining', 'Dining out', 'fun', 'ticket'),
  _sub('fun_movies', 'Movies', 'fun', 'ticket'),
];

const List<LoanType> seedLoanTypes = [
  LoanType(id: 'home', name: 'Home Loan', description: 'Purchase or construction of a house', icon: 'home', defaultMethod: InterestMethod.reducing),
  LoanType(id: 'vehicle', name: 'Vehicle Loan', description: 'Car, scooter or motorbike financing', icon: 'car', defaultMethod: InterestMethod.reducing),
  LoanType(id: 'personal', name: 'Personal Loan', description: 'Unsecured bank or finance-company loans', icon: 'user', defaultMethod: InterestMethod.reducing),
  LoanType(id: 'education', name: 'Education Loan', description: 'Tuition and study abroad', icon: 'book', defaultMethod: InterestMethod.reducing),
  LoanType(id: 'business', name: 'Business Loan', description: 'Working capital or equipment', icon: 'store', defaultMethod: InterestMethod.reducing),
  LoanType(id: 'family', name: 'Credit from Family / Friends', description: 'Informal borrowing, often interest-free', icon: 'heart', defaultMethod: InterestMethod.none),
  LoanType(id: 'other_loan', name: 'Other Loan', description: 'Anything else you owe', icon: 'dots', defaultMethod: InterestMethod.flat),
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

final List<RecurringRule> seedRecurring = [
  _rec('r1', 'House rent', 22000, 'nabil', '2026-11-01', category: 'housing'),
  _rec('r2', 'Family support — Pokhara', 10000, 'nabil', '2026-11-04', category: 'family'),
  _rec('r3', 'WorldLink internet', 1695, 'esewa', '2026-11-13', category: 'utilities'),
  _rec('r4', 'Streaming subscription', 1499, 'cc', '2026-11-08', category: 'subs'),
  _rec('r5', 'Monthly salary', 92789, 'nabil', '2026-10-17', incomeType: 'salary'),
  _rec('r6', 'Health insurance premium', 14500, 'nabil', '2027-01-10',
      category: 'health', frequency: RecurringFrequency.yearly),
];

List<ConfigItem> _list(String key, List<(String, String, String)> rows, {Set<String> off = const {}}) => [
      for (final (i, (id, name, desc)) in rows.indexed)
        ConfigItem(id: id, listKey: key, name: name, description: desc, active: !off.contains(id), isDefault: i == 0),
    ];

/// Bank descriptions start with `Sender <ID>` so Add account can tell
/// whether a sender is already known.
final Map<String, List<ConfigItem>> seedConfig = {
  ConfigList.accountTypes: _list(ConfigList.accountTypes, [
    ('a1', 'Bank account', 'Liquid · counts toward available balance'),
    ('a2', 'Savings account', 'Reserved · excluded from available by default'),
    ('a3', 'Cash', 'Liquid'),
    ('a4', 'Digital wallet', 'Liquid · eSewa, Khalti, IME Pay'),
    ('a5', 'Fixed deposit', 'Locked until maturity'),
    ('a6', 'Credit card', 'Liability'),
    ('a7', 'CIT balance', 'Locked · retirement'),
    ('a8', 'SSF balance', 'Locked · retirement'),
    ('a9', 'Other asset', 'e.g. shares, gold — tracked manually'),
    ('a10', 'Other liability', 'Anything else you owe'),
  ]),
  ConfigList.contributionTypes: _list(ConfigList.contributionTypes, [
    ('c1', 'Social Security Fund (SSF)', 'Employee + employer % of basic salary'),
    ('c2', 'Citizen Investment Trust (CIT)', 'Voluntary retirement contribution'),
    ('c3', 'Provident fund', 'Employee + employer % of basic salary'),
    ('c4', 'Insurance premium', 'Life or health insurance via payroll'),
    ('c5', 'Custom deduction', 'Any other payroll deduction'),
  ], off: {'c3'}),
  ConfigList.classificationRules: _list(ConfigList.classificationRules, [
    ('k1', 'Remark contains “SAL” + credit', '→ Income · Monthly Salary'),
    ('k2', 'Destination is one of my accounts', '→ Transfer (never income or expense)'),
    ('k3', 'Remark contains “EMI” or “LOAN”', '→ Loan repayment, split principal / interest'),
    ('k4', 'Remark contains “CC PAYMENT”', '→ Credit card payment (no double counting)'),
    ('k5', 'Remark contains “REVERSED” or “FAILED”', '→ Reversal (not counted)'),
    ('k6', 'Merchant: Bhat-Bhateni, Big Mart', '→ Expense · Groceries'),
    ('k7', 'Same amount + account within 10 min', '→ Flag as possible duplicate'),
    ('k8', 'Low confidence', '→ Always ask; never auto-approve'),
  ]),
  ConfigList.banks: _list(ConfigList.banks, [
    ('b1', 'Nabil Bank', 'Sender NABIL_ALERT · A/C ##4821, card ##5512'),
    ('b2', 'NIC Asia Bank', 'Sender NIC_ASIA · A/C ##2290'),
    ('b3', 'Global IME Bank', 'Sender GIBL · A/C ##3307'),
    ('b4', 'Siddhartha Bank', 'Sender SBL_ALERT'),
    ('b5', 'eSewa', 'Sender eSewa · wallet notifications'),
    ('b6', 'Khalti', 'Sender Khalti · wallet notifications'),
    ('b7', 'IME Pay', 'Sender IMEPay · not linked'),
  ], off: {'b7'}),
};

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

/// History from the mockup. Already reflected in the seeded balances.
final List<Txn> seedTransactions = [
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

const List<AuditEntry> seedAudit = [
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
