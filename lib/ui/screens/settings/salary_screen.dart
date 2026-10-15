import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/settings_models.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/salary_settings.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';
import 'ai_salary_check.dart';

/// Settings → Salary & deductions: gross-to-net simulator (spec §5.3),
/// payroll deductions with toggles, employer contributions shown separately.
class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  final _gross = TextEditingController();
  final _basic = TextEditingController();
  final _employer = TextEditingController();
  SalaryEntryMode _mode = SalaryEntryMode.gross;
  bool _loaded = false;
  bool _filling = false;
  String? _grossError;

  @override
  void initState() {
    super.initState();
    for (final c in [_gross, _basic]) {
      c.addListener(() {
        if (!_filling) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _gross.dispose();
    _basic.dispose();
    _employer.dispose();
    super.dispose();
  }

  void _load(SalaryProfile p) {
    if (_loaded) return;
    _loaded = true;
    _filling = true;
    _gross.text = p.grossMonthly > 0 ? '${toWholeRupees(p.grossMonthly)}' : '';
    _basic.text = p.basicPct == p.basicPct.roundToDouble() ? p.basicPct.toStringAsFixed(0) : '${p.basicPct}';
    _employer.text = p.employer;
    _mode = p.entryMode;
    _filling = false;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(salaryProfileProvider);
    final settings = ref.watch(salarySettingsProvider);
    return DetailPage(
      title: 'Salary & deductions',
      body: AsyncView(
        value: settings,
        data: (s) {
          _load(profile.value ?? const SalaryProfile());
          return _body(s, profile.value ?? const SalaryProfile());
        },
      ),
    );
  }

  Widget _body(SalarySettings s, SalaryProfile profile) {
    final c = context.colors;
    final money = MoneyFormat(grouping: ref.watch(groupingProvider));
    final today = ref.watch(clockProvider).today();
    final gross = parseNpr(_gross.text) ?? 0;
    final basicPct = double.tryParse(_basic.text.trim()) ?? profile.basicPct;
    final settings = SalarySettings(
      employer: s.employer,
      grossMonthly: gross,
      basicPct: basicPct,
      taxCategory: s.taxCategory,
      deductions: s.deductions,
      rules: s.rules,
    );
    final b = gross > 0 ? settings.breakdown(gross, asOf: today) : null;
    final taxOn = s.deductions.any((d) => d.kind == DeductionKind.tax && d.active);
    final red = PaisaText.numeric(PaisaText.body.copyWith(fontSize: 14, color: c.red));
    final ink = PaisaText.numeric(PaisaText.body.copyWith(fontSize: 14, color: c.ink));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
      PaisaCard(
        child: Row(children: [
          const IconWell(icon: PaisaIcons.brief, tone: Tone.positive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monthly Salary', style: PaisaText.h3.copyWith(color: c.ink)),
              Text(
                profile.employer.isEmpty ? 'Add your employer and gross salary below' : profile.employer,
                style: PaisaText.sub.copyWith(color: c.ink3),
              ),
            ]),
          ),
        ]),
      ),
      if (s.rules.isSampleDefault) ...[
        const SizedBox(height: 12),
        const Note(kSampleDefaultsBanner, tone: Tone.amber, icon: PaisaIcons.alert),
      ],
      const SectionHeader(title: 'Gross-to-net simulator', padding: EdgeInsets.fromLTRB(0, 20, 0, 10)),
      Segmented<SalaryEntryMode>(
        segments: const [(SalaryEntryMode.gross, 'From gross'), (SalaryEntryMode.takeHome, 'I know take-home')],
        selected: _mode,
        onChanged: (m) => setState(() => _mode = m),
      ),
      const SizedBox(height: 12),
      PaisaTextField(label: 'Employer', controller: _employer, hint: 'Optional, e.g. Himal Tech Pvt. Ltd.'),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: PaisaTextField(
            label: _mode == SalaryEntryMode.gross ? 'Gross monthly salary' : 'Take-home per month',
            controller: _gross,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _grossError,
          ),
        ),
        if (_mode == SalaryEntryMode.gross) ...[
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaTextField(
              label: 'Basic (% of gross)',
              controller: _basic,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 12),
      if (_mode == SalaryEntryMode.takeHome && gross > 0)
        Note(
          'Take-home ${money.npr(gross)} will be recorded as is. Tax, SSF, CIT and other payroll deductions are not deducted again.',
          tone: Tone.positive,
        )
      else if (b != null) ...[
        KeyValueCard(rows: [
          KeyValueRow('Gross salary', valueWidget: Text(money.npr(b.gross), style: ink)),
          KeyValueRow(
            taxOn
                ? '− Income tax (TDS) · ${(b.effectiveTaxRate * 100).toStringAsFixed(1)}% effective'
                : '− Income tax (TDS) · disabled',
            valueWidget: Text(money.npr(b.monthlyTax), style: red),
          ),
          for (final l in b.employeeLines) KeyValueRow('− ${l.name}', valueWidget: Text(money.npr(l.amount), style: red)),
          KeyValueRow(
            '= Estimated take-home',
            valueWidget: Text(money.npr(b.takeHome), style: PaisaText.numeric(PaisaText.h2.copyWith(color: c.positive))),
          ),
        ]),
        const SizedBox(height: 12),
        Text('Employer pays — not deducted from you', style: PaisaText.label.copyWith(color: c.ink2)),
        const SizedBox(height: 6),
        KeyValueCard(rows: [
          if (b.employerLines.isEmpty) const KeyValueRow('None configured', value: '—'),
          for (final l in b.employerLines) KeyValueRow(l.name, valueWidget: Text(money.npr(l.amount), style: ink)),
          KeyValueRow('Cost to company', valueWidget: Text('≈ ${money.npr(b.costToCompany)} / month', style: ink)),
        ]),
        const SizedBox(height: 8),
        Text(
          'Annual taxable income ${money.npr(b.taxableAnnual)} after ${money.npr(b.allowableAnnual)} retirement deduction · '
          'annual tax ${money.npr(b.annualTax)}.',
          style: PaisaText.hint.copyWith(color: c.ink3),
        ),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: PaisaButton(label: 'Save as my salary', variant: ButtonVariant.secondary, onPressed: () => _save(profile, gross, basicPct))),
        const SizedBox(width: 10),
        Expanded(
          child: PaisaButton(
            label: 'Record salary',
            onPressed: gross <= 0
                ? null
                : () async {
                    await _save(profile, gross, basicPct, quiet: true);
                    final takeHome = _mode == SalaryEntryMode.gross && b != null ? b.takeHome : gross;
                    if (mounted) context.push('/income/new?type=salary&amount=${toWholeRupees(takeHome)}');
                  },
          ),
        ),
      ]),
      AiSalaryCheck(breakdown: b, rules: s.rules),
      SectionHeader(
        title: 'Payroll deductions',
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
        trailing: PaisaLink(label: 'Custom', onPressed: () => showDeductionSheet(context, null, s.deductions)),
      ),
      PaisaListCard(children: [
        for (final d in s.deductions) _deductionRow(d, s, b, money),
      ]),
      const SizedBox(height: 12),
      PaisaCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/settings/tax'),
        child: ListRow(
          title: 'Tax rules',
          subtitle: 'FY ${s.rules.fiscalYear} · ${s.taxCategory}${s.rules.isSampleDefault ? ' · sample defaults' : ''}',
          leading: const IconWell(icon: PaisaIcons.percent, tone: Tone.amber, size: 36),
          trailing: PaisaIcon(PaisaIcons.chevR, size: 19, color: c.ink3),
        ),
      ),
    ]);
  }

  Widget _deductionRow(Deduction d, SalarySettings s, SalaryBreakdown? b, MoneyFormat money) {
    final c = context.colors;
    final line = [...?b?.employeeLines, ...?b?.employerLines].where((l) => l.deductionId == d.id).firstOrNull;
    final sub = d.kind == DeductionKind.tax
        ? 'Progressive brackets · FY ${s.rules.fiscalYear}'
        : '${d.paidBy == PaidBy.employer ? 'Employer · not deducted · ' : 'Employee · '}'
            '${d.method == CalcMethod.percent ? '${d.rate?.toStringAsFixed(d.rate == d.rate?.roundToDouble() ? 0 : 1)}% of ${d.base.name}' : 'Fixed'}';
    final amount = !d.active
        ? '—'
        : d.kind == DeductionKind.tax
            ? (b == null ? '' : money.short(b.monthlyTax))
            : (line == null ? '' : money.short(line.amount));
    return ListRow(
      title: d.name,
      subtitle: sub,
      onTap: d.kind == DeductionKind.tax ? () => context.push('/settings/tax') : () => showDeductionSheet(context, d, s.deductions),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(amount, style: PaisaText.numeric(PaisaText.sub.copyWith(color: d.paidBy == PaidBy.employer ? c.ink3 : c.ink))),
        PaisaToggle(
          value: d.active,
          label: '${d.active ? 'Disable' : 'Enable'} ${d.name}',
          onChanged: (on) => ref
              .read(settingsRepoProvider)
              .saveDeductions([for (final x in s.deductions) x.id == d.id ? x.copyWith(active: on) : x]),
        ),
      ]),
    );
  }

  Future<void> _save(SalaryProfile profile, Paisa gross, double basicPct, {bool quiet = false}) async {
    if (gross <= 0) {
      setState(() => _grossError = 'Enter an amount greater than zero');
      return;
    }
    setState(() => _grossError = null);
    final toast = ref.read(toastProvider.notifier);
    final money = toastNpr(ref, gross);
    await ref.read(settingsRepoProvider).saveSalaryProfile(profile.copyWith(
          employer: _employer.text.trim(),
          grossMonthly: _mode == SalaryEntryMode.gross ? gross : profile.grossMonthly,
          basicPct: basicPct,
          entryMode: _mode,
        ));
    if (!quiet) toast.show(_mode == SalaryEntryMode.gross ? 'Salary saved · gross $money' : 'Salary saved');
  }
}

class _DeductionForm extends ChangeNotifier {
  _DeductionForm(Deduction? d)
      : name = TextEditingController(text: d?.name ?? ''),
        rate = TextEditingController(text: d?.rate == null ? '' : '${d!.rate}'),
        amount = TextEditingController(text: d?.amount == null ? '' : '${toWholeRupees(d!.amount!)}'),
        limit = TextEditingController(text: d?.annualLimit == null ? '' : '${toWholeRupees(d!.annualLimit!)}'),
        paidBy = d?.paidBy ?? PaidBy.employee,
        method = d?.method ?? CalcMethod.fixed,
        base = d?.base ?? SalaryBase.gross,
        retirement = d?.retirementDeductible ?? false;
  final TextEditingController name, rate, amount, limit;
  PaidBy paidBy;
  CalcMethod method;
  SalaryBase base;
  bool retirement;
  String? nameError, valueError;

  void update(void Function() f) {
    f();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [name, rate, amount, limit]) {
      c.dispose();
    }
    super.dispose();
  }
}

/// New (null) or edit a payroll deduction.
Future<void> showDeductionSheet(BuildContext context, Deduction? d, List<Deduction> all) =>
    showPaisaFormSheet<void, _DeductionForm>(
      context,
      title: d == null ? 'New payroll deduction' : 'Edit deduction',
      create: () => _DeductionForm(d),
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'Sample defaults — confirm rates and limits with your payslip or the current rules.',
          style: PaisaText.sub.copyWith(color: ctx.colors.ink3),
        ),
        const SizedBox(height: 14),
        PaisaTextField(label: 'Name', controller: f.name, hint: 'e.g. Staff welfare fund', errorText: f.nameError),
        const SizedBox(height: 14),
        FieldGroup(
          label: 'Paid by',
          child: ChipWrap(children: [
            PaisaChip(label: 'Employee (from my pay)', selected: f.paidBy == PaidBy.employee, onTap: () => f.update(() => f.paidBy = PaidBy.employee)),
            PaisaChip(label: 'Employer', selected: f.paidBy == PaidBy.employer, onTap: () => f.update(() => f.paidBy = PaidBy.employer)),
          ]),
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: 'Calculation',
          child: ChipWrap(children: [
            PaisaChip(label: '% of salary', selected: f.method == CalcMethod.percent, onTap: () => f.update(() => f.method = CalcMethod.percent)),
            PaisaChip(label: 'Fixed amount', selected: f.method == CalcMethod.fixed, onTap: () => f.update(() => f.method = CalcMethod.fixed)),
          ]),
        ),
        const SizedBox(height: 14),
        if (f.method == CalcMethod.percent) ...[
          PaisaTextField(
            label: 'Rate (%)',
            controller: f.rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.valueError,
          ),
          const SizedBox(height: 14),
          FieldGroup(
            label: 'Salary base',
            child: ChipWrap(children: [
              PaisaChip(label: 'Basic salary', selected: f.base == SalaryBase.basic, onTap: () => f.update(() => f.base = SalaryBase.basic)),
              PaisaChip(label: 'Gross salary', selected: f.base == SalaryBase.gross, onTap: () => f.update(() => f.base = SalaryBase.gross)),
            ]),
          ),
        ] else
          PaisaTextField(
            label: 'Amount per month (NPR)',
            controller: f.amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: f.valueError,
          ),
        const SizedBox(height: 14),
        PaisaTextField(
          label: 'Annual limit (NPR)',
          controller: f.limit,
          hint: 'No limit',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        ToggleRow(
          title: 'Tax-deductible retirement contribution',
          value: f.retirement,
          onChanged: (v) => f.update(() => f.retirement = v),
        ),
      ]),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Save',
              onPressed: () async {
                final rate = double.tryParse(f.rate.text.trim());
                final amount = parseNpr(f.amount.text);
                final limit = f.limit.text.trim().isEmpty ? null : parseNpr(f.limit.text);
                f.update(() {
                  f.nameError = f.name.text.trim().isEmpty ? 'Enter a name' : null;
                  f.valueError = f.method == CalcMethod.percent
                      ? (rate == null || rate < 0 || rate > 100 ? 'Enter a rate between 0 and 100' : null)
                      : (amount == null ? 'Enter a valid amount' : null);
                });
                if (f.nameError != null || f.valueError != null) return;
                final updated = Deduction(
                  id: d?.id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
                  name: f.name.text.trim(),
                  kind: d?.kind ?? DeductionKind.other,
                  paidBy: f.paidBy,
                  method: f.method,
                  rate: f.method == CalcMethod.percent ? rate : null,
                  amount: f.method == CalcMethod.fixed ? amount : null,
                  base: f.base,
                  annualLimit: limit,
                  retirementDeductible: f.retirement,
                  effectiveFrom: d?.effectiveFrom,
                  effectiveTo: d?.effectiveTo,
                  active: d?.active ?? true,
                  scheme: d?.scheme,
                );
                await ref.read(settingsRepoProvider).saveDeductions(
                      d == null ? [...all, updated] : [for (final x in all) x.id == d.id ? updated : x],
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show(
                      d == null ? '${updated.name} added to payroll deductions' : 'Deduction updated · simulator recalculated',
                    );
              },
            ),
          ),
        ]),
      ),
    );
