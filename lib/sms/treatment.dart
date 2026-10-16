import '../finance/finance.dart';
import 'sms_models.dart';

enum LineTone { neutral, positive, negative }

class AccountingLine {
  const AccountingLine(this.label, this.value, {this.tone = LineTone.neutral});
  final String label;
  final String value;
  final LineTone tone;
}

/// The "Proposed accounting" card on Review (spec §7): what confirming
/// would do to balances, spending and income, worded for a person.
class SmsTreatment {
  const SmsTreatment({required this.lines, required this.note, this.warning});
  final List<AccountingLine> lines;
  final String note;

  /// Something that must be fixed, or looks wrong, before confirming.
  final String? warning;
}

SmsTreatment treatSms(
  SmsMessage m, {
  required List<Account> accounts,
  required List<Loan> loans,
  required List<ExpenseCategory> categories,
  required List<IncomeType> incomeTypes,
  required Map<String, Paisa> spentThisMonth,
  required MoneyFormat money,
  required String monthName,
}) {
  String n(Paisa p) => money.npr(p);
  final amt = m.amount;
  final account = accounts.where((a) => a.id == m.accountId).firstOrNull;
  final name = account?.shortName ?? 'Account';
  final counter = accounts.where((a) => a.id == m.counterAccountId).firstOrNull;
  final category = categories.where((c) => c.id == m.categoryId).firstOrNull;
  final loan = loans.where((l) => l.id == m.loanId).firstOrNull;
  final lines = <AccountingLine>[];
  var note = '';
  String? warning;

  switch (m.type) {
    case TxType.expense:
      final cat = category?.name ?? 'Other';
      lines
        ..add(AccountingLine(name, '− ${n(amt)}'))
        ..add(AccountingLine('Expense · $cat', '+ ${n(amt)}', tone: LineTone.negative));
      final budget = category?.monthlyBudget ?? 0;
      final used = (spentThisMonth[m.categoryId] ?? 0) + amt;
      note = 'Counts toward $monthName spending.${budget > 0 ? ' $cat budget after saving: ${n(used)} of ${n(budget)}.' : ''}';
      if (m.direction == Direction.credit) warning = 'This message is a credit, but it is marked as an expense. Check the type.';
    case TxType.income:
      final it = incomeTypes.where((t) => t.id == m.incomeTypeId).firstOrNull;
      lines
        ..add(AccountingLine(name, '+ ${n(amt)}', tone: LineTone.positive))
        ..add(AccountingLine('Income · ${it?.name ?? 'Other income'}', n(amt), tone: LineTone.positive));
      note = m.incomeTypeId == 'salary'
          ? 'Recorded as take-home pay. Tax, SSF and CIT were already deducted by payroll — they are not deducted again.'
          : 'Counts toward $monthName income.';
      if (m.direction == Direction.debit) warning = 'This message is a debit, but it is marked as income. Check the type.';
    case TxType.transfer:
      final other = counter?.shortName ?? '—';
      if (m.direction == Direction.debit) {
        lines
          ..add(AccountingLine('From $name', '− ${n(amt)}'))
          ..add(AccountingLine('To $other', '+ ${n(amt)}'));
      } else {
        lines
          ..add(AccountingLine('From $other', '− ${n(amt)}'))
          ..add(AccountingLine('To $name', '+ ${n(amt)}'));
      }
      note = 'Moves money between your own accounts. Not counted as income or expense.';
      if (counter == null || counter.id == account?.id) warning = 'Choose the other account in Edit details.';
    case TxType.loanRepayment:
      lines.add(AccountingLine(name, '− ${n(amt)}'));
      if (loan == null) {
        warning = 'Pick which loan this repayment belongs to.';
      } else {
        final split = splitRepayment(loan, amt);
        lines
          ..add(AccountingLine('Principal · ${loan.name}', '− ${n(split.principal)} owed', tone: LineTone.positive))
          ..add(AccountingLine('Interest expense', n(split.interest), tone: LineTone.negative));
        final after = loan.outstanding - split.principal;
        note = 'Only the interest counts as an expense. Outstanding falls to ${n(after < 0 ? 0 : after)}.';
        if (amt > payoffAmount(loan)) warning = 'This is more than you owe on ${loan.name}. Check the amount.';
      }
    case TxType.ccPayment:
      lines
        ..add(AccountingLine(name, '− ${n(amt)}'))
        ..add(AccountingLine('${counter?.shortName ?? 'Credit card'} balance owed', '− ${n(amt)}', tone: LineTone.positive));
      note = 'Card purchases were recorded when you made them, so this payment is not counted as spending again.';
      if (counter == null) warning = 'Choose the credit card in Edit details.';
    case TxType.cashWithdrawal:
      lines
        ..add(AccountingLine(name, '− ${n(amt)}'))
        ..add(AccountingLine(counter?.shortName ?? 'Cash in hand', '+ ${n(amt)}'));
      note = 'Not an expense — record what you spend from cash separately.';
      if (counter == null) warning = 'Add a Cash account to record withdrawals.';
    case TxType.refund:
      final cat = category?.name ?? 'Other';
      lines
        ..add(AccountingLine(name, '+ ${n(amt)}', tone: LineTone.positive))
        ..add(AccountingLine('$cat spending', '− ${n(amt)}', tone: LineTone.positive));
      note = 'Reduces $cat spending for $monthName. Not counted as income.';
    case TxType.reversal:
      lines.add(AccountingLine(name, '${m.direction == Direction.debit ? '−' : '+'} ${n(amt)}'));
      note = 'The original payment failed or was reversed, so it is never counted as spending or income.';
    case TxType.loanDisbursement:
      lines
        ..add(AccountingLine(name, '+ ${n(amt)}'))
        ..add(AccountingLine('Liability · ${loan?.name ?? 'loan'}', '+ ${n(amt)} owed', tone: LineTone.negative));
      note = 'Borrowed money increases what you owe. It is not income.';
      if (loan == null) warning = 'Pick which loan this money came from.';
    case TxType.adjustment:
      lines.add(AccountingLine(name, n(amt)));
      note = 'A balance adjustment.';
  }
  if (account == null) warning = 'Pick the account this message is about in Edit details.';
  return SmsTreatment(lines: lines, note: note, warning: warning);
}
