import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/loans/loan_presentation.dart';

import '../../data/sample_data.dart';

Loan loan(String id) => sampleLoans.firstWhere((l) => l.id == id);

void main() {
  test('rate text never shows a missing rate as 0%', () {
    expect(rateText(loan('L1')), '11.25% · reducing');
    expect(rateText(loan('L3')), '12% · flat');
    expect(rateText(loan('L4')), 'Interest-free');
    expect(rateText(loan('L2').copyWithTerms(clearRate: true)), 'Rate not entered');
  });

  test('frequency labels', () {
    expect(frequencyLabel(LoanFrequency.monthly), 'Monthly');
    expect(frequencyLabel(LoanFrequency.flexible), 'Flexible');
  });

  test('month index 0 is next month', () {
    expect(payoffMonthLabel('2026-10-14', 0), 'Nov 2026');
    expect(payoffMonthLabel('2026-10-14', 14), 'Jan 2028');
  });

  test('average monthly surplus uses complete past months only, up to the last 5', () {
    Txn tx(String date, TxType type, num rupees) =>
        Txn(id: date + type.wire, date: date, time: '09:00', title: 't', type: type, accountId: 'a', amount: fromRupees(rupees));
    final history = [
      tx('2026-08-01', TxType.income, 100000), tx('2026-08-10', TxType.expense, 40000),
      tx('2026-09-01', TxType.income, 100000), tx('2026-09-10', TxType.expense, 60000),
      tx('2026-10-01', TxType.income, 999999), // this month: not complete, ignored
    ];
    expect(averageMonthlySurplus(history, '2026-10-14'), fromRupees(50000));
    expect(averageMonthlySurplus(const [], '2026-10-14'), isNull);
  });

  test('loans still owed exclude closed and paid-off loans', () {
    final paid = loan('L4').copyWith(outstanding: 0);
    expect(owedLoans([loan('L1'), paid, loan('L2').copyWith(closed: true)]).map((l) => l.id), ['L1']);
  });
}
