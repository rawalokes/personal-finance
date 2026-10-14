import 'money.dart';
import 'salary.dart';
import 'tax.dart';

/// Banner text required wherever sample tax data is shown (spec §5.3).
const String kSampleDefaultsBanner = 'Sample defaults — verify for your fiscal year';

List<TaxBracket> _slabs(List<(num, num?, double)> rows) => [
      for (var i = 0; i < rows.length; i++)
        TaxBracket(
          min: fromRupees(rows[i].$1),
          max: rows[i].$2 == null ? null : fromRupees(rows[i].$2!),
          ratePct: rows[i].$3,
          condition: i == 0 ? 'Social security tax' : null,
        ),
    ];

/// FY 2083/84 SAMPLE defaults. Not official — the user must verify them.
TaxRuleSet sampleTaxRules() => TaxRuleSet(
      id: 'np-2083-84-sample',
      jurisdiction: 'Nepal · Inland Revenue Department',
      fiscalYear: '2083/84',
      effectiveFrom: '2026-07-17',
      effectiveTo: '2027-07-16',
      calculation: TaxCalculation.annual,
      categories: {
        'individual': _slabs([
          (0, 500000, 1.0),
          (500000, 700000, 10.0),
          (700000, 1000000, 20.0),
          (1000000, 2000000, 30.0),
          (2000000, 5000000, 36.0),
          (5000000, null, 39.0),
        ]),
        'couple': _slabs([
          (0, 600000, 1.0),
          (600000, 800000, 10.0),
          (800000, 1100000, 20.0),
          (1100000, 2000000, 30.0),
          (2000000, 5000000, 36.0),
          (5000000, null, 39.0),
        ]),
      },
      waiveFirstSlabForSsf: true,
      retirementCap: fromRupees(500000),
      retirementMaxPctOfGross: 33.33,
      isSampleDefault: true,
    );

/// Payroll deductions from spec §12 (provident fund off by default).
List<Deduction> sampleDeductions() => [
      const Deduction(id: 'tax', name: 'Personal income tax', kind: DeductionKind.tax),
      const Deduction(
        id: 'ssf', name: 'SSF — employee share', kind: DeductionKind.contribution,
        method: CalcMethod.percent, rate: 11, base: SalaryBase.basic, retirementDeductible: true,
        effectiveFrom: '2026-07-17', scheme: DeductionScheme.ssf,
      ),
      const Deduction(
        id: 'ssf_employer', name: 'SSF — employer share', kind: DeductionKind.contribution,
        paidBy: PaidBy.employer, method: CalcMethod.percent, rate: 20, base: SalaryBase.basic,
        effectiveFrom: '2026-07-17', scheme: DeductionScheme.ssf,
      ),
      Deduction(
        id: 'cit', name: 'CIT contribution', kind: DeductionKind.contribution,
        amount: fromRupees(5000), retirementDeductible: true, effectiveFrom: '2026-07-17',
        scheme: DeductionScheme.cit,
      ),
      const Deduction(
        id: 'pf', name: 'Provident fund', kind: DeductionKind.contribution,
        method: CalcMethod.percent, rate: 10, base: SalaryBase.basic, retirementDeductible: true,
        active: false, effectiveFrom: '2026-07-17', scheme: DeductionScheme.providentFund,
      ),
      Deduction(
        id: 'insurance', name: 'Group health insurance', kind: DeductionKind.other,
        amount: fromRupees(500), effectiveFrom: '2026-07-17', scheme: DeductionScheme.insurance,
      ),
    ];
