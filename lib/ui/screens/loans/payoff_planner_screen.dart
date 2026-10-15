import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings_models.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../loans/loan_presentation.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';
import 'ai_planner_explainer.dart';

class _PlannerData {
  const _PlannerData(this.loans, this.txns, this.accounts, this.saved);
  final List<Loan> loans;
  final List<Txn> txns;
  final List<Account> accounts;
  final PayoffPlanSettings saved;
}

final _plannerDataProvider = FutureProvider<_PlannerData>((ref) async => _PlannerData(
      owedLoans(await ref.watch(loansProvider.future)),
      await ref.watch(transactionsProvider.future),
      await ref.watch(accountsProvider.future),
      await ref.watch(payoffPlanProvider.future),
    ));

const _extras = [0, 200000, 500000, 1000000, 2000000];

/// Payoff planner (spec §5.5): extra amount, avalanche or snowball, the
/// debt-free date against today's pace, payoff order and next month's
/// payments. Saving creates a monthly reminder for the extra payment.
class PayoffPlannerScreen extends ConsumerStatefulWidget {
  const PayoffPlannerScreen({super.key});

  @override
  ConsumerState<PayoffPlannerScreen> createState() => _PayoffPlannerScreenState();
}

class _PayoffPlannerScreenState extends ConsumerState<PayoffPlannerScreen> {
  final _extra = TextEditingController();
  PayoffStrategy _strategy = PayoffStrategy.avalanche;
  bool _loaded = false;
  bool _saving = false;

  /// True while the saved plan is copied into the field during build.
  bool _filling = false;

  @override
  void initState() {
    super.initState();
    _extra.addListener(() {
      if (!_filling) setState(() {});
    });
  }

  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  Paisa get _extraValue => parseNpr(_extra.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Payoff planner',
      body: AsyncView(
        value: ref.watch(_plannerDataProvider),
        data: (d) {
          if (!_loaded) {
            _loaded = true;
            _strategy = d.saved.strategy;
            if (d.saved.extraMonthly > 0) {
              _filling = true;
              _extra.text = '${toWholeRupees(d.saved.extraMonthly)}';
              _filling = false;
            }
          }
          if (d.loans.isEmpty) {
            return const EmptyState(
              icon: PaisaIcons.check,
              tone: Tone.positive,
              title: 'Nothing to pay off',
              body: 'You have no outstanding loans.',
            );
          }
          return _body(d);
        },
      ),
    );
  }

  Widget _body(_PlannerData d) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final today = ref.watch(clockProvider).today();
    final extra = _extraValue;
    final cmp = comparePayoff(d.loans, extraMonthly: extra, strategy: _strategy);
    final base = cmp.baseline;
    final plan = cmp.plan;
    final out = d.loans.fold<int>(0, (t, l) => t + l.outstanding);
    final installments = d.loans.fold<int>(0, (t, l) => t + l.installment);
    final surplus = averageMonthlySurplus(d.txns, today);
    String when(PayoffResult r) => r.hitLimit ? 'never' : payoffMonthLabel(today, r.months - 1);
    final baseById = {for (final r in base.loans) r.loanId: r};
    final order = [...plan.loans]..sort((a, b) => (a.payoffMonth ?? 9999).compareTo(b.payoffMonth ?? 9999));
    final saved = cmp.monthsSaved;
    final gain = plan.hitLimit
        ? 'One installment is too low to ever clear its loan.'
        : saved > 0
            ? '$saved ${saved == 1 ? 'month' : 'months'} sooner · saves about ${money.npr(cmp.interestSaved < 0 ? 0 : cmp.interestSaved)} in interest'
            : extra > 0
                ? 'Saves about ${money.npr(cmp.interestSaved < 0 ? 0 : cmp.interestSaved)} in interest'
                : 'Freed installments roll into the next loan. Add an extra amount to finish sooner.';
    final label = PaisaText.sub.copyWith(color: c.ink3);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
      PaisaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You still owe', style: label),
          MoneyText(out, color: c.red, style: PaisaText.h1.copyWith(fontSize: 28)),
          Text('${d.loans.length} loans · ${money.npr(installments)} in installments each month', style: label),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            const TextSpan(text: 'At this pace you’re debt-free by '),
            TextSpan(text: when(base), style: const TextStyle(fontVariations: [FontVariation('wght', 700)])),
          ]), style: PaisaText.sub.copyWith(color: c.ink2)),
        ]),
      ),
      const SizedBox(height: 16),
      FieldGroup(
        label: 'Extra I can pay each month',
        footer: surplus == null
            ? null
            : Text(
                'Your average monthly surplus is about ${money.npr(surplus)}. '
                '${extra > surplus ? 'This extra is more than that — it may not be sustainable.' : 'Keep part of it for savings goals.'}',
                style: PaisaText.hint.copyWith(color: extra > surplus ? c.amber : c.ink3),
              ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ChipWrap(children: [
            for (final x in _extras)
              PaisaChip(
                label: x == 0 ? 'None' : '+ ${money.short(x)}',
                selected: extra == x,
                onTap: () => _extra.text = x == 0 ? '' : '${toWholeRupees(x)}',
              ),
          ]),
          const SizedBox(height: 8),
          PaisaTextField(
            label: 'Or type an amount (NPR)',
            controller: _extra,
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      FieldGroup(
        label: 'Which loan gets the extra first?',
        footer: Text(
          _strategy == PayoffStrategy.avalanche
              ? 'Saves the most interest: extra goes to the costliest loan first.'
              : 'Quick wins: clear the smallest loan first, then roll its installment into the next.',
          style: PaisaText.hint.copyWith(color: c.ink3),
        ),
        child: Segmented<PayoffStrategy>(
          segments: const [(PayoffStrategy.avalanche, 'Highest interest'), (PayoffStrategy.snowball, 'Smallest balance')],
          selected: _strategy,
          onChanged: (s) => setState(() => _strategy = s),
        ),
      ),
      const SizedBox(height: 16),
      PaisaCard(
        color: c.attentionBg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('With this plan you’re debt-free by', style: label),
          Text(
            plan.hitLimit ? 'Not reachable' : when(plan),
            style: PaisaText.h1.copyWith(fontSize: 28, color: plan.hitLimit ? c.red : c.positive),
          ),
          const SizedBox(height: 4),
          Text(gain, style: PaisaText.sub.copyWith(color: c.ink2)),
          const SizedBox(height: 4),
          Text('Pay ${money.npr(installments + extra)} a month in total', style: PaisaText.sub.copyWith(color: c.ink2)),
        ]),
      ),
      const SectionHeader(title: 'Payoff order', padding: EdgeInsets.fromLTRB(0, 24, 0, 10)),
      PaisaListCard(children: [
        for (final (i, r) in order.indexed)
          ListRow(
            title: r.name,
            subtitle: () {
              final l = d.loans.firstWhere((x) => x.id == r.loanId);
              return '${rateText(l)} · ${money.npr(l.outstanding)} left';
            }(),
            leading: IconWell(icon: i == 0 ? PaisaIcons.flag : PaisaIcons.rupee, tone: i == 0 ? Tone.positive : Tone.neutral, size: 36),
            trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Text(r.payoffMonth == null ? '—' : payoffMonthLabel(today, r.payoffMonth!), style: PaisaText.h3.copyWith(color: c.ink)),
              Text(
                () {
                  final b = baseById[r.loanId]?.payoffMonth;
                  return b != null && b != r.payoffMonth ? 'was ${payoffMonthLabel(today, b)}' : 'no change';
                }(),
                style: PaisaText.hint.copyWith(color: c.ink3),
              ),
            ]),
          ),
      ]),
      const SectionHeader(title: 'What to pay next month', padding: EdgeInsets.fromLTRB(0, 24, 0, 10)),
      KeyValueCard(rows: [
        for (final r in plan.loans)
          KeyValueRow(
            r.nextMonthExtra > 0 ? '${r.name} + extra' : r.name,
            valueWidget: MoneyText(r.nextMonthPayment, style: PaisaText.numeric(PaisaText.body.copyWith(fontSize: 14))),
          ),
        KeyValueRow('Total', valueWidget: MoneyText(plan.nextMonthTotal, style: PaisaText.numeric(PaisaText.h3))),
      ]),
      const SizedBox(height: 16),
      PaisaButton(
        label: d.saved.savedAt != null && d.saved.extraMonthly == extra && d.saved.strategy == _strategy
            ? 'Plan saved ✓'
            : 'Save plan & remind me monthly',
        onPressed: _saving ? null : () => _save(d, plan, today),
      ),
      AiPlannerExplainer(loans: d.loans, comparison: cmp, extraMonthly: extra, strategy: _strategy, surplus: surplus),
      const SizedBox(height: 12),
      Text(
        'Estimate. Assumes today’s rates and on-time payments. Check prepayment fees with your lender first.',
        style: PaisaText.hint.copyWith(color: c.ink3),
      ),
    ]);
  }

  Future<void> _save(_PlannerData d, PayoffResult plan, IsoDate today) async {
    setState(() => _saving = true);
    final extra = _extraValue;
    final target = plan.loans.where((l) => l.nextMonthExtra > 0).firstOrNull;
    final targetLoan = d.loans.where((l) => l.id == target?.loanId).firstOrNull;
    final account = targetLoan?.repaymentAccountId ??
        d.accounts.where((a) => !a.archived && a.group == AccountGroup.liquid).firstOrNull?.id;
    final when = plan.hitLimit ? 'never' : payoffMonthLabel(today, plan.months - 1);
    final strategy = _strategy == PayoffStrategy.avalanche ? 'highest interest first' : 'smallest balance first';
    final settings = ref.read(settingsRepoProvider);
    final catalog = ref.read(catalogRepoProvider);
    final toast = ref.read(toastProvider.notifier);
    await settings.savePayoffPlan(
      PayoffPlanSettings(extraMonthly: extra, strategy: _strategy, savedAt: ref.read(clockProvider).stamp()),
      summary: 'Saved payoff plan: +${toWholeRupees(extra)}/month, $strategy, debt-free $when',
    );
    // One reminder for the extra payment; saving again replaces it.
    await catalog.removeRecurring('payoff-extra');
    if (extra > 0 && account != null) {
      await catalog.addRecurring(RecurringRule(
        id: 'payoff-extra',
        name: 'Extra payment → ${target?.name ?? 'loans'}',
        kind: RecurringKind.loanExtra,
        amount: extra,
        accountId: account,
        frequency: RecurringFrequency.monthly,
        nextDate: addMonths('${monthKey(today)}-01', 1),
      ));
    }
    if (mounted) setState(() => _saving = false);
    toast.show('Plan saved · debt-free by $when');
  }
}
