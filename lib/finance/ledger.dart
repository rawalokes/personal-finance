import 'dates.dart';
import 'models.dart';
import 'money.dart';

class LedgerError implements Exception {
  LedgerError(this.message);
  final String message;
  @override
  String toString() => 'LedgerError: $message';
}

/// Account balances and loan outstandings that transactions change.
class LedgerState {
  const LedgerState({required this.accounts, required this.loans});

  factory LedgerState.from(Iterable<Account> accounts, Iterable<Loan> loans) => LedgerState(
        accounts: {for (final a in accounts) a.id: a},
        loans: {for (final l in loans) l.id: l},
      );

  final Map<String, Account> accounts;
  final Map<String, Loan> loans;

  Paisa balanceOf(String accountId) => accounts[accountId]!.balance;
  Paisa outstandingOf(String loanId) => loans[loanId]!.outstanding;
}

/// Applies [tx] (sign 1) or reverses it (sign -1). Pure: returns a new state.
/// Nothing is clamped, so reverting always restores the exact previous state.
LedgerState applyTransaction(LedgerState state, Txn tx, {int sign = 1}) {
  if (sign != 1 && sign != -1) {
    throw ArgumentError.value(sign, 'sign', 'must be 1 or -1');
  }
  if (tx.status == TxStatus.pending) return state;
  final validAmount = tx.type == TxType.adjustment ? tx.amount != 0 : tx.amount > 0;
  if (!validAmount) throw LedgerError('Amount must be more than zero (${tx.id})');

  final accounts = Map<String, Account>.of(state.accounts);
  final loans = Map<String, Loan>.of(state.loans);
  final amt = tx.amount * sign;

  /// Money in: an asset's balance rises, a liability's debt falls.
  void moneyIn(String accountId, Paisa value) {
    final a = accounts[accountId];
    if (a == null) throw LedgerError('Unknown account $accountId (${tx.id})');
    final delta = a.group == AccountGroup.liability ? -value : value;
    accounts[accountId] = a.copyWith(balance: a.balance + delta);
  }

  String counter() {
    final id = tx.counterAccountId;
    if (id == null) throw LedgerError('${tx.type.wire} ${tx.id} needs the other account');
    if (id == tx.accountId) throw LedgerError('${tx.type.wire} ${tx.id} cannot use one account twice');
    return id;
  }

  Loan loan() {
    final id = tx.loanId;
    final l = id == null ? null : loans[id];
    if (l == null) throw LedgerError('${tx.type.wire} ${tx.id} needs a known loan');
    return l;
  }

  switch (tx.type) {
    case TxType.expense:
      moneyIn(tx.accountId, -amt);
    case TxType.income || TxType.refund || TxType.adjustment:
      moneyIn(tx.accountId, amt);
    case TxType.reversal:
      moneyIn(tx.accountId, tx.direction == Direction.debit ? -amt : amt);
    case TxType.transfer || TxType.cashWithdrawal:
      {
        final other = counter();
        final intoThisAccount = tx.direction == Direction.credit;
        moneyIn(tx.accountId, intoThisAccount ? amt : -amt);
        moneyIn(other, intoThisAccount ? -amt : amt);
      }
    case TxType.ccPayment:
      {
        final card = counter();
        moneyIn(tx.accountId, -amt);
        moneyIn(card, amt);
      }
    case TxType.loanRepayment:
      {
        final l = loan();
        moneyIn(tx.accountId, -amt);
        final principal = (tx.principal ?? tx.amount) * sign;
        final due = l.nextDueDate;
        loans[l.id] = l.copyWith(
          outstanding: l.outstanding - principal,
          nextDueDate: due == null ? null : addMonths(due, sign * l.frequency.monthsPerPeriod),
        );
      }
    case TxType.loanDisbursement:
      {
        final l = loan();
        moneyIn(tx.accountId, amt);
        loans[l.id] = l.copyWith(outstanding: l.outstanding + amt);
      }
  }
  return LedgerState(accounts: accounts, loans: loans);
}

LedgerState revertTransaction(LedgerState state, Txn tx) => applyTransaction(state, tx, sign: -1);

LedgerState applyAll(LedgerState state, Iterable<Txn> txs) =>
    txs.fold(state, (s, t) => applyTransaction(s, t));
