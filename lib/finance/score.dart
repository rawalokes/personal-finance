import 'catalog.dart';
import 'dates.dart';
import 'models.dart';
import 'money.dart';
import 'reports.dart';
import 'totals.dart';

enum ScorePartKind { savingsRate, budgets, loans, spending }

/// Points each part is worth before parts with no data are left out (spec §4.2).
const Map<ScorePartKind, int> kScoreMax = {
  ScorePartKind.savingsRate: 40,
  ScorePartKind.budgets: 25,
  ScorePartKind.loans: 20,
  ScorePartKind.spending: 15,
};

/// Saving this share of income earns every savings point.
const double kTargetSavingsRate = 0.20;

class ScoreTip {
  const ScoreTip(this.text, this.gain);
  final String text;
  final int gain;
}

class SavingsScore {
  const SavingsScore({
    required this.month,
    required this.total,
    required this.parts,
    required this.maxima,
    required this.isFinal,
    this.tip,
  });

  final String month;

  /// 0–100.
  final int total;

  /// Points per included part, scaled so the included maxima add up to 100.
  final Map<ScorePartKind, double> parts;
  final Map<ScorePartKind, double> maxima;

  /// False for the current month ("so far").
  final bool isFinal;

  /// Only for the current month.
  final ScoreTip? tip;
}

SavingsScore scoreForMonth(
  String month, {
  required Iterable<Txn> txs,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Loan> loans,
  required IsoDate today,
  MoneyFormat money = const MoneyFormat(),
}) {
  final isCurrent = monthKey(today) == month;
  final end = isCurrent ? today : lastOfMonth(month);
  final dayShare = isCurrent ? parseIsoDate(today).day / daysInMonthOf(today) : 1.0;
  final posted = [for (final t in txs) if (t.isPosted) t];
  final t = monthlyTotals(posted, month);
  final raw = <ScorePartKind, double>{};
  final tips = <(String, double)>[]; // text, raw points gained

  // Savings rate (40).
  final rate = t.income > 0 ? t.surplus / t.income : 0.0;
  raw[ScorePartKind.savingsRate] = 40 * (rate / kTargetSavingsRate).clamp(0.0, 1.0);
  if (t.income > 0 && rate < kTargetSavingsRate) {
    final need = (kTargetSavingsRate * t.income - t.surplus).ceil();
    tips.add(('Save ${money.npr(need)} more this month', 40 - raw[ScorePartKind.savingsRate]!));
  }

  // Budgets kept (25).
  final budgets = budgetPerformance(posted, categories, month);
  if (budgets.isNotEmpty) {
    final kept = budgets.where((b) => b.spent <= b.limit).toList();
    raw[ScorePartKind.budgets] = 25 * kept.length / budgets.length;
    if (kept.isNotEmpty) {
      final closest = (kept..sort((a, b) => b.ratio.compareTo(a.ratio))).first;
      final name = categories.firstWhere((c) => c.id == closest.categoryId).name;
      tips.add(('Keep $name under ${money.npr(closest.limit)}', 25 / budgets.length));
    }
  }

  // Loan progress (20).
  final open = [
    for (final l in loans)
      if (!l.closed && l.installment > 0 && (l.startDate == null || l.startDate!.compareTo(end) <= 0)) l,
  ];
  if (open.isNotEmpty) {
    bool paid(Loan l) => posted.any((x) => x.type == TxType.loanRepayment && x.loanId == l.id && monthKey(x.date) == month);
    final paidLoans = open.where(paid).toList();
    // Due = paid this month, or its due date has passed and it is still unpaid.
    final overdue = [
      for (final l in open)
        if (!paid(l) && l.nextDueDate != null && l.nextDueDate!.compareTo(end) <= 0) l,
    ];
    final due = paidLoans.length + overdue.length;
    final principal = posted
        .where((x) => x.type == TxType.loanRepayment && monthKey(x.date) == month)
        .fold<Paisa>(0, (s, x) => s + (x.principal ?? 0));
    final borrowed = posted
        .where((x) => x.type == TxType.loanDisbursement && monthKey(x.date) == month)
        .fold<Paisa>(0, (s, x) => s + x.amount);
    raw[ScorePartKind.loans] = (due == 0 ? 10 : 10 * paidLoans.length / due) + (principal > borrowed ? 10 : 0);
    if (overdue.isNotEmpty) tips.add(('Record the ${overdue.first.name} installment', 10 / due));
  }

  // Spending vs your normal (15).
  final previous = [
    for (var k = 1; k <= 3; k++) monthlyTotals(posted, monthKey(addMonths('$month-01', -k))).expenses,
  ].where((e) => e > 0).toList();
  if (previous.isNotEmpty) {
    final reference = previous.reduce((a, b) => a + b) / previous.length * dayShare;
    final ratio = reference <= 0 ? 0.0 : t.expenses / reference;
    final points = ratio <= 1 ? 15.0 : ratio >= 1.5 ? 0.0 : 15 * (1.5 - ratio) / 0.5;
    raw[ScorePartKind.spending] = points;
    if (points < 15) tips.add(('Spend less for the rest of the month', 15 - points));
  }

  final maxSum = raw.keys.fold<int>(0, (s, k) => s + kScoreMax[k]!);
  final scale = 100 / maxSum;
  final parts = raw.map((k, v) => MapEntry(k, v * scale));
  final total = parts.values.fold<double>(0, (s, v) => s + v).round();
  ScoreTip? tip;
  if (isCurrent && tips.isNotEmpty) {
    tips.sort((a, b) => b.$2.compareTo(a.$2));
    final gain = (tips.first.$2 * scale).round();
    if (gain > 0) tip = ScoreTip(tips.first.$1, gain);
  }
  return SavingsScore(
    month: month,
    total: total.clamp(0, 100),
    parts: parts,
    maxima: raw.map((k, _) => MapEntry(k, kScoreMax[k]! * scale)),
    isFinal: !isCurrent,
    tip: tip,
  );
}

/// The last [months] months' scores, oldest first.
List<SavingsScore> scoreTrend({
  required Iterable<Txn> txs,
  required Iterable<ExpenseCategory> categories,
  required Iterable<Loan> loans,
  required IsoDate today,
  MoneyFormat money = const MoneyFormat(),
  int months = 6,
}) =>
    [
      for (var k = months - 1; k >= 0; k--)
        scoreForMonth(monthKey(addMonths(firstOfMonth(today), -k)),
            txs: txs, categories: categories, loans: loans, today: today, money: money),
    ];
