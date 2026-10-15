import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repos/settings_repo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/salary_settings.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/dialog.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

class _Slab {
  _Slab(TaxBracket? b)
      : from = TextEditingController(text: b == null ? '' : '${toWholeRupees(b.min)}'),
        to = TextEditingController(text: b?.max == null ? '' : '${toWholeRupees(b!.max!)}'),
        rate = TextEditingController(text: b == null ? '' : _num(b.ratePct)),
        condition = TextEditingController(text: b?.condition ?? '');

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  final TextEditingController from, to, rate, condition;

  /// The bracket, or null with the reason when a field is not a number.
  (TaxBracket?, String?) parse() {
    final min = parseNpr(from.text);
    final max = to.text.trim().isEmpty ? null : parseNpr(to.text);
    final r = double.tryParse(rate.text.trim());
    if (min == null) return (null, 'Enter a starting amount');
    if (to.text.trim().isNotEmpty && max == null) return (null, 'Enter an upper limit, or leave it blank');
    if (r == null) return (null, 'Enter a rate');
    final cond = condition.text.trim();
    return (TaxBracket(min: min, max: max, ratePct: r, condition: cond.isEmpty ? null : cond), null);
  }

  void dispose() {
    for (final c in [from, to, rate, condition]) {
      c.dispose();
    }
  }
}

/// Settings → Tax rules: jurisdiction, fiscal year, brackets per taxpayer
/// category with gap/overlap checks, retirement cap and a live preview
/// (spec §7, acceptance 9). Saving is blocked while any slab has an issue.
class TaxRulesScreen extends ConsumerStatefulWidget {
  const TaxRulesScreen({super.key});

  @override
  ConsumerState<TaxRulesScreen> createState() => _TaxRulesScreenState();
}

class _TaxRulesScreenState extends ConsumerState<TaxRulesScreen> {
  TaxRuleSet? _base;
  final _jurisdiction = TextEditingController();
  final _fy = TextEditingController();
  final _cap = TextEditingController();
  final _pct = TextEditingController();
  late IsoDate _from;
  late IsoDate _to;
  TaxCalculation _calc = TaxCalculation.annual;
  bool _waive = true;
  bool _verified = false;
  String _category = 'individual';
  final _slabs = <String, List<_Slab>>{};

  @override
  void dispose() {
    for (final c in [_jurisdiction, _fy, _cap, _pct]) {
      c.dispose();
    }
    _disposeSlabs();
    super.dispose();
  }

  void _disposeSlabs() {
    for (final list in _slabs.values) {
      for (final s in list) {
        s.dispose();
      }
    }
    _slabs.clear();
  }

  void _load(TaxRuleSet r) {
    _base = r;
    _jurisdiction.text = r.jurisdiction;
    _fy.text = r.fiscalYear;
    _cap.text = '${toWholeRupees(r.retirementCap)}';
    _pct.text = _Slab._num(r.retirementMaxPctOfGross);
    _from = r.effectiveFrom;
    _to = r.effectiveTo;
    _calc = r.calculation;
    _waive = r.waiveFirstSlabForSsf;
    _verified = !r.isSampleDefault;
    _disposeSlabs();
    for (final e in r.categories.entries) {
      _slabs[e.key] = [for (final b in e.value) _attach(_Slab(b))];
    }
    if (!_slabs.containsKey(_category)) _category = _slabs.keys.first;
  }

  _Slab _attach(_Slab s) {
    for (final c in [s.from, s.to, s.rate]) {
      c.addListener(() => setState(() {}));
    }
    return s;
  }

  /// Per-slab issues for the shown category (parse errors first).
  Map<int, String> _issues() {
    final list = _slabs[_category] ?? const [];
    final parsed = [for (final s in list) s.parse()];
    final out = <int, String>{};
    for (final (i, (_, err)) in parsed.indexed) {
      if (err != null) out[i] = err;
    }
    if (out.isEmpty) {
      for (final issue in validateBrackets([for (final (b, _) in parsed) b!])) {
        out.putIfAbsent(issue.index, () => issue.message);
      }
    }
    return out;
  }

  TaxRuleSet? _build() {
    final base = _base!;
    final cats = <String, List<TaxBracket>>{};
    for (final e in _slabs.entries) {
      final parsed = [for (final s in e.value) s.parse()];
      if (parsed.any((p) => p.$1 == null)) return null;
      cats[e.key] = [for (final p in parsed) p.$1!];
    }
    final cap = parseNpr(_cap.text);
    final pct = double.tryParse(_pct.text.trim());
    if (cap == null || pct == null) return null;
    return TaxRuleSet(
      id: base.id,
      jurisdiction: _jurisdiction.text.trim().isEmpty ? base.jurisdiction : _jurisdiction.text.trim(),
      fiscalYear: _fy.text.trim().isEmpty ? base.fiscalYear : _fy.text.trim(),
      effectiveFrom: _from,
      effectiveTo: _to,
      calculation: _calc,
      categories: cats,
      waiveFirstSlabForSsf: _waive,
      retirementCap: cap,
      retirementMaxPctOfGross: pct,
      isSampleDefault: !_verified,
      verifiedAt: _verified ? (base.verifiedAt ?? ref.read(clockProvider).stamp()) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(taxRulesProvider);
    return DetailPage(
      title: 'Nepal tax rules',
      actions: [PaisaLink(label: 'Reset', onPressed: _reset)],
      body: AsyncView(
        value: rules,
        data: (r) {
          if (_base == null) _load(r);
          return _form();
        },
      ),
      footer: SizedBox(width: double.infinity, child: PaisaButton(label: 'Save tax rules', onPressed: _save)),
    );
  }

  Widget _form() {
    final c = context.colors;
    final money = MoneyFormat(grouping: ref.watch(groupingProvider));
    final issues = _issues();
    final draft = issues.isEmpty ? _build() : null;
    final salary = ref.watch(salarySettingsProvider).value;
    final gross = salary?.grossMonthly ?? 0;
    final preview = draft != null && salary != null && gross > 0
        ? SalarySettings(
            employer: salary.employer,
            grossMonthly: gross,
            basicPct: salary.basicPct,
            taxCategory: _category,
            deductions: salary.deductions,
            rules: draft,
          ).breakdown(gross)
        : null;
    final slabs = _slabs[_category] ?? const <_Slab>[];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
      if (!_verified)
        const Note(
          'These slabs follow recently published Nepal rates but are not confirmed for the selected fiscal year. '
          'Check the current Finance Act or Inland Revenue Department guidance.',
          lead: 'Sample defaults requiring verification.',
          tone: Tone.amber,
        ),
      const SizedBox(height: 14),
      PaisaTextField(label: 'Country & jurisdiction', controller: _jurisdiction),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: PaisaTextField(label: 'Fiscal year', controller: _fy, hint: '2083/84')),
        const SizedBox(width: 10),
        Expanded(
          child: FieldGroup(
            label: 'Calculate',
            child: Segmented<TaxCalculation>(
              segments: const [(TaxCalculation.annual, 'Annual'), (TaxCalculation.monthly, 'Monthly')],
              selected: _calc,
              onChanged: (v) => setState(() => _calc = v),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: DateField(label: 'Effective from', value: _from, onChanged: (v) => setState(() => _from = v))),
        const SizedBox(width: 10),
        Expanded(child: DateField(label: 'Effective to', value: _to, onChanged: (v) => setState(() => _to = v))),
      ]),
      const SizedBox(height: 14),
      FieldGroup(
        label: 'Taxpayer category',
        child: Segmented<String>(
          segments: [for (final k in _slabs.keys) (k, '${k[0].toUpperCase()}${k.substring(1)}')],
          selected: _category,
          onChanged: (v) => setState(() => _category = v),
        ),
      ),
      SectionHeader(
        title: 'Progressive brackets',
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        trailing: Text('annual NPR', style: PaisaText.sub.copyWith(color: c.ink3)),
      ),
      for (final (i, s) in slabs.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PaisaCard(
            borderColor: issues.containsKey(i) ? c.red : null,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text('Slab ${i + 1}', style: PaisaText.h3.copyWith(color: c.ink))),
                if (preview != null && i < preview.tax.slabs.length)
                  Flexible(
                    child: Text(
                      preview.tax.slabs[i].waived ? 'Waived for SSF contributors' : 'Your tax: ${money.npr(preview.tax.slabs[i].tax)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PaisaText.hint.copyWith(color: c.ink3),
                    ),
                  ),
                PaisaIconButton(icon: PaisaIcons.trash, label: 'Delete slab ${i + 1}', onPressed: () => _deleteSlab(i)),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: PaisaTextField(
                    label: 'Slab ${i + 1} · From',
                    controller: s.from,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PaisaTextField(
                    label: 'Slab ${i + 1} · To',
                    controller: s.to,
                    hint: 'No limit',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: PaisaTextField(
                    label: 'Slab ${i + 1} · Rate %',
                    controller: s.rate,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              PaisaTextField(label: 'Slab ${i + 1} · Conditions', controller: s.condition, hint: 'Optional'),
              if (issues[i] != null) ...[
                const SizedBox(height: 6),
                Text(issues[i]!, style: PaisaText.hint.copyWith(color: c.red)),
              ],
            ]),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: PaisaButton(
          label: 'Add bracket',
          icon: PaisaIcons.plus,
          small: true,
          variant: ButtonVariant.outline,
          onPressed: () => setState(() {
            final list = _slabs[_category]!;
            final last = list.isEmpty ? null : list.last.parse().$1;
            list.add(_attach(_Slab(null)..from.text = last?.max == null ? '' : '${toWholeRupees(last!.max!)}'));
          }),
        ),
      ),
      const SectionHeader(title: 'Deductions & eligibility', padding: EdgeInsets.fromLTRB(0, 24, 0, 10)),
      ToggleRow(
        title: 'Waive first-slab social security tax',
        subtitle: 'For SSF contributors',
        value: _waive,
        onChanged: (v) => setState(() => _waive = v),
      ),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: PaisaTextField(
            label: 'Retirement deduction cap (NPR / year)',
            controller: _cap,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PaisaTextField(
            label: '…or at most this % of gross',
            controller: _pct,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      ToggleRow(
        title: 'I have verified these rules for this fiscal year',
        subtitle: 'Removes the “sample defaults” warnings',
        value: _verified,
        onChanged: (v) => setState(() => _verified = v),
      ),
      const SizedBox(height: 14),
      PaisaCard(
        color: c.surface2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Preview with your salary', style: PaisaText.label.copyWith(color: c.ink2)),
          const SizedBox(height: 6),
          Text(
            preview == null
                ? (gross <= 0 ? 'Add your salary in Salary & deductions to see a preview.' : 'Fix the slabs above to see a preview.')
                : 'Annual tax ${money.npr(preview.annualTax)} · ${money.npr(preview.monthlyTax)}/month',
            style: PaisaText.h3.copyWith(color: c.ink),
          ),
          if (preview != null)
            Text(
              'On gross ${money.npr(gross)}/month · effective rate ${(preview.effectiveTaxRate * 100).toStringAsFixed(1)}% · '
              'take-home ${money.npr(preview.takeHome)}',
              style: PaisaText.hint.copyWith(color: c.ink3),
            ),
        ]),
      ),
    ]);
  }

  Future<void> _deleteSlab(int i) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete slab ${i + 1}?',
      body: 'This bracket is removed from the draft. Nothing changes until you save.',
      okLabel: 'Delete slab',
      okVariant: ButtonVariant.danger,
    );
    if (ok != ConfirmChoice.ok) return;
    setState(() => _slabs[_category]!.removeAt(i).dispose());
  }

  Future<void> _reset() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reset to sample defaults?',
      body: 'Your saved tax rules are replaced with the sample Nepal slabs (which still need verifying).',
      okLabel: 'Reset',
    );
    if (ok != ConfirmChoice.ok) return;
    await ref.read(settingsRepoProvider).resetTaxRules();
    setState(() => _load(sampleTaxRules()));
    ref.read(toastProvider.notifier).show('Tax rules reset to sample defaults');
  }

  Future<void> _save() async {
    final toast = ref.read(toastProvider.notifier);
    final draft = _base == null ? null : _build();
    final anyIssue = _slabs.keys.any((k) {
      final keep = _category;
      _category = k;
      final has = _issues().isNotEmpty;
      _category = keep;
      return has;
    });
    if (draft == null || anyIssue) {
      toast.show('Fix the highlighted slabs before saving');
      return;
    }
    try {
      await ref.read(settingsRepoProvider).saveTaxRules(draft);
      _base = draft;
      toast.show('Tax rules saved · salary estimates updated');
    } on TaxRulesInvalid {
      toast.show('Fix the highlighted slabs before saving');
    }
  }
}
