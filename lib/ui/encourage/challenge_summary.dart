import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../theme.dart';
import '../typography.dart';

String challengeTitle(Challenge c, ReportInputs i, MoneyFormat money) {
  final cat = i.categories.where((x) => x.id == c.categoryId).firstOrNull?.name ?? 'a category';
  final loan = i.loans.where((l) => l.id == c.loanId).firstOrNull?.name ?? 'a loan';
  return switch (c.template) {
    ChallengeTemplate.saveAmount => 'Save ${money.npr(c.target)}',
    ChallengeTemplate.categoryCap => 'Keep $cat under ${money.npr(c.target)}',
    ChallengeTemplate.noSpendDays => '${c.target} no-spend days',
    ChallengeTemplate.loanExtra => 'Pay ${money.npr(c.target)} extra on $loan',
    ChallengeTemplate.categoryCut => 'Spend ${c.target}% less on $cat',
  };
}

String challengeProgressText(Challenge c, ChallengeProgress p, MoneyFormat money) => switch (c.template) {
      ChallengeTemplate.saveAmount || ChallengeTemplate.loanExtra => '${money.npr(p.current)} of ${money.npr(p.target)}',
      ChallengeTemplate.categoryCap => '${money.npr(p.current)} spent of ${money.npr(p.target)}',
      ChallengeTemplate.noSpendDays => '${p.current} of ${p.target} days',
      ChallengeTemplate.categoryCut => '${p.current}% less so far · goal ${p.target}%',
    };

/// Streak and this month's accepted challenges, for Reports.
class ChallengeSummary extends ConsumerWidget {
  const ChallengeSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(challengeRolloverProvider);
    final c = context.colors;
    final s = ref.watch(challengeStateProvider).value;
    final i = ref.watch(reportInputsProvider).value;
    if (s == null || i == null) return const SizedBox(height: 60);
    final today = ref.watch(clockProvider).today();
    final month = monthKey(today);
    final money = ref.watch(moneyFormatProvider);
    final accepted = s.acceptedIn(month);
    final waiting = s.suggestionsIn(month).length;
    final streak = challengeStreak(s.history, month);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(streak == 0 ? 'No streak yet' : '🔥 $streak-month streak', style: PaisaText.sub.copyWith(color: c.ink2)),
      const SizedBox(height: 8),
      if (accepted.isEmpty)
        Text(
          waiting > 0 ? '$waiting suggested challenges are waiting for you.' : 'No challenges this month.',
          style: PaisaText.sub.copyWith(color: c.ink3),
        )
      else
        for (final ch in accepted)
          Builder(builder: (context) {
            final p = challengeProgress(ch, i.txs, i.loans, today);
            final cap = ch.template == ChallengeTemplate.categoryCap;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(challengeTitle(ch, i, money), style: PaisaText.sub.copyWith(color: c.ink)),
                const SizedBox(height: 4),
                ProgressBar(value: p.ratio, color: cap ? (p.met ? c.positive : c.red) : (p.met ? c.positive : c.primary)),
                const SizedBox(height: 2),
                Text(challengeProgressText(ch, p, money), style: PaisaText.hint.copyWith(color: c.ink3)),
              ]),
            );
          }),
      Align(
        alignment: Alignment.centerLeft,
        child: PaisaLink(label: 'Open challenges', onPressed: () => context.go('/plans?seg=challenges')),
      ),
    ]);
  }
}
