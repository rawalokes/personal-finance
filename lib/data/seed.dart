import '../finance/finance.dart';
import 'db/database.dart';
import 'mappers.dart';
import 'records.dart';

/// Bump when the defaults change in a way existing installs should NOT get
/// (they keep their data); new installs always get the latest defaults.
const String kSeedVersion = '1';
const String kSeedVersionKey = 'seed_version';

/// First launch only: the default lists the app needs (income types, expense
/// categories, loan types, account types, contribution types, SMS
/// classification rules, banks & wallets). No accounts, money, loans or
/// history: a clean install starts empty. Returns true if it seeded.
Future<bool> seedIfNeeded(AppDatabase db) async {
  final marker = await (db.select(db.appMeta)..where((m) => m.key.equals(kSeedVersionKey))).getSingleOrNull();
  if (marker != null) return false;
  await db.transaction(() async {
    await db.batch((b) {
      b.insertAll(db.incomeTypes, [for (final (i, t) in seedIncomeTypes.indexed) incomeTypeToCompanion(t, sortOrder: i)]);
      b.insertAll(db.expenseCategories, [for (final (i, c) in seedCategories.indexed) categoryToCompanion(c, sortOrder: i)]);
      b.insertAll(db.loanTypes, [for (final (i, t) in seedLoanTypes.indexed) loanTypeToCompanion(t, sortOrder: i)]);
      b.insertAll(db.configItems, [
        for (final list in seedConfig.values)
          for (final (i, c) in list.indexed) configItemToCompanion(c, sortOrder: i),
      ]);
      b.insert(db.appMeta, AppMetaCompanion.insert(key: kSeedVersionKey, value: kSeedVersion));
    });
  });
  return true;
}

/// Spec §12 income types, without amounts or accounts (the user has none yet).
const List<IncomeType> seedIncomeTypes = [
  IncomeType(
    id: 'salary', name: 'Monthly Salary', description: 'Take-home pay from your employer', icon: 'brief',
    color: 0xFF0B7A53, recurring: true, frequency: IncomeFrequency.monthly, expectedDay: 'End of BS month',
    applicableDeductionIds: ['tax', 'ssf', 'cit', 'insurance'],
  ),
  IncomeType(
    id: 'bonus', name: 'Bonus', description: 'Dashain and performance bonus', icon: 'gift', color: 0xFFB7791F,
    recurring: false, frequency: IncomeFrequency.yearly, expectedDay: 'Before Dashain', applicableDeductionIds: ['tax'],
  ),
  IncomeType(
    id: 'freelance', name: 'Freelance Income', description: 'Freelance and contract work', icon: 'laptop',
    color: 0xFF1F4FC4, recurring: false, frequency: IncomeFrequency.irregular,
  ),
  IncomeType(
    id: 'business', name: 'Business Income', icon: 'store', color: 0xFF7C3AED, recurring: false,
    frequency: IncomeFrequency.irregular, active: false,
  ),
  IncomeType(
    id: 'rental', name: 'Rental Income', icon: 'key', color: 0xFF0E7490, recurring: true,
    frequency: IncomeFrequency.monthly, active: false,
  ),
  IncomeType(
    id: 'interest', name: 'Interest Income', description: 'Savings account and FD interest', icon: 'trend',
    color: 0xFF0B7A53, recurring: true, frequency: IncomeFrequency.monthly, expectedDay: 'Month end',
  ),
  IncomeType(
    id: 'dividend', name: 'Dividend Income', description: 'Share dividends', icon: 'pie', color: 0xFFB42318,
    recurring: false, frequency: IncomeFrequency.yearly,
  ),
  IncomeType(
    id: 'other_inc', name: 'Other Income', description: 'Gifts, cashback and anything else', icon: 'dots',
    color: 0xFF465365, recurring: false, frequency: IncomeFrequency.irregular,
  ),
];

ExpenseCategory _cat(String id, String name, String icon, {bool essential = false}) =>
    ExpenseCategory(id: id, name: name, icon: icon, essential: essential);

ExpenseCategory _sub(String id, String name, String parent, String icon) =>
    ExpenseCategory(id: id, name: name, icon: icon, parentId: parent);

/// Spec §12 categories, without budgets: the user sets their own. Subcategories
/// (mockup `subs`) are child rows.
final List<ExpenseCategory> seedCategories = [
  _cat('housing', 'Housing & Rent', 'home', essential: true),
  _cat('groceries', 'Groceries', 'cart', essential: true),
  _cat('transport', 'Transport', 'car', essential: true),
  _cat('family', 'Family Support', 'heart', essential: true),
  _cat('utilities', 'Utilities', 'bolt', essential: true),
  _cat('education', 'Education', 'book'),
  _cat('health', 'Healthcare', 'health', essential: true),
  _cat('subs', 'Subscriptions', 'play'),
  _cat('fun', 'Entertainment', 'ticket'),
  const ExpenseCategory(id: kLoanInterestCategoryId, name: 'Loan Interest', icon: 'percent', system: kLoanInterestCategoryId),
  _cat('charges', 'Bank Charges', 'bank'),
  _cat('other', 'Other Expenses', 'dots'),
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
    ('b1', 'Nabil Bank', 'Sender NABIL_ALERT'),
    ('b2', 'NIC Asia Bank', 'Sender NIC_ASIA'),
    ('b3', 'Global IME Bank', 'Sender GIBL'),
    ('b4', 'Siddhartha Bank', 'Sender SBL_ALERT'),
    ('b5', 'eSewa', 'Sender eSewa · wallet notifications'),
    ('b6', 'Khalti', 'Sender Khalti · wallet notifications'),
    ('b7', 'IME Pay', 'Sender IMEPay · not linked'),
  ], off: {'b7'}),
};
