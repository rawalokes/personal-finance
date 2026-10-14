import 'dates.dart';
import 'money.dart';

enum AccountGroup { liquid, reserved, locked, liability }

enum AccountKind {
  bank('bank'),
  savings('savings'),
  wallet('wallet'),
  cash('cash'),
  creditCard('credit_card'),
  fixedDeposit('fixed_deposit'),
  cit('cit'),
  ssf('ssf'),
  other('other');

  const AccountKind(this.wire);
  final String wire;
  static AccountKind fromWire(String w) => values.firstWhere((k) => k.wire == w);
}

enum TxType {
  expense('expense'),
  income('income'),
  transfer('transfer'),
  loanRepayment('loan_repayment'),
  ccPayment('cc_payment'),
  cashWithdrawal('cash_withdrawal'),
  refund('refund'),
  reversal('reversal'),
  loanDisbursement('loan_disbursement'),
  adjustment('adjustment');

  const TxType(this.wire);
  final String wire;
  static TxType fromWire(String w) => values.firstWhere((t) => t.wire == w);
}

enum Direction { debit, credit }

enum TxStatus { posted, pending }

enum TxSource { manual, sms, import, api }

enum SmsConfidence { high, medium, low }

enum InterestMethod { reducing, flat, none }

enum LoanFrequency {
  monthly(12, 1),
  quarterly(4, 3),
  yearly(1, 12),
  flexible(12, 1);

  const LoanFrequency(this.periodsPerYear, this.monthsPerPeriod);
  final int periodsPerYear;
  final int monthsPerPeriod;
}

/// Category id of the system "Loan Interest" expense category.
const String kLoanInterestCategoryId = 'loan_interest';

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.shortName,
    this.institution,
    this.accountTypeId,
    required this.group,
    required this.kind,
    this.maskedNumber,
    this.smsSender,
    this.autoUpdateFromSms = false,
    required this.openingBalance,
    required this.balance,
    this.creditLimit,
    this.statementDueDate,
    this.note,
    this.archived = false,
    this.lastReconciled,
  });

  final String id;
  final String name;
  final String shortName;
  final String? institution;
  final String? accountTypeId;
  final AccountGroup group;
  final AccountKind kind;

  /// Last 4 digits only.
  final String? maskedNumber;

  /// SMS sender ID used to match messages to this account, e.g. 'eSewa', 'NABIL_ALERT'.
  final String? smsSender;

  /// Confident Cr/Dr SMS update the balance without review.
  final bool autoUpdateFromSms;
  final Paisa openingBalance;

  /// Derived from opening balance + transactions; cached here.
  /// For a liability this is the amount owed (positive = debt).
  final Paisa balance;
  final Paisa? creditLimit;
  final IsoDate? statementDueDate;
  final String? note;
  final bool archived;
  final IsoDate? lastReconciled;

  Account copyWith({
    Paisa? balance,
    bool? autoUpdateFromSms,
    bool? archived,
    IsoDate? lastReconciled,
    String? smsSender,
  }) =>
      Account(
        id: id,
        name: name,
        shortName: shortName,
        institution: institution,
        accountTypeId: accountTypeId,
        group: group,
        kind: kind,
        maskedNumber: maskedNumber,
        smsSender: smsSender ?? this.smsSender,
        autoUpdateFromSms: autoUpdateFromSms ?? this.autoUpdateFromSms,
        openingBalance: openingBalance,
        balance: balance ?? this.balance,
        creditLimit: creditLimit,
        statementDueDate: statementDueDate,
        note: note,
        archived: archived ?? this.archived,
        lastReconciled: lastReconciled ?? this.lastReconciled,
      );
}

/// A money movement. The spec calls this `Transaction`.
class Txn {
  const Txn({
    required this.id,
    required this.date,
    required this.time,
    required this.title,
    required this.type,
    this.direction,
    required this.accountId,
    this.counterAccountId,
    this.categoryId,
    this.incomeTypeId,
    this.loanId,
    required this.amount,
    this.principal,
    this.interest,
    this.status = TxStatus.posted,
    this.source = TxSource.manual,
    this.smsId,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final IsoDate date;

  /// 'HH:mm'
  final String time;
  final String title;
  final TxType type;

  /// Which way money moved on [accountId], as the SMS reported it.
  final Direction? direction;
  final String accountId;

  /// The other own account for transfers, cash withdrawals and card payments.
  final String? counterAccountId;
  final String? categoryId;
  final String? incomeTypeId;
  final String? loanId;

  /// Always positive, except `adjustment`, which carries the signed difference.
  final Paisa amount;
  final Paisa? principal;
  final Paisa? interest;
  final TxStatus status;
  final TxSource source;
  final String? smsId;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  bool get isPosted => status == TxStatus.posted;
}

class Loan {
  const Loan({
    required this.id,
    required this.loanTypeId,
    required this.name,
    required this.lender,
    required this.principal,
    required this.outstanding,
    required this.ratePct,
    required this.method,
    required this.installment,
    required this.frequency,
    this.startDate,
    this.maturityDate,
    this.nextDueDate,
    this.repaymentAccountId,
    this.feesAndPrepayment,
    this.closed = false,
  });

  final String id;
  final String loanTypeId;
  final String name;
  final String lender;
  final Paisa principal;
  final Paisa outstanding;

  /// Annual %, or null when the user has not entered it ("Not entered").
  final double? ratePct;
  final InterestMethod method;
  final Paisa installment;
  final LoanFrequency frequency;
  final IsoDate? startDate;
  final IsoDate? maturityDate;
  final IsoDate? nextDueDate;
  final String? repaymentAccountId;
  final String? feesAndPrepayment;
  final bool closed;

  Loan copyWith({Paisa? outstanding, IsoDate? nextDueDate, bool? closed}) => Loan(
        id: id,
        loanTypeId: loanTypeId,
        name: name,
        lender: lender,
        principal: principal,
        outstanding: outstanding ?? this.outstanding,
        ratePct: ratePct,
        method: method,
        installment: installment,
        frequency: frequency,
        startDate: startDate,
        maturityDate: maturityDate,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        repaymentAccountId: repaymentAccountId,
        feesAndPrepayment: feesAndPrepayment,
        closed: closed ?? this.closed,
      );
}
