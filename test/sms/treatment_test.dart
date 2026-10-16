import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/sms/sms_models.dart';
import 'package:paisa/sms/treatment.dart';

import '../data/sample_data.dart';

SmsMessage _msg({
  TxType type = TxType.expense,
  Direction direction = Direction.debit,
  num amount = 2450,
  String? categoryId = 'groceries',
  String? incomeTypeId,
  String? counter,
  String? loanId,
}) =>
    SmsMessage(
      id: 's1', sender: 'NABIL_ALERT', receivedAt: '2026-10-14T08:41:00', maskedBody: '', bodyHash: 'h',
      institution: 'Nabil Bank', accountId: 'nabil', direction: direction, amount: fromRupees(amount),
      merchant: 'Bhat-Bhateni', date: '2026-10-14', time: '08:41', type: type, categoryId: categoryId,
      incomeTypeId: incomeTypeId, counterAccountId: counter, loanId: loanId, confidence: SmsConfidence.high, reason: '',
    );

SmsTreatment treat(SmsMessage m, {Map<String, Paisa> spent = const {}}) => treatSms(
      m,
      accounts: sampleAccounts,
      loans: sampleLoans,
      categories: [
        ExpenseCategory(id: 'groceries', name: 'Groceries', icon: 'cart', essential: true, monthlyBudget: fromRupees(12000)),
        ...seedCategories.where((c) => c.id != 'groceries'),
      ],
      incomeTypes: seedIncomeTypes,
      spentThisMonth: spent,
      money: const MoneyFormat(),
      monthName: 'October',
    );

void main() {
  test('expense: account down, category up, budget after saving', () {
    final t = treat(_msg(), spent: {'groceries': fromRupees(9000)});
    expect(t.lines.map((l) => (l.label, l.value)), [
      ('Nabil ••4821', '− NPR 2,450'),
      ('Expense · Groceries', '+ NPR 2,450'),
    ]);
    expect(t.lines.last.tone, LineTone.negative);
    expect(t.note, 'Counts toward October spending. Groceries budget after saving: NPR 11,450 of NPR 12,000.');
    expect(t.warning, isNull);
  });

  test('a credit marked as an expense warns', () {
    expect(treat(_msg(direction: Direction.credit)).warning, contains('credit'));
  });

  test('salary income: take-home, deductions not taken again', () {
    final t = treat(_msg(type: TxType.income, direction: Direction.credit, amount: 92789, categoryId: null, incomeTypeId: 'salary'));
    expect(t.lines.first.value, '+ NPR 92,789');
    expect(t.lines.first.tone, LineTone.positive);
    expect(t.lines.last.label, 'Income · Monthly Salary');
    expect(t.note, contains('take-home pay'));
  });

  test('transfer without the other account warns; with it, both sides show', () {
    expect(treat(_msg(type: TxType.transfer, categoryId: null)).warning, contains('other account'));
    final t = treat(_msg(type: TxType.transfer, categoryId: null, counter: 'nic'));
    expect(t.lines.map((l) => l.label), ['From Nabil ••4821', 'To NIC Asia ••2290']);
    expect(t.note, contains('Not counted as income or expense'));
  });

  test('loan repayment: principal and interest split, outstanding after', () {
    final t = treat(_msg(type: TxType.loanRepayment, amount: 11501, categoryId: null, loanId: 'L1'));
    expect(t.lines.map((l) => l.label), ['Nabil ••4821', 'Principal · Scooter loan', 'Interest expense']);
    expect(t.lines[2].value, 'NPR 2,144');
    expect(t.note, 'Only the interest counts as an expense. Outstanding falls to NPR 2,19,283.');
  });

  test('loan repayment without a loan, reversal and disbursement notes', () {
    expect(treat(_msg(type: TxType.loanRepayment, categoryId: null)).warning, contains('loan'));
    expect(treat(_msg(type: TxType.reversal, direction: Direction.credit, categoryId: null)).note, contains('never counted'));
    final d = treat(_msg(type: TxType.loanDisbursement, direction: Direction.credit, categoryId: null, loanId: 'L2'));
    expect(d.note, contains('not income'));
    expect(d.lines.last.tone, LineTone.negative);
  });

  test('no matching account: asks for one', () {
    final m = SmsMessage(
      id: 's', sender: 'X', receivedAt: '', maskedBody: '', bodyHash: '', institution: 'Bank', direction: Direction.debit,
      amount: 100, merchant: 'M', date: '2026-10-14', time: '08:00', type: TxType.expense, categoryId: 'other',
      confidence: SmsConfidence.low, reason: '',
    );
    expect(treat(m).warning, contains('account'));
  });
}
