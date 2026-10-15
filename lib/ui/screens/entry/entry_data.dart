import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';

/// What the Add income / Add expense forms need, loaded together.
class EntryData {
  const EntryData({
    required this.accounts,
    required this.incomeTypes,
    required this.categories,
    required this.month,
  });

  /// Non-archived accounts in display order.
  final List<Account> accounts;
  final List<IncomeType> incomeTypes;
  final List<ExpenseCategory> categories;

  /// This month's totals, for the budget hint.
  final MonthlyTotals month;

  /// Accounts offered for [groups], always including [preselected] (the
  /// account whose page opened the form) even if its group is not listed.
  List<Account> accountChoices(Set<AccountGroup> groups, String? preselected) =>
      accounts.where((a) => groups.contains(a.group) || a.id == preselected).toList();
}

final entryDataProvider = FutureProvider<EntryData>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  return EntryData(
    accounts: accounts.where((a) => !a.archived).toList(),
    incomeTypes: await ref.watch(incomeTypesProvider.future),
    categories: await ref.watch(categoriesProvider.future),
    month: await ref.watch(monthTotalsProvider.future),
  );
});

/// Shared validation message for amount fields.
const String kAmountError = 'Enter an amount greater than zero';

/// Paisa for a typed amount, or null if it is not a positive amount.
Paisa? positiveAmount(String text) {
  final p = parseNpr(text);
  return p == null || p <= 0 ? null : p;
}
