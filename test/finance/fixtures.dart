import 'package:paisa/finance/ledger.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';

Account acct(String id, AccountGroup group, num rupees,
        {AccountKind kind = AccountKind.bank, String? sender, bool auto = false, num? limit}) =>
    Account(
      id: id,
      name: id,
      shortName: id,
      group: group,
      kind: kind,
      smsSender: sender,
      autoUpdateFromSms: auto,
      openingBalance: fromRupees(rupees),
      balance: fromRupees(rupees),
      creditLimit: limit == null ? null : fromRupees(limit),
    );

List<Account> seedAccounts() => [
      acct('nabil', AccountGroup.liquid, 142350),
      acct('gibl', AccountGroup.liquid, 24600),
      acct('esewa', AccountGroup.liquid, 8420, kind: AccountKind.wallet, sender: 'eSewa'),
      acct('khalti', AccountGroup.liquid, 2150, kind: AccountKind.wallet, sender: 'Khalti'),
      acct('cash', AccountGroup.liquid, 6500, kind: AccountKind.cash),
      acct('nic', AccountGroup.reserved, 385000, kind: AccountKind.savings),
      acct('fd', AccountGroup.locked, 500000, kind: AccountKind.fixedDeposit),
      acct('cit', AccountGroup.locked, 286400, kind: AccountKind.cit),
      acct('ssf', AccountGroup.locked, 194800, kind: AccountKind.ssf),
      acct('cc', AccountGroup.liability, 18640, kind: AccountKind.creditCard, limit: 150000),
    ];

List<Loan> seedLoans() => [
      Loan(id: 'L1', loanTypeId: 'vehicle', name: 'Scooter loan', lender: 'Global IME Bank',
          principal: fromRupees(350000), outstanding: fromRupees(228640), ratePct: 11.25,
          method: InterestMethod.reducing, installment: fromRupees(11501),
          frequency: LoanFrequency.monthly, nextDueDate: '2026-10-13', repaymentAccountId: 'gibl'),
      Loan(id: 'L2', loanTypeId: 'personal', name: 'Personal loan A', lender: 'NIC Asia Bank',
          principal: fromRupees(200000), outstanding: fromRupees(131450), ratePct: 13.5,
          method: InterestMethod.reducing, installment: fromRupees(6790),
          frequency: LoanFrequency.monthly, nextDueDate: '2026-10-20', repaymentAccountId: 'nabil'),
      Loan(id: 'L3', loanTypeId: 'personal', name: 'Personal loan B', lender: 'Siddhartha Bank',
          principal: fromRupees(100000), outstanding: fromRupees(54163), ratePct: 12,
          method: InterestMethod.flat, installment: fromRupees(5167),
          frequency: LoanFrequency.monthly, nextDueDate: '2026-11-05', repaymentAccountId: 'nabil'),
      Loan(id: 'L4', loanTypeId: 'family', name: 'Borrowed from Kiran', lender: 'Kiran',
          principal: fromRupees(50000), outstanding: fromRupees(30000), ratePct: null,
          method: InterestMethod.none, installment: fromRupees(5000),
          frequency: LoanFrequency.flexible, nextDueDate: '2026-10-01', repaymentAccountId: 'esewa'),
    ];

LedgerState seedLedger() => LedgerState.from(seedAccounts(), seedLoans());

int _next = 0;

Txn tx(
  TxType type,
  String accountId,
  num rupees, {
  String? to,
  Direction? dir,
  String? cat,
  String? incomeType,
  String? loanId,
  String? party,
  num? principal,
  num? interest,
  String date = '2026-10-14',
  TxStatus status = TxStatus.posted,
  TxSource source = TxSource.manual,
}) =>
    Txn(
      id: 't${_next++}',
      date: date,
      time: '09:00',
      title: type.wire,
      type: type,
      direction: dir,
      accountId: accountId,
      counterAccountId: to,
      categoryId: cat,
      incomeTypeId: incomeType,
      loanId: loanId,
      partyId: party,
      amount: fromRupees(rupees),
      principal: principal == null ? null : fromRupees(principal),
      interest: interest == null ? null : fromRupees(interest),
      status: status,
      source: source,
    );

/// Everything a transaction can change, for exact before/after comparison.
Map<String, Object?> snapshot(LedgerState s) => {
      for (final a in s.accounts.values) 'a:${a.id}': a.balance,
      for (final l in s.loans.values) 'l:${l.id}': '${l.outstanding}@${l.nextDueDate}',
    };
