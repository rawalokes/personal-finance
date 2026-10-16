import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/finance.dart';
import '../../store/reports.dart';
import '../components/indicators.dart';
import '../components/surfaces.dart';
import '../theme.dart';
import '../typography.dart';

const _partLabels = {
  ScorePartKind.savingsRate: 'Savings rate',
  ScorePartKind.budgets: 'Budgets kept',
  ScorePartKind.loans: 'Loan progress',
  ScorePartKind.spending: 'Spending vs your normal',
};

/// This month's savings score (spec §4.2). [compact] is the Home version.
class ScoreCard extends ConsumerWidget {
  const ScoreCard({super.key, this.compact = false, this.onTap});
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final trend = ref.watch(savingsScoreProvider).value;
    if (trend == null || trend.isEmpty) return SizedBox(height: compact ? 72 : 180);
    final s = trend.last;
    final color = s.total >= 70 ? c.positive : s.total >= 40 ? c.amber : c.red;
    final tip = s.tip;
    final line = tip != null ? '${tip.text} → +${tip.gain}' : s.total >= 70 ? 'Great month so far — keep it up.' : 'Add income and budgets to see how you’re doing.';
    return PaisaCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          SizedBox.square(
            dimension: 56,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.square(
                dimension: 56,
                child: CircularProgressIndicator(value: s.total / 100, strokeWidth: 6, color: color, backgroundColor: c.line),
              ),
              Text('${s.total}', style: PaisaText.h3.copyWith(color: c.ink)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Savings score', style: PaisaText.h3.copyWith(color: c.ink)),
              const SizedBox(height: 2),
              Text(line, style: PaisaText.sub.copyWith(color: c.ink3)),
            ]),
          ),
        ]),
        if (!compact) ...[
          const SizedBox(height: 14),
          for (final e in s.parts.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text(_partLabels[e.key]!, style: PaisaText.sub.copyWith(color: c.ink2))),
                  Text('${e.value.round()} / ${s.maxima[e.key]!.round()}', style: PaisaText.sub.copyWith(color: c.ink3)),
                ]),
                const SizedBox(height: 4),
                ProgressBar(value: e.value / s.maxima[e.key]!, color: color),
              ]),
            ),
          const SizedBox(height: 6),
          SizedBox(
            height: 64,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final m in trend)
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      height: 4 + 36 * m.total / 100,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: m.isFinal ? color.withValues(alpha: 0.6) : color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(height: 4),
                    Text(calendarOf(m.month).monthShort(m.month), style: PaisaText.hint.copyWith(color: c.ink3)),
                  ]),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}
