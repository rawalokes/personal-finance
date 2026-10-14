import 'models.dart';
import 'money.dart';

class BalanceSummary {
  const BalanceSummary({
    required this.liquid,
    required this.reserved,
    required this.locked,
    required this.creditCards,
    required this.loans,
  });

  final Paisa liquid;
  final Paisa reserved;
  final Paisa locked;
  final Paisa creditCards;
  final Paisa loans;

  Paisa get assets => liquid + reserved + locked;
  Paisa get liabilities => creditCards + loans;
  Paisa get netWorth => assets - liabilities;
  Paisa get availableToSpend => liquid;
}

BalanceSummary summarizeBalances(Iterable<Account> accounts, Iterable<Loan> loans) {
  Paisa sum(AccountGroup g) =>
      accounts.where((a) => !a.archived && a.group == g).fold(0, (t, a) => t + a.balance);
  return BalanceSummary(
    liquid: sum(AccountGroup.liquid),
    reserved: sum(AccountGroup.reserved),
    locked: sum(AccountGroup.locked),
    creditCards: sum(AccountGroup.liability),
    loans: loans.where((l) => !l.closed).fold(0, (t, l) => t + l.outstanding),
  );
}
