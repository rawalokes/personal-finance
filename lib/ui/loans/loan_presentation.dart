import '../../finance/finance.dart';

/// '11.25% · reducing', 'Interest-free', or 'Rate not entered' (spec §5.4:
/// never assume a missing rate).
String rateText(Loan l) {
  if (l.method == InterestMethod.none) return 'Interest-free';
  final r = l.ratePct;
  if (r == null) return 'Rate not entered';
  final pct = r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toString();
  return '$pct% · ${l.method == InterestMethod.flat ? 'flat' : 'reducing'}';
}

String frequencyLabel(LoanFrequency f) => switch (f) {
      LoanFrequency.monthly => 'Monthly',
      LoanFrequency.quarterly => 'Quarterly',
      LoanFrequency.yearly => 'Yearly',
      LoanFrequency.flexible => 'Flexible',
    };

String methodLabel(InterestMethod m) => switch (m) {
      InterestMethod.reducing => 'Reducing balance',
      InterestMethod.flat => 'Flat rate',
      InterestMethod.none => 'No interest',
    };

/// The payoff engine counts months from next month (index 0).
String payoffMonthLabel(IsoDate today, int monthIndex, {MonthCalendar cal = const AdCalendar()}) => cal is AdCalendar
    ? monthYear(addMonths(addMonths('${monthKey(today)}-01', 1), monthIndex))
    : cal.monthYearFrom(today, 1 + monthIndex);

/// Loans that still need paying.
List<Loan> owedLoans(Iterable<Loan> loans) => [for (final l in loans) if (!l.closed && l.outstanding > 0) l];

/// Average income minus spending over the last (up to 5) complete months
/// before [today]'s month that have any activity; null without history.
/// The planner warns when the extra amount exceeds it (spec §5.5).
Paisa? averageMonthlySurplus(List<Txn> txns, IsoDate today) {
  final current = monthKey(today);
  final months = {for (final t in txns) monthKey(t.date)}.where((m) => m.compareTo(current) < 0).toList()
    ..sort();
  final recent = months.length > 5 ? months.sublist(months.length - 5) : months;
  if (recent.isEmpty) return null;
  final total = recent.fold<int>(0, (sum, m) => sum + monthlyTotals(txns, m).surplus);
  return total ~/ recent.length;
}
