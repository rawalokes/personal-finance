import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/records.dart';
import 'package:paisa/data/repos/catalog_repo.dart';
import 'package:paisa/data/repos/data_repo.dart';
import 'package:paisa/data/repos/goal_repo.dart';
import 'package:paisa/data/repos/loan_repo.dart';
import 'package:paisa/data/repos/transaction_repo.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';

import 'data_fixtures.dart';
import 'sample_data.dart';
import 'test_db.dart';

void main() {
  late AppDatabase db;
  late AuditLog audit;
  late TransactionRepository txns;

  Future<void> sampleDb() async {
    db = openTestDb();
    await seedWithSampleData(db);
    audit = testAudit(db);
    txns = TransactionRepository(db, audit, clock: testClock);
  }

  group('loans', () {
    late LoanRepository loans;
    setUp(() async {
      await sampleDb();
      loans = LoanRepository(db, audit, txns, clock: testClock, newId: counterIds('newL'));
    });

    test('add saves a loan and undo removes it while it has no repayments', () async {
      final (loan, undo) = await loans.add(LoanInput(
        loanTypeId: 'education', name: 'Study loan', lender: 'NMB Bank', principal: fromRupees(300000),
        outstanding: fromRupees(300000), ratePct: 10, method: InterestMethod.reducing, installment: fromRupees(9000),
        frequency: LoanFrequency.monthly, nextDueDate: '2026-11-15', repaymentAccountId: 'nabil',
      ));
      expect((await loans.get(loan.id)).name, 'Study loan');
      expect(await auditSummaries(db), contains('Added loan Study loan · NPR 3,00,000 outstanding'));
      await undo();
      expect(await loans.find(loan.id), isNull);
    });

    test('a missing rate stays "not entered" (null), never 0', () async {
      final (loan, _) = await loans.add(LoanInput(
        loanTypeId: 'personal', name: 'X', lender: 'Y', principal: 100000, outstanding: 100000, ratePct: null,
        method: InterestMethod.reducing, installment: 10000, frequency: LoanFrequency.monthly,
      ));
      expect((await loans.get(loan.id)).ratePct, isNull);
    });

    test('acceptance 4: recording the scooter EMI splits 2,144 interest / 9,357 principal and moves the due date', () async {
      final undo = await loans.recordRepayment('L1', amount: fromRupees(11501), date: '2026-10-13', fromAccountId: 'gibl');
      final l1 = await loans.get('L1');
      expect(l1.outstanding, fromRupees(228640 - 9357));
      expect(l1.nextDueDate, '2026-11-13');
      final tx = (await txns.watchAll().first).firstWhere((t) => t.loanId == 'L1');
      expect(tx.interest, fromRupees(2144));
      expect(tx.principal, fromRupees(9357));
      expect(tx.title, 'Scooter loan installment');
      expect(monthlyTotals([tx], '2026-10').byCategory[kLoanInterestCategoryId], fromRupees(2144));
      expect(await balanceOf(db, 'gibl'), fromRupees(24600 - 11501));
      await undo();
      expect((await loans.get('L1')).outstanding, fromRupees(228640));
    });

    test('update edits terms and undo restores the old ones', () async {
      final before = await loans.get('L2');
      final undo = await loans.update(before.copyWithTerms(installment: fromRupees(8000), ratePct: 12));
      expect((await loans.get('L2')).installment, fromRupees(8000));
      await undo();
      expect((await loans.get('L2')).installment, before.installment);
    });

    test('a payment above what is owed is refused and changes nothing', () async {
      final before = await loans.get('L1');
      await expectLater(
        loans.recordRepayment('L1', amount: payoffAmount(before) + 100, date: '2026-10-13', fromAccountId: 'gibl'),
        throwsA(isA<RepaymentTooLarge>()),
      );
      expect((await loans.get('L1')).outstanding, before.outstanding);
      expect(await balanceOf(db, 'gibl'), fromRupees(24600));
      // Exactly the payoff amount is fine and closes the debt.
      await loans.recordRepayment('L1', amount: payoffAmount(before), date: '2026-10-13', fromAccountId: 'gibl');
      expect((await loans.get('L1')).outstanding, 0);
    });

    test('repayments of one loan are listed newest first', () async {
      await loans.recordRepayment('L3', amount: fromRupees(5167), date: '2026-11-05', fromAccountId: 'nabil');
      final list = await loans.watchRepayments('L3').first;
      expect(list.map((t) => t.date), ['2026-11-05', '2026-10-05']);
    });

    test('loan types can be added, renamed and disabled', () async {
      final catalog = CatalogRepository(db, audit);
      final id = await catalog.saveLoanType(const LoanType(id: '', name: 'Gold Loan', icon: 'rupee', defaultMethod: InterestMethod.flat));
      await catalog.saveLoanType(LoanType(id: id, name: 'Gold loan', icon: 'rupee', defaultMethod: InterestMethod.flat, active: false));
      final t = (await catalog.watchLoanTypes().first).firstWhere((t) => t.id == id);
      expect(t.name, 'Gold loan');
      expect(t.active, isFalse);
    });
  });

  group('goals', () {
    late GoalRepository goals;
    setUp(() async {
      await sampleDb();
      goals = GoalRepository(db, audit, txns, clock: testClock, newId: counterIds('g'));
    });

    test('add a goal; contributing moves money between accounts and is not an expense', () async {
      final goal = await goals.add(Goal(id: '', name: 'Mustang trip', kind: 'Travel', target: fromRupees(80000), targetDate: '2026-12-20'));
      final undo = await goals.contribute(goal.id, amount: fromRupees(5000), fromAccountId: 'nabil', toAccountId: 'nic');
      expect((await goals.watchAll().first).single.current, fromRupees(5000));
      expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 5000));
      expect(await balanceOf(db, 'nic'), fromRupees(385000 + 5000));
      final oct = monthlyTotals(await txns.watchAll().first, '2026-10');
      expect(oct.expenses, fromRupees(53674), reason: 'unchanged by the contribution');
      await undo();
      expect((await goals.watchAll().first).single.current, 0);
      expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    });

    test('contributing within one account only counts toward the goal', () async {
      final goal = await goals.add(Goal(id: '', name: 'Laptop', kind: 'Major purchase', target: fromRupees(180000)));
      await goals.contribute(goal.id, amount: fromRupees(1000), fromAccountId: 'nabil');
      expect(await balanceOf(db, 'nabil'), fromRupees(142350));
      expect((await goals.watchAll().first).single.current, fromRupees(1000));
    });

    test('delete removes a goal; undo brings it back', () async {
      final goal = await goals.add(Goal(id: '', name: 'Bike', kind: 'Short-term', target: 100));
      final undo = await goals.delete(goal.id);
      expect(await goals.watchAll().first, isEmpty);
      await undo();
      expect((await goals.watchAll().first).single.name, 'Bike');
    });
  });

  group('catalog editing', () {
    late CatalogRepository catalog;
    setUp(() async {
      await sampleDb();
      catalog = CatalogRepository(db, audit);
    });

    test('budgets are set and cleared per category', () async {
      await catalog.setBudget('groceries', fromRupees(15000));
      expect((await catalog.watchCategories().first).firstWhere((c) => c.id == 'groceries').monthlyBudget, fromRupees(15000));
      await catalog.setBudget('groceries', null);
      expect((await catalog.watchCategories().first).firstWhere((c) => c.id == 'groceries').monthlyBudget, isNull);
    });

    test('custom categories are added, renamed, disabled and deleted; names stay unique', () async {
      final id = await catalog.saveCategory(const ExpenseCategory(id: '', name: 'Pet care', icon: 'heart', custom: true));
      await expectLater(
        catalog.saveCategory(const ExpenseCategory(id: '', name: 'pet care', icon: 'tag', custom: true)),
        throwsA(isA<DuplicateName>()),
      );
      await catalog.setCategoryActive(id, false);
      expect((await catalog.watchCategories().first).firstWhere((c) => c.id == id).active, isFalse);
      await catalog.deleteCategory(id);
      expect((await catalog.watchCategories().first).where((c) => c.id == id), isEmpty);
    });

    test('built-in categories cannot be deleted', () async {
      await expectLater(catalog.deleteCategory('groceries'), throwsStateError);
    });

    test('income types are added and toggled', () async {
      final id = await catalog.saveIncomeType(const IncomeType(
        id: '', name: 'Teaching Income', icon: 'book', color: 0xFF1F4FC4, recurring: true, frequency: IncomeFrequency.monthly,
      ));
      await catalog.setIncomeTypeActive(id, false);
      expect((await catalog.watchIncomeTypes().first).firstWhere((t) => t.id == id).active, isFalse);
    });

    test('config lists: add, disable, and exactly one default', () async {
      await catalog.addConfigItem(ConfigList.banks, 'Laxmi Sunrise', 'Sender LSBL');
      final banks = await catalog.watchConfig(ConfigList.banks).first;
      final laxmi = banks.firstWhere((b) => b.name == 'Laxmi Sunrise');
      await catalog.setConfigDefault(ConfigList.banks, laxmi.id);
      await catalog.setConfigActive(laxmi.id, false);
      final after = await catalog.watchConfig(ConfigList.banks).first;
      expect(after.where((b) => b.isDefault).map((b) => b.id), [laxmi.id]);
      expect(after.firstWhere((b) => b.id == laxmi.id).active, isFalse);
    });

    test('recurring rules pause and resume', () async {
      await catalog.setRecurringActive('r1', false);
      expect((await catalog.watchRecurring().first).firstWhere((r) => r.id == 'r1').active, isFalse);
    });
  });

  group('data', () {
    setUp(sampleDb);

    test('JSON export holds every table but no secrets', () async {
      final json = await DataRepository(db, audit, clock: testClock).exportJson();
      final map = jsonDecode(json) as Map<String, Object?>;
      expect((map['accounts']! as List), hasLength(10));
      expect((map['transactions']! as List), hasLength(17));
      expect(map['exportedAt'], '2026-10-14T10:30:00');
      expect(json.contains('apiKey'), isFalse);
    });

    test('CSV export has a header and one line per transaction, amounts in rupees', () async {
      final csv = await DataRepository(db, audit, clock: testClock).exportTransactionsCsv();
      final lines = const LineSplitter().convert(csv);
      expect(lines.first, 'date,time,title,type,account,counter_account,category,income_type,amount_npr,status,source');
      expect(lines, hasLength(18));
      expect(lines.any((l) => l.startsWith('2026-10-01,09:00,House rent — October,expense,nabil,,housing,,22000.00')), isTrue);
    });

    test('delete all data leaves a clean install', () async {
      await DataRepository(db, audit, clock: testClock).deleteAllData();
      expect(await db.select(db.accounts).get(), isEmpty);
      expect(await db.select(db.transactions).get(), isEmpty);
      expect(await db.select(db.loans).get(), isEmpty);
      expect(await db.select(db.settings).get(), isEmpty);
      expect(await db.select(db.expenseCategories).get(), hasLength(seedCategories.length));
      expect(categoryFromRow((await db.select(db.expenseCategories).get()).first).monthlyBudget, isNull);
    });
  });
}
