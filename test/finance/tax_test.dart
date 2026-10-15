import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/money.dart';
import 'package:paisa/finance/sample_defaults.dart';
import 'package:paisa/finance/tax.dart';

void main() {
  final individual = sampleTaxRules().categories['individual']!;

  test('progressive slabs on 12,84,960 taxable', () {
    final r = computeAnnualTax(fromRupees(1284960), individual);
    expect(r.annualTax, fromRupees(5000 + 20000 + 60000 + 85488));
    expect(r.slabs.first.tax, fromRupees(5000));
    expect(r.slabs.last.portion, 0);
  });

  test('waiving the first slab zeroes only slab 1', () {
    final r = computeAnnualTax(fromRupees(1284960), individual, waiveFirstSlab: true);
    expect(r.annualTax, fromRupees(165488));
    expect(r.slabs.first.waived, isTrue);
    expect(r.slabs.first.tax, 0);
  });

  test('sample rules are flagged as unverified samples', () {
    final rules = sampleTaxRules();
    expect(rules.isSampleDefault, isTrue);
    expect(rules.fiscalYear, '2083/84');
    expect(kSampleDefaultsBanner, 'Sample defaults — verify for your fiscal year');
  });

  group('validateBrackets (acceptance 9)', () {
    test('accepts the sample brackets', () {
      expect(validateBrackets(individual), isEmpty);
      expect(validateBrackets(sampleTaxRules().categories['couple']!), isEmpty);
    });
    test('flags an overlap, which blocks saving', () {
      final b = [...individual];
      b[1] = TaxBracket(min: fromRupees(450000), max: fromRupees(700000), ratePct: 10);
      final issues = validateBrackets(b);
      expect(issues.single.index, 1);
      expect(issues.single.message, contains('Overlaps'));
    });
    test('flags a gap', () {
      final b = [...individual];
      b[1] = TaxBracket(min: fromRupees(550000), max: fromRupees(700000), ratePct: 10);
      expect(validateBrackets(b).single.message, contains('Gap'));
    });
    test('flags bad first bracket, open-ended middle bracket, inverted range and bad rate', () {
      expect(validateBrackets([TaxBracket(min: fromRupees(1), ratePct: 1)]).single.message,
          contains('start at 0'));
      expect(validateBrackets([
        const TaxBracket(min: 0, ratePct: 1),
        TaxBracket(min: fromRupees(5), ratePct: 2),
      ]).map((i) => i.message), contains(contains('no upper limit')));
      expect(validateBrackets([TaxBracket(min: 0, max: 0, ratePct: 1)]).single.message, contains('more than'));
      expect(validateBrackets([const TaxBracket(min: 0, ratePct: 120)]).single.message, contains('between 0 and 100'));
      expect(validateBrackets(const []).single.message, contains('at least one'));
    });
  });
}
