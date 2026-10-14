import 'dart:math' as math;

import 'dates.dart';
import 'money.dart';
import 'tax.dart';

enum DeductionKind { tax, contribution, other }

enum PaidBy { employee, employer }

enum CalcMethod { percent, fixed }

enum SalaryBase { basic, gross }

/// Lets the engine recognise schemes without matching on names.
enum DeductionScheme { ssf, cit, providentFund, insurance }

class Deduction {
  const Deduction({
    required this.id,
    required this.name,
    required this.kind,
    this.paidBy = PaidBy.employee,
    this.method = CalcMethod.fixed,
    this.rate,
    this.amount,
    this.base = SalaryBase.gross,
    this.annualLimit,
    this.retirementDeductible = false,
    this.effectiveFrom,
    this.effectiveTo,
    this.active = true,
    this.scheme,
  });

  final String id;
  final String name;
  final DeductionKind kind;
  final PaidBy paidBy;
  final CalcMethod method;

  /// Percent of [base] when [method] is percent.
  final double? rate;

  /// Monthly amount when [method] is fixed.
  final Paisa? amount;
  final SalaryBase base;
  final Paisa? annualLimit;
  final bool retirementDeductible;
  final IsoDate? effectiveFrom;
  final IsoDate? effectiveTo;
  final bool active;
  final DeductionScheme? scheme;

  Deduction copyWith({bool? active, double? rate, Paisa? amount, Paisa? annualLimit}) => Deduction(
        id: id,
        name: name,
        kind: kind,
        paidBy: paidBy,
        method: method,
        rate: rate ?? this.rate,
        amount: amount ?? this.amount,
        base: base,
        annualLimit: annualLimit ?? this.annualLimit,
        retirementDeductible: retirementDeductible,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        active: active ?? this.active,
        scheme: scheme,
      );
}

class DeductionLine {
  const DeductionLine({
    required this.deductionId,
    required this.name,
    required this.amount,
    required this.retirementDeductible,
  });
  final String deductionId;
  final String name;
  final Paisa amount;
  final bool retirementDeductible;
}

class SalaryBreakdown {
  const SalaryBreakdown({
    required this.gross,
    required this.basic,
    required this.employeeLines,
    required this.employerLines,
    required this.allowableAnnual,
    required this.taxableAnnual,
    required this.tax,
    required this.monthlyTax,
    required this.takeHome,
    this.enteredAsTakeHome = false,
  });

  /// Take-home mode: recorded as is, with no deductions applied (spec §5.3).
  factory SalaryBreakdown.fromTakeHome(Paisa takeHome) => SalaryBreakdown(
        gross: takeHome,
        basic: 0,
        employeeLines: const [],
        employerLines: const [],
        allowableAnnual: 0,
        taxableAnnual: 0,
        tax: TaxResult.zero,
        monthlyTax: 0,
        takeHome: takeHome,
        enteredAsTakeHome: true,
      );

  final Paisa gross;
  final Paisa basic;
  final List<DeductionLine> employeeLines;

  /// Shown separately; never subtracted from take-home.
  final List<DeductionLine> employerLines;
  final Paisa allowableAnnual;
  final Paisa taxableAnnual;
  final TaxResult tax;
  final Paisa monthlyTax;
  final Paisa takeHome;
  final bool enteredAsTakeHome;

  Paisa get employeeTotal => employeeLines.fold(0, (t, l) => t + l.amount);
  Paisa get retirementMonthly =>
      employeeLines.where((l) => l.retirementDeductible).fold(0, (t, l) => t + l.amount);
  Paisa get employerTotal => employerLines.fold(0, (t, l) => t + l.amount);
  Paisa get costToCompany => gross + employerTotal;
  Paisa get annualTax => tax.annualTax;
  double get effectiveTaxRate => gross > 0 ? tax.annualTax / (gross * 12) : 0;
}

SalaryBreakdown computeSalary({
  required Paisa grossMonthly,
  required double basicPct,
  required List<Deduction> deductions,
  required TaxRuleSet rules,
  required String taxCategory,
  IsoDate? asOf,
}) {
  final brackets = rules.categories[taxCategory];
  if (brackets == null) {
    throw ArgumentError.value(taxCategory, 'taxCategory', 'not defined in FY ${rules.fiscalYear} rules');
  }

  bool inEffect(Deduction d) =>
      d.active &&
      (asOf == null ||
          ((d.effectiveFrom == null || d.effectiveFrom!.compareTo(asOf) <= 0) &&
              (d.effectiveTo == null || d.effectiveTo!.compareTo(asOf) >= 0)));

  final basic = (grossMonthly * basicPct / 100).round();
  final employee = <DeductionLine>[];
  final employer = <DeductionLine>[];
  for (final d in deductions.where(inEffect)) {
    if (d.kind == DeductionKind.tax) continue;
    final base = d.base == SalaryBase.basic ? basic : grossMonthly;
    var amount = d.method == CalcMethod.percent ? (base * (d.rate ?? 0) / 100).round() : (d.amount ?? 0);
    final limit = d.annualLimit;
    if (limit != null && limit > 0) amount = math.min(amount, (limit / 12).round());
    final line = DeductionLine(
      deductionId: d.id,
      name: d.name,
      amount: amount,
      retirementDeductible: d.retirementDeductible,
    );
    (d.paidBy == PaidBy.employer ? employer : employee).add(line);
  }

  final retirement = employee.where((l) => l.retirementDeductible).fold<Paisa>(0, (t, l) => t + l.amount);
  final annualGross = grossMonthly * 12;
  final cap = math.min(rules.retirementCap, (annualGross * rules.retirementMaxPctOfGross / 100).round());
  final allowable = math.min(retirement * 12, cap);
  final taxable = math.max(0, annualGross - allowable);

  final taxOn = deductions.any((d) => d.kind == DeductionKind.tax && inEffect(d));
  final ssfOn = deductions.any((d) => d.scheme == DeductionScheme.ssf && d.paidBy == PaidBy.employee && inEffect(d));
  final tax = taxOn
      ? computeAnnualTax(taxable, brackets, waiveFirstSlab: rules.waiveFirstSlabForSsf && ssfOn)
      : TaxResult.zero;
  final monthlyTax = (tax.annualTax / 12).round();
  final employeeTotal = employee.fold<Paisa>(0, (t, l) => t + l.amount);

  return SalaryBreakdown(
    gross: grossMonthly,
    basic: basic,
    employeeLines: employee,
    employerLines: employer,
    allowableAnnual: allowable,
    taxableAnnual: taxable,
    tax: tax,
    monthlyTax: monthlyTax,
    takeHome: grossMonthly - monthlyTax - employeeTotal,
  );
}
