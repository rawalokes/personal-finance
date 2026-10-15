import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../loans/loan_presentation.dart';
import '../../theme.dart';
import '../../typography.dart';

/// Loans segment: what you still owe, then one card per loan.
class LoansView extends ConsumerWidget {
  const LoansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(loansProvider),
      data: (loans) {
        if (loans.isEmpty) {
          return EmptyState(
            icon: PaisaIcons.rupee,
            title: 'No loans',
            body: 'Add a bank loan, a credit from family, or anything you owe to see what remains and plan to pay it off.',
            actionLabel: 'Add a loan',
            onAction: () => context.push('/loans/new'),
          );
        }
        final c = context.colors;
        final today = ref.watch(clockProvider).today();
        final money = ref.watch(moneyFormatProvider);
        final owed = owedLoans(loans);
        final out = owed.fold<int>(0, (t, l) => t + l.outstanding);
        final principal = owed.fold<int>(0, (t, l) => t + l.principal);
        final paid = principal <= 0 ? 0.0 : (1 - out / principal).clamp(0.0, 1.0).toDouble();
        final monthly = owed
            .where((l) => l.frequency == LoanFrequency.monthly || l.frequency == LoanFrequency.flexible)
            .fold<int>(0, (t, l) => t + l.installment);
        final base = simulatePayoff(owed, rollover: false);
        final freeTxt = owed.isEmpty
            ? 'You have no outstanding loans'
            : base.hitLimit
                ? 'One installment is too low to ever clear its loan'
                : 'At this pace you’re debt-free by ${payoffMonthLabel(today, base.months - 1)}';
        final byId = {for (final r in base.loans) r.loanId: r};
        return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('You still owe', style: PaisaText.sub.copyWith(color: c.ink3)),
                const SizedBox(height: 4),
                MoneyText(out, color: out > 0 ? c.red : c.ink, style: PaisaText.h1.copyWith(fontSize: 30)),
                const SizedBox(height: 10),
                ProgressBar(value: paid, semanticLabel: 'Loans repaid'),
                const SizedBox(height: 8),
                Text(
                  '${(paid * 100).round()}% of ${money.npr(principal)} repaid · ${money.npr(monthly)} / month',
                  style: PaisaText.hint.copyWith(color: c.ink3),
                ),
                const SizedBox(height: 4),
                Text(freeTxt, style: PaisaText.sub.copyWith(color: c.ink2)),
                if (owed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PaisaButton(label: 'Plan how to pay it off', onPressed: () => context.push('/loans/planner')),
                  ),
                ],
              ]),
            ),
          ),
          SectionHeader(
            title: 'Your loans',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              PaisaLink(label: 'Types', onPressed: () => context.push('/loans/types')),
              const SizedBox(width: 8),
              PaisaLink(label: '+ Add', onPressed: () => context.push('/loans/new')),
            ]),
          ),
          for (final l in loans)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _LoanCard(loan: l, result: byId[l.id], today: today),
            ),
        ]);
      },
    );
  }
}

class _LoanCard extends ConsumerWidget {
  const _LoanCard({required this.loan, required this.result, required this.today});
  final Loan loan;
  final PayoffLoanResult? result;
  final IsoDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final l = loan;
    final done = l.outstanding <= 0 || l.closed;
    final paid = l.principal <= 0 ? 0.0 : (1 - l.outstanding / l.principal).clamp(0.0, 1.0).toDouble();
    final days = l.nextDueDate == null ? 99 : daysBetween(l.nextDueDate!, today);
    final month = result?.payoffMonth;
    final ends = done ? 'Paid off' : month == null ? 'Never at this rate' : payoffMonthLabel(today, month);
    final label = PaisaText.hint.copyWith(color: c.ink3);
    return PaisaCard(
      onTap: () => context.push('/loans/${l.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name, style: PaisaText.h3.copyWith(color: c.ink)),
              Text('${l.lender} · ${rateText(l)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.sub.copyWith(color: c.ink3)),
            ]),
          ),
          Tag(
            done ? 'Paid off' : dueText(l.nextDueDate, today),
            tone: done ? Tone.positive : days < 0 ? Tone.red : days <= 7 ? Tone.amber : Tone.neutral,
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Remaining', style: label),
              MoneyText(l.outstanding, style: PaisaText.h2),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Paid off by', style: label),
            Text(ends, style: PaisaText.h3.copyWith(color: month == null && !done ? c.red : c.ink)),
          ]),
        ]),
        const SizedBox(height: 10),
        ProgressBar(value: paid, semanticLabel: '${l.name} repaid'),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('${(paid * 100).round()}% repaid of ${money.npr(l.principal)}', style: label)),
          Text(done ? 'Done' : month == null ? '—' : '${month + 1} installments left', style: label),
        ]),
      ]),
    );
  }
}
