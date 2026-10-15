import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/models.dart';

void main() {
  test('TxType wire names match spec §4', () {
    expect(TxType.values.map((t) => t.wire), [
      'expense', 'income', 'transfer', 'loan_repayment', 'cc_payment',
      'cash_withdrawal', 'refund', 'reversal', 'loan_disbursement', 'adjustment',
    ]);
    for (final t in TxType.values) {
      expect(TxType.fromWire(t.wire), t);
    }
  });

  test('AccountKind wire names match spec §4', () {
    expect(AccountKind.values.map((k) => k.wire), [
      'bank', 'savings', 'wallet', 'cash', 'credit_card', 'fixed_deposit', 'cit', 'ssf', 'other',
    ]);
    for (final k in AccountKind.values) {
      expect(AccountKind.fromWire(k.wire), k);
    }
  });

  test('LoanFrequency periods', () {
    expect(LoanFrequency.monthly.periodsPerYear, 12);
    expect(LoanFrequency.monthly.monthsPerPeriod, 1);
    expect(LoanFrequency.quarterly.periodsPerYear, 4);
    expect(LoanFrequency.quarterly.monthsPerPeriod, 3);
    expect(LoanFrequency.yearly.monthsPerPeriod, 12);
    expect(LoanFrequency.flexible.monthsPerPeriod, 1);
  });

  test('Account.copyWith changes only the given fields', () {
    const a = Account(
      id: 'khalti', name: 'Khalti Wallet', shortName: 'Khalti', group: AccountGroup.liquid,
      kind: AccountKind.wallet, smsSender: 'Khalti', openingBalance: 150000, balance: 215000,
    );
    final b = a.copyWith(balance: 100, autoUpdateFromSms: true);
    expect(b.balance, 100);
    expect(b.autoUpdateFromSms, isTrue);
    expect(b.smsSender, 'Khalti');
    expect(b.openingBalance, 150000);
    expect(a.autoUpdateFromSms, isFalse);
  });

  test('Txn defaults to posted manual entry', () {
    const t = Txn(id: 't1', date: '2026-10-14', time: '09:00', title: 'Big Mart',
        type: TxType.expense, accountId: 'esewa', amount: 218000);
    expect(t.isPosted, isTrue);
    expect(t.source, TxSource.manual);
  });

  test('Loan.copyWith', () {
    const l = Loan(id: 'L1', loanTypeId: 'vehicle', name: 'Scooter loan', lender: 'Global IME Bank',
        principal: 35000000, outstanding: 22864000, ratePct: 11.25, method: InterestMethod.reducing,
        installment: 1150100, frequency: LoanFrequency.monthly, nextDueDate: '2026-10-13');
    final m = l.copyWith(outstanding: 1, nextDueDate: '2026-11-13');
    expect(m.outstanding, 1);
    expect(m.nextDueDate, '2026-11-13');
    expect(m.ratePct, 11.25);
  });
}
