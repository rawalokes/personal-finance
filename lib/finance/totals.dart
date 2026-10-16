import 'calendar.dart';
import 'models.dart';
import 'money.dart';

const String kUncategorised = 'uncategorised';

class MonthlyTotals {
  const MonthlyTotals({
    required this.income,
    required this.expenses,
    required this.byCategory,
    required this.byIncomeType,
  });

  final Paisa income;

  /// Expenses + loan interest − refunds.
  final Paisa expenses;
  final Map<String, Paisa> byCategory;
  final Map<String, Paisa> byIncomeType;

  Paisa get surplus => income - expenses;
  double get savingsRate => income > 0 ? surplus / income : 0;
}

/// Totals for [month] ('YYYY-MM'). Only posted transactions count. Transfers,
/// card payments, cash withdrawals, reversals, disbursements and adjustments
/// are never income or spending.
/// [month] is a [MonthCalendar] key: 'YYYY-MM' (AD) or 'B2083-06' (BS).
MonthlyTotals monthlyTotals(Iterable<Txn> txs, String month, {MonthCalendar cal = const AdCalendar()}) {
  Paisa income = 0;
  Paisa expenses = 0;
  final byCategory = <String, Paisa>{};
  final byIncomeType = <String, Paisa>{};
  void add(Map<String, Paisa> m, String key, Paisa v) => m[key] = (m[key] ?? 0) + v;

  for (final t in txs) {
    if (!t.isPosted || cal.key(t.date) != month) continue;
    switch (t.type) {
      case TxType.income:
        income += t.amount;
        add(byIncomeType, t.incomeTypeId ?? kUncategorised, t.amount);
      case TxType.expense:
        expenses += t.amount;
        add(byCategory, t.categoryId ?? kUncategorised, t.amount);
      case TxType.refund:
        expenses -= t.amount;
        add(byCategory, t.categoryId ?? kUncategorised, -t.amount);
      case TxType.loanRepayment:
        {
          final interest = t.interest ?? 0;
          if (interest > 0) {
            expenses += interest;
            add(byCategory, kLoanInterestCategoryId, interest);
          }
        }
      default:
        break;
    }
  }
  return MonthlyTotals(income: income, expenses: expenses, byCategory: byCategory, byIncomeType: byIncomeType);
}
