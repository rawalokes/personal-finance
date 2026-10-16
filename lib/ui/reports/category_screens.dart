import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/indicators.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/money_text.dart';
import '../components/surfaces.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../txn/transaction_tile.dart';
import '../txn/txn_presentation.dart';
import '../txn/txn_sheet.dart';
import '../typography.dart';
import 'report_charts.dart';

const _periods = [ReportPeriod.thisMonth, ReportPeriod.lastMonth, ReportPeriod.last3m, ReportPeriod.last6m, ReportPeriod.last12m];

/// "▲ NPR 500 vs last period" — up is red for spending, down is green.
class ChangeText extends StatelessWidget {
  const ChangeText({super.key, required this.now, required this.before});
  final Paisa now;
  final Paisa before;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (before == 0 && now == 0) return const SizedBox.shrink();
    if (before == 0) return Text('New this period', style: PaisaText.hint.copyWith(color: c.ink3));
    final diff = now - before;
    final pct = (diff.abs() * 100 / before).round();
    final color = diff > 0 ? c.red : c.positive;
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(diff > 0 ? '▲ ' : diff < 0 ? '▼ ' : '', style: PaisaText.hint.copyWith(color: color)),
      MoneyText(diff.abs(), style: PaisaText.hint, color: color),
      Text(' ($pct%) vs last period', style: PaisaText.hint.copyWith(color: c.ink3)),
    ]);
  }
}

Widget _periodChips(ReportPeriod selected, ValueChanged<ReportPeriod> onChanged) => ChipRow(children: [
      for (final p in _periods) PaisaChip(label: p.label, selected: p == selected, onTap: () => onChanged(p)),
    ]);

/// Every expense category for a period, with its share and change.
class CategoriesReportScreen extends ConsumerStatefulWidget {
  const CategoriesReportScreen({super.key, this.initial = ReportPeriod.thisMonth});
  final ReportPeriod initial;

  @override
  ConsumerState<CategoriesReportScreen> createState() => _CategoriesReportScreenState();
}

class _CategoriesReportScreenState extends ConsumerState<CategoriesReportScreen> {
  late ReportPeriod _period = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = ref.watch(reportInputsProvider).value;
    final today = ref.watch(clockProvider).today();
    final cal = ref.watch(monthCalendarProvider);
    final palette = chartPalette(context);
    final range = resolvePeriod(_period, today, fyStart: ref.watch(fyStartProvider), cal: cal);
    final rows = i == null ? const <CategorySpend>[] : categoryOverview(i.txs, i.categories, range, today: today, cal: cal);
    final total = rows.fold<Paisa>(0, (s, r) => s + r.total);
    return DetailPage(
      title: 'Spending by category',
      body: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
        _periodChips(_period, (p) => setState(() => _period = p)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Spent', style: PaisaText.sub.copyWith(color: c.ink3)),
            MoneyText(total, style: PaisaText.h1),
            const SizedBox(height: 12),
            if (rows.isEmpty) Text('No spending in this period.', style: PaisaText.sub.copyWith(color: c.ink3)),
            if (rows.isNotEmpty)
              PaisaDonut(values: [for (final r in rows.take(6)) r.total / 100], colors: palette),
            const SizedBox(height: 8),
            for (var k = 0; k < rows.length; k++)
              PaisaCard(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                onTap: () => context.push('/reports/category/${rows[k].id}?period=${_period.wire}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: palette[k % palette.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rows[k].name, style: PaisaText.h3.copyWith(color: c.ink), overflow: TextOverflow.ellipsis)),
                    MoneyText(rows[k].total, style: PaisaText.sub),
                  ]),
                  const SizedBox(height: 6),
                  ProgressBar(value: rows[k].share, color: palette[k % palette.length]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('${(rows[k].share * 100).round()}% of spending', style: PaisaText.hint.copyWith(color: c.ink3)),
                    const Spacer(),
                    Flexible(child: ChangeText(now: rows[k].total, before: rows[k].previous)),
                  ]),
                ]),
              ),
          ].expand((w) => [w, if (w is PaisaCard) const SizedBox(height: 8)]).toList()),
        ),
      ]),
    );
  }
}

/// One category: total, change, 6-month trend, budget, where it went and
/// every transaction.
class CategoryReportScreen extends ConsumerStatefulWidget {
  const CategoryReportScreen({super.key, required this.categoryId, this.initial = ReportPeriod.thisMonth});
  final String categoryId;
  final ReportPeriod initial;

  @override
  ConsumerState<CategoryReportScreen> createState() => _CategoryReportScreenState();
}

class _CategoryReportScreenState extends ConsumerState<CategoryReportScreen> {
  late ReportPeriod _period = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = ref.watch(reportInputsProvider).value;
    final lookup = ref.watch(txnLookupProvider).value;
    final money = ref.watch(moneyFormatProvider);
    final today = ref.watch(clockProvider).today();
    final cal = ref.watch(monthCalendarProvider);
    final palette = chartPalette(context);
    final name = i?.categories.where((x) => x.id == widget.categoryId).firstOrNull?.name ??
        (widget.categoryId == kLoanInterestCategoryId ? 'Loan interest' : 'Uncategorised');
    if (i == null || lookup == null) return DetailPage(title: name, body: const SizedBox.shrink());
    final range = resolvePeriod(_period, today, fyStart: ref.watch(fyStartProvider), cal: cal);
    final d = categoryDetail(i.txs, i.categories, widget.categoryId, range, today: today, cal: cal);
    final thisMonth = d.trend.last.value;
    final budget = d.budget;
    return DetailPage(
      title: name,
      body: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
        _periodChips(_period, (p) => setState(() => _period = p)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Spent · ${_period.label}', style: PaisaText.sub.copyWith(color: c.ink3)),
            MoneyText(d.total, style: PaisaText.h1),
            ChangeText(now: d.total, before: d.previousTotal),
            const SizedBox(height: 14),
            PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Last 6 months', style: PaisaText.h3.copyWith(color: c.ink)),
                const SizedBox(height: 10),
                PaisaBarChart(
                  labels: [for (final p in d.trend) cal.monthShort(p.label)],
                  series: [[for (final p in d.trend) p.value / 100]],
                  colors: [palette.first],
                  faded: {for (var k = 0; k < d.trend.length - 1; k++) k},
                ),
                const SizedBox(height: 6),
                LegendRow(
                  label: 'Monthly average',
                  amount: (d.trend.fold<Paisa>(0, (s, p) => s + p.value) / d.trend.length).round(),
                ),
              ]),
            ),
            if (budget != null && budget > 0) ...[
              const SizedBox(height: 10),
              PaisaCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text('${cal.monthLong(cal.key(today))} budget', style: PaisaText.h3.copyWith(color: c.ink))),
                    Text('${(thisMonth * 100 / budget).round()}%', style: PaisaText.sub.copyWith(color: thisMonth > budget ? c.red : c.ink2)),
                  ]),
                  const SizedBox(height: 6),
                  ProgressBar(value: thisMonth / budget, color: thisMonth > budget ? c.red : thisMonth >= budget * 0.85 ? c.amber : c.positive),
                  const SizedBox(height: 4),
                  Text(
                    thisMonth > budget
                        ? 'Over by ${money.npr(thisMonth - budget)}'
                        : '${money.npr(budget - thisMonth)} left of ${money.npr(budget)}',
                    style: PaisaText.hint.copyWith(color: c.ink3),
                  ),
                ]),
              ),
            ],
            if (d.places.isNotEmpty) ...[
              const SizedBox(height: 10),
              PaisaCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Where it went', style: PaisaText.h3.copyWith(color: c.ink)),
                  const SizedBox(height: 6),
                  SliceList(slices: d.places, colors: palette),
                ]),
              ),
            ],
          ]),
        ),
        SectionHeader(title: 'Transactions', subtitle: '${d.transactions.length} in ${_period.label.toLowerCase()}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: d.transactions.isEmpty
              ? Text('Nothing in this period.', style: PaisaText.sub.copyWith(color: c.ink3))
              : PaisaListCard(children: [
                  for (final t in d.transactions)
                    TransactionTile(view: describeTxn(t, lookup, today: today, money: money), onTap: () => showTxnSheet(context, t)),
                ]),
        ),
      ]),
    );
  }
}
