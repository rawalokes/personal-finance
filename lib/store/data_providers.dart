import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/audit_log.dart';
import '../data/clock.dart';
import '../data/db/database.dart';
import '../data/records.dart';
import '../data/repos/account_repo.dart';
import '../data/repos/catalog_repo.dart';
import '../data/repos/transaction_repo.dart';
import '../finance/finance.dart';

/// Opened in main.dart (and in tests) and passed in with an override.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Override databaseProvider with an opened AppDatabase'),
);

/// "Today" for the whole app (roadmap decision). Tests fix it at 2026-10-14.
final clockProvider = Provider<Clock>((ref) => systemClock);

final idGenProvider = Provider<IdGen>((ref) => const Uuid().v4);

final auditLogProvider = Provider<AuditLog>(
  (ref) => AuditLog(ref.watch(databaseProvider), clock: ref.watch(clockProvider), newId: ref.watch(idGenProvider)),
);

final transactionRepoProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(databaseProvider), ref.watch(auditLogProvider), clock: ref.watch(clockProvider)),
);

final accountRepoProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(
    ref.watch(databaseProvider),
    ref.watch(auditLogProvider),
    ref.watch(transactionRepoProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGenProvider),
  ),
);

final catalogRepoProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(databaseProvider), ref.watch(auditLogProvider)),
);

/// Every account, archived included, in display order.
final accountsProvider = StreamProvider<List<Account>>((ref) => ref.watch(accountRepoProvider).watchAll());

/// Every transaction, newest first.
final transactionsProvider = StreamProvider<List<Txn>>((ref) => ref.watch(transactionRepoProvider).watchAll());

final accountTransactionsProvider = StreamProvider.family<List<Txn>, String>(
  (ref, accountId) => ref.watch(transactionRepoProvider).watchForAccount(accountId),
);

final loansProvider = StreamProvider<List<Loan>>((ref) => ref.watch(catalogRepoProvider).watchLoans());

final incomeTypesProvider = StreamProvider<List<IncomeType>>((ref) => ref.watch(catalogRepoProvider).watchIncomeTypes());

final categoriesProvider = StreamProvider<List<ExpenseCategory>>((ref) => ref.watch(catalogRepoProvider).watchCategories());

final accountTypesProvider = StreamProvider<List<ConfigItem>>(
  (ref) => ref.watch(catalogRepoProvider).watchConfig(ConfigList.accountTypes),
);

/// Liquid / reserved / locked / owed and net worth (archived accounts excluded).
final balanceSummaryProvider = FutureProvider<BalanceSummary>((ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final loans = await ref.watch(loansProvider.future);
  return summarizeBalances(accounts, loans);
});

/// Income, spending and per-category totals for the current calendar month.
final monthTotalsProvider = FutureProvider<MonthlyTotals>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  return monthlyTotals(txns, monthKey(ref.watch(clockProvider).today()));
});
