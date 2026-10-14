import 'dart:math' as math;

import 'dates.dart';
import 'money.dart';

/// Annual and monthly give the same result: scaling progressive brackets by
/// 1/12 is linear. The value is kept so the editor can show the user's choice.
enum TaxCalculation { annual, monthly }

class TaxBracket {
  const TaxBracket({required this.min, this.max, required this.ratePct, this.condition});

  /// Annual taxable income where this slab starts.
  final Paisa min;

  /// Where it ends; null = no upper limit (last slab only).
  final Paisa? max;
  final double ratePct;
  final String? condition;
}

class TaxRuleSet {
  const TaxRuleSet({
    required this.id,
    required this.jurisdiction,
    required this.fiscalYear,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.calculation,
    required this.categories,
    required this.waiveFirstSlabForSsf,
    required this.retirementCap,
    required this.retirementMaxPctOfGross,
    required this.isSampleDefault,
    this.verifiedAt,
  });

  final String id;
  final String jurisdiction;

  /// e.g. '2083/84'
  final String fiscalYear;
  final IsoDate effectiveFrom;
  final IsoDate effectiveTo;
  final TaxCalculation calculation;

  /// 'individual', 'couple', or user-defined categories.
  final Map<String, List<TaxBracket>> categories;
  final bool waiveFirstSlabForSsf;
  final Paisa retirementCap;
  final double retirementMaxPctOfGross;

  /// Seeded values — show the "Sample defaults" banner while true.
  final bool isSampleDefault;
  final String? verifiedAt;

  TaxRuleSet withBrackets(String category, List<TaxBracket> brackets) => TaxRuleSet(
        id: id,
        jurisdiction: jurisdiction,
        fiscalYear: fiscalYear,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        calculation: calculation,
        categories: {...categories, category: List.unmodifiable(brackets)},
        waiveFirstSlabForSsf: waiveFirstSlabForSsf,
        retirementCap: retirementCap,
        retirementMaxPctOfGross: retirementMaxPctOfGross,
        isSampleDefault: isSampleDefault,
        verifiedAt: verifiedAt,
      );
}

class SlabTax {
  const SlabTax({required this.bracket, required this.portion, required this.tax, required this.waived});
  final TaxBracket bracket;
  final Paisa portion;
  final Paisa tax;
  final bool waived;
}

class TaxResult {
  const TaxResult({required this.annualTax, required this.slabs});
  final Paisa annualTax;
  final List<SlabTax> slabs;
  static const zero = TaxResult(annualTax: 0, slabs: []);
}

TaxResult computeAnnualTax(Paisa taxable, List<TaxBracket> brackets, {bool waiveFirstSlab = false}) {
  final sorted = [...brackets]..sort((a, b) => a.min.compareTo(b.min));
  final slabs = <SlabTax>[];
  Paisa total = 0;
  for (var i = 0; i < sorted.length; i++) {
    final b = sorted[i];
    final top = b.max == null ? taxable : math.min(taxable, b.max!);
    final portion = math.max(0, top - b.min);
    final waived = i == 0 && waiveFirstSlab;
    final tax = waived ? 0 : (portion * b.ratePct / 100).round();
    total += tax;
    slabs.add(SlabTax(bracket: b, portion: portion, tax: tax, waived: waived));
  }
  return TaxResult(annualTax: total, slabs: slabs);
}

class BracketIssue {
  const BracketIssue(this.index, this.message);
  final int index;
  final String message;
  @override
  String toString() => 'Slab ${index + 1}: $message';
}

/// Brackets must start at 0, be contiguous (no gaps or overlaps), have
/// To > From, rates 0–100, and only the last may be open-ended.
/// Any issue blocks saving.
List<BracketIssue> validateBrackets(List<TaxBracket> brackets) {
  if (brackets.isEmpty) return const [BracketIssue(0, 'Add at least one bracket')];
  const fmt = MoneyFormat();
  final issues = <BracketIssue>[];
  for (var i = 0; i < brackets.length; i++) {
    final b = brackets[i];
    if (i == 0 && b.min != 0) {
      issues.add(BracketIssue(i, 'The first bracket must start at 0'));
    }
    if (b.max != null && b.max! <= b.min) {
      issues.add(BracketIssue(i, '"To" must be more than "From"'));
    }
    if (b.ratePct < 0 || b.ratePct > 100) {
      issues.add(BracketIssue(i, 'Rate must be between 0 and 100'));
    }
    if (i > 0) {
      final prevMax = brackets[i - 1].max;
      if (prevMax == null) {
        issues.add(BracketIssue(i - 1, 'Only the last bracket can have no upper limit'));
      } else if (b.min > prevMax) {
        issues.add(BracketIssue(i, 'Gap: the previous bracket ends at ${fmt.plain(prevMax)}'));
      } else if (b.min < prevMax) {
        issues.add(BracketIssue(i, 'Overlaps the previous bracket, which ends at ${fmt.plain(prevMax)}'));
      }
    }
  }
  return issues;
}
