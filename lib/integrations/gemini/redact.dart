import '../../data/settings_models.dart';
import '../../finance/finance.dart';

/// Everything the AI may summarise. The payload builder decides what
/// actually leaves the phone, by privacy level (spec §9.2).
class SummaryInput {
  const SummaryInput({
    required this.today,
    required this.accounts,
    required this.loans,
    required this.transactions,
    required this.categories,
    required this.goals,
    required this.privacy,
  });

  final IsoDate today;
  final List<Account> accounts;
  final List<Loan> loans;
  final List<Txn> transactions;
  final List<ExpenseCategory> categories;
  final List<Goal> goals;
  final AiPrivacy privacy;
}

int _r(Paisa p) => toWholeRupees(p);

/// The JSON sent with every AI request, in whole rupees.
///
/// Never included, at any level: account names, account or card numbers,
/// SMS senders, notes. Merchant names and transaction titles are added only
/// at [AiPrivacy.merchants] and above. SMS text is never part of this
/// summary (only the Inbox's low-confidence help may send masked SMS).
Map<String, Object?> buildSummaryPayload(SummaryInput s) {
  final month = monthKey(s.today);
  final totals = monthlyTotals(s.transactions, month);
  final balances = summarizeBalances(s.accounts, s.loans);
  final months = {for (final t in s.transactions) monthKey(t.date)}.where((m) => m.compareTo(month) < 0).toList()..sort();
  final history = months.length > 6 ? months.sublist(months.length - 6) : months;
  // This month plus up to five before it, for per-category spending.
  final spendMonths = [...(history.length > 5 ? history.sublist(history.length - 5) : history), month];
  final byMonth = {for (final m in spendMonths) m: m == month ? totals : monthlyTotals(s.transactions, m)};
  final active = s.categories.where((c) => c.active && c.isTopLevel).toList();
  final essential = active.where((c) => c.essential).fold<int>(0, (t, c) => t + (c.monthlyBudget ?? 0));
  final reserved = balances.reserved;
  final owed = [for (final l in s.loans) if (!l.closed && l.outstanding > 0) l];
  final payoff = owed.isEmpty ? null : simulatePayoff(owed, rollover: false);

  return {
    'month': month,
    'currency': 'NPR',
    'income': _r(totals.income),
    'expenses': _r(totals.expenses),
    'surplus': _r(totals.surplus),
    'savingsRatePct': double.parse((totals.savingsRate * 100).toStringAsFixed(1)),
    'history': [
      for (final m in history)
        () {
          final t = monthlyTotals(s.transactions, m);
          return {'m': m, 'in': _r(t.income), 'out': _r(t.expenses)};
        }(),
    ],
    'available': _r(balances.liquid),
    'reserved': _r(reserved),
    'locked': _r(balances.locked),
    'liabilities': {'creditCard': _r(balances.creditCards), 'loans': _r(balances.loans)},
    'loans': [
      for (final l in owed)
        {
          'name': l.name,
          'outstanding': _r(l.outstanding),
          'ratePct': l.method == InterestMethod.none ? 0 : l.ratePct ?? 'not entered',
          'method': l.method.name,
          'installment': _r(l.installment),
          'nextDue': l.nextDueDate,
        },
    ],
    'budgets': [
      for (final c in active)
        if ((c.monthlyBudget ?? 0) > 0)
          {'category': c.name, 'categoryId': c.id, 'limit': _r(c.monthlyBudget!), 'spent': _r(totals.byCategory[c.id] ?? 0)},
    ],
    'spendingByCategory': {
      for (final e in totals.byCategory.entries)
        (s.categories.where((c) => c.id == e.key).firstOrNull?.name ?? e.key): _r(e.value),
    },
    'categories': [
      for (final c in active)
        {
          'categoryId': c.id,
          'name': c.name,
          if ((c.monthlyBudget ?? 0) > 0) 'budget': _r(c.monthlyBudget!),
          'spentByMonth': {for (final m in spendMonths) m: _r(byMonth[m]!.byCategory[c.id] ?? 0)},
        },
    ],
    'emergencyFundMonths': essential <= 0 ? null : double.parse((reserved / essential).toStringAsFixed(1)),
    'goals': [
      for (final g in s.goals) {'name': g.name, 'target': _r(g.target), 'saved': _r(g.current), 'targetDate': g.targetDate},
    ],
    if (payoff != null) 'payoff': {'debtFreeMonths': payoff.hitLimit ? 'never' : payoff.months, 'totalInterest': _r(payoff.totalInterest)},
    if (s.privacy != AiPrivacy.summaries)
      'recentTransactions': [
        for (final t in s.transactions.where((t) => t.isPosted).take(40))
          {'date': t.date, 'title': t.title, 'type': t.type.wire, 'amount': _r(t.amount)},
      ],
  };
}
