import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/finance.dart';
import '../../integrations/gemini/schemas.dart';
import '../../store/data_providers.dart';
import '../../store/reality.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/dialog.dart';
import '../components/indicators.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/money_text.dart';
import '../components/surfaces.dart';
import '../components/toast.dart';
import '../components/tone.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../typography.dart';
import 'reality_widgets.dart';

String methodLabel(BudgetMethod m) => switch (m) {
      BudgetMethod.fiftyThirtyTwenty => '50/30/20',
      BudgetMethod.zeroBased => 'Zero-based',
      BudgetMethod.debtFirst => 'Debt first',
    };

String methodRule(BudgetMethod m) => switch (m) {
      BudgetMethod.fiftyThirtyTwenty => '50% needs (EMIs included), 30% wants, 20% saved. Simple and proven — best when saving is under 20%.',
      BudgetMethod.zeroBased => 'Every rupee gets a job: needs as they are, wants trimmed 15%, the rest saved — part of it to costly loans.',
      BudgetMethod.debtFirst => 'Avalanche: needs as they are, wants cut 30%, 10% saved, and everything else to the loan with the highest rate.',
    };

/// A whole budget built from a proven method and the user's real spending;
/// one tap sets every line as a category budget.
class BudgetPlanScreen extends ConsumerStatefulWidget {
  const BudgetPlanScreen({super.key});

  @override
  ConsumerState<BudgetPlanScreen> createState() => _BudgetPlanScreenState();
}

class _BudgetPlanScreenState extends ConsumerState<BudgetPlanScreen> {
  BudgetMethod? _picked;

  Future<void> _apply(BudgetPlan plan) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Apply this plan?',
      body: 'Sets ${plan.lines.length} category budgets to the ${methodLabel(plan.method)} amounts. You can change any of them later in Plans → Budgets.',
      okLabel: 'Apply',
    );
    if (ok != ConfirmChoice.ok) return;
    final n = await applyBudgetPlan(ref.read(catalogRepoProvider), plan);
    ref.read(toastProvider.notifier).show('$n budgets set from your ${methodLabel(plan.method)} plan');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final recommended = ref.watch(recommendedMethodProvider).value;
    final method = _picked ?? recommended;
    final plan = method == null ? null : ref.watch(budgetPlanProvider(method)).value;
    final inputs = ref.watch(reportInputsProvider).value;
    final names = {for (final x in inputs?.categories ?? const <ExpenseCategory>[]) x.id: x.name};
    final loanName = plan?.extraDebtLoanId == null ? null : inputs?.loans.where((l) => l.id == plan!.extraDebtLoanId).firstOrNull?.name;

    return DetailPage(
      title: 'Budget plan',
      body: method == null || plan == null
          ? const SizedBox.shrink()
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
              ChipWrap(children: [
                for (final m in BudgetMethod.values) PaisaChip(label: methodLabel(m), selected: m == method, onTap: () => setState(() => _picked = m)),
              ]),
              const SizedBox(height: 10),
              PaisaCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(methodLabel(method), style: PaisaText.h3.copyWith(color: c.ink))),
                    if (method == recommended) const Tag('Recommended', tone: Tone.positive),
                  ]),
                  const SizedBox(height: 4),
                  Text(methodRule(method), style: PaisaText.sub.copyWith(color: c.ink2)),
                ]),
              ),
              const SizedBox(height: 10),
              if (plan.income <= 0)
                Note('Add your income first — a plan needs to know what comes in each month.', tone: Tone.amber)
              else ...[
                KeyValueCard(rows: [
                  KeyValueRow('Income (monthly average)', value: money.npr(plan.income)),
                  KeyValueRow('Needs', value: money.npr(plan.needs)),
                  KeyValueRow('Wants', value: money.npr(plan.wants)),
                  if (plan.emis > 0) KeyValueRow('EMIs', value: money.npr(plan.emis)),
                  if (plan.extraDebt > 0) KeyValueRow('Extra to ${loanName ?? 'your costliest loan'}', value: money.npr(plan.extraDebt)),
                  KeyValueRow('Save', valueWidget: MoneyText(plan.save, style: PaisaText.sub, color: c.positive)),
                ]),
                SectionHeader(padding: kInsetSection, title: 'Budgets', subtitle: 'Your plan, with what you spend now'),
                if (plan.lines.isEmpty)
                  Note('No spending by category yet. Record a few weeks of expenses and come back.', tone: Tone.blue)
                else
                  PaisaListCard(children: [
                    for (final l in plan.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(names[l.categoryId] ?? l.categoryId, style: PaisaText.sub.copyWith(color: c.ink), overflow: TextOverflow.ellipsis),
                              Wrap(children: [
                                Text('${l.essential ? 'Need' : 'Want'} · now ', style: PaisaText.hint.copyWith(color: c.ink3)),
                                MoneyText(l.current, style: PaisaText.hint, color: c.ink3),
                              ]),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          MoneyText(l.suggested, style: PaisaText.sub, color: l.suggested < l.current ? c.positive : c.ink),
                        ]),
                      ),
                  ]),
                const SizedBox(height: 14),
                if (plan.lines.isNotEmpty) PaisaButton(label: 'Apply as my budgets', onPressed: () => _apply(plan)),
                const SizedBox(height: 12),
                RealityAiCard(
                  key: ValueKey(method),
                  topic: RealityTopic.budget,
                  scope: method.name,
                  blurb: 'Why this method suits you, which cuts matter most, and how to stick to it.',
                  askLabel: 'Ask AI to explain this plan',
                  facts: () => budgetFacts(plan, names: names),
                ),
              ],
            ]),
    );
  }
}
