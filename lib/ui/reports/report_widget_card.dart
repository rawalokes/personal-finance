import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/report_settings.dart';
import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/money_text.dart';
import '../components/surfaces.dart';
import '../components/tone.dart';
import '../encourage/challenge_summary.dart';
import '../encourage/score_card.dart';
import '../theme.dart';
import '../typography.dart';
import 'report_charts.dart';

/// One dashboard widget (spec §3.1). [periodOverride] is the screen's
/// temporary "one period for all" choice.
class ReportWidgetCard extends ConsumerWidget {
  const ReportWidgetCard({super.key, required this.config, this.periodOverride});

  final ReportWidgetConfig config;
  final ReportPeriod? periodOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (config.type == ReportWidgetType.savingsScore) return const ScoreCard();
    final c = context.colors;
    final i = ref.watch(reportInputsProvider).value;
    if (i == null) return const SizedBox(height: 120);
    final today = ref.watch(clockProvider).today();
    final usesPeriod = config.type.settings.contains(WidgetSetting.period);
    final period = periodOverride ?? config.period;
    final cal = ref.watch(monthCalendarProvider);
    final range = resolvePeriod(period, today, fyStart: ref.watch(fyStartProvider), cal: cal);
    Widget body;
    var forecast = false;
    try {
      (body, forecast) = _body(context, i, range, today, cal);
    } on Object {
      body = Text('Couldn’t draw this widget.', style: PaisaText.sub.copyWith(color: c.red));
    }
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(config.type.title, style: PaisaText.h3.copyWith(color: c.ink))),
          if (config.type != ReportWidgetType.challenges) Tag(forecast ? 'Actual · Forecast' : 'Actual', tone: forecast ? Tone.blue : Tone.neutral),
        ]),
        if (usesPeriod) Text(period.label, style: PaisaText.hint.copyWith(color: c.ink3)),
        const SizedBox(height: 10),
        body,
      ]),
    );
  }

  Widget _empty(BuildContext context, String text) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: PaisaText.sub.copyWith(color: context.colors.ink3)));

  Widget _compare(BuildContext context, String label, Paisa now, Paisa before) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(child: Text('$label vs previous period', style: PaisaText.hint.copyWith(color: c.ink3))),
        MoneyText(now - before, style: PaisaText.hint, sign: now >= before ? '+' : ''),
      ]),
    );
  }

  /// The widget body and whether it shows forecast figures.
  (Widget, bool) _body(BuildContext context, ReportInputs i, DateRange range, IsoDate today, MonthCalendar cal) {
    final c = context.colors;
    final palette = chartPalette(context);
    final accounts = config.accountIds.toSet();
    switch (config.type) {
      case ReportWidgetType.savingsScore:
        return (const ScoreCard(), false);
      case ReportWidgetType.challenges:
        return (const ChallengeSummary(), false);
      case ReportWidgetType.cashFlow:
        final pts = cashFlow(i.txs, range, accountIds: accounts, recurring: i.recurring, loans: i.loans, today: today, cal: cal);
        final actual = pts.where((p) => p.kind == PointKind.actual).toList();
        if (actual.every((p) => p.income == 0 && p.expenses == 0)) return (_empty(context, 'No money in or out in this period.'), false);
        final labels = [for (final p in pts) cal.monthShort(p.month)];
        final series = [
          [for (final p in pts) p.income / 100],
          [for (final p in pts) p.expenses / 100],
        ];
        final firstForecast = pts.indexWhere((p) => p.kind == PointKind.forecast);
        final colors = [c.positive, c.red];
        final income = actual.fold<Paisa>(0, (t, p) => t + p.income);
        final out = actual.fold<Paisa>(0, (t, p) => t + p.expenses);
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            config.chart == ReportChart.line
                ? PaisaLineChart(labels: labels, series: series, colors: colors, forecastFrom: firstForecast < 0 ? null : firstForecast)
                : PaisaBarChart(labels: labels, series: series, colors: colors, faded: {for (var k = 0; k < pts.length; k++) if (pts[k].kind == PointKind.forecast) k}),
            const SizedBox(height: 8),
            LegendRow(label: 'Money in', amount: income, color: c.positive),
            LegendRow(label: 'Money out', amount: out, color: c.red),
            LegendRow(label: 'Net', amount: income - out),
            if (config.compare)
              () {
                final prev = cashFlow(i.txs, previousRange(range, cal: cal), accountIds: accounts, cal: cal);
                return _compare(context, 'Net', income - out, prev.fold<Paisa>(0, (t, p) => t + p.net));
              }(),
          ]),
          firstForecast >= 0,
        );
      case ReportWidgetType.spendingByCategory:
      case ReportWidgetType.incomeBySource:
        final spending = config.type == ReportWidgetType.spendingByCategory;
        List<ReportSlice> slicesFor(DateRange r) => spending
            ? spendingByCategory(i.txs, r, i.categories, accountIds: accounts, categoryIds: config.categoryIds.toSet(), cal: cal)
            : incomeBySource(i.txs, r, groupBy: config.groupBy, incomeTypes: i.incomeTypes, parties: i.parties, accountIds: accounts);
        final all = slicesFor(range);
        if (all.isEmpty) return (_empty(context, spending ? 'No spending in this period.' : 'No income in this period.'), false);
        final slices = topSlices(all);
        final total = all.fold<Paisa>(0, (t, s) => t + s.value);
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (config.chart == ReportChart.donut) PaisaDonut(values: [for (final s in slices) s.value / 100], colors: palette),
            if (config.chart == ReportChart.bar)
              PaisaBarChart(
                labels: [for (final s in slices) s.label.length > 6 ? s.label.substring(0, 6) : s.label],
                series: [[for (final s in slices) s.value / 100]],
                colors: [palette.first],
              ),
            const SizedBox(height: 8),
            SliceList(
              slices: slices,
              colors: palette,
              onTap: spending ? (s) => context.push('/reports/category/${s.id}?period=${(periodOverride ?? config.period).wire}') : null,
            ),
            if (spending)
              Align(
                alignment: Alignment.centerLeft,
                child: PaisaLink(
                  label: 'See all categories',
                  onPressed: () => context.push('/reports/categories?period=${(periodOverride ?? config.period).wire}'),
                ),
              ),
            if (config.compare) _compare(context, 'Total', total, slicesFor(previousRange(range, cal: cal)).fold<Paisa>(0, (t, s) => t + s.value)),
          ]),
          false,
        );
      case ReportWidgetType.netWorth:
        if (i.accounts.isEmpty && i.loans.isEmpty) return (_empty(context, 'Add accounts to see your net worth.'), false);
        final pts = netWorthSeries(i.accounts, i.loans, i.txs, range, today, recurring: i.recurring, cal: cal);
        final actual = pts.where((p) => p.kind == PointKind.actual).toList();
        final firstForecast = pts.indexWhere((p) => p.kind == PointKind.forecast);
        final labels = [for (final p in pts) cal.monthShort(p.label)];
        final series = [[for (final p in pts) p.value / 100]];
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            config.chart == ReportChart.bar
                ? PaisaBarChart(labels: labels, series: series, colors: [palette.first], faded: {for (var k = 0; k < pts.length; k++) if (pts[k].kind == PointKind.forecast) k})
                : PaisaLineChart(labels: labels, series: series, colors: [palette.first], forecastFrom: firstForecast < 0 ? null : firstForecast),
            const SizedBox(height: 8),
            LegendRow(label: 'Now', amount: actual.last.value),
            LegendRow(label: 'Change in period', amount: actual.last.value - actual.first.value),
            if (firstForecast >= 0) LegendRow(label: 'In 3 months (forecast)', amount: pts.last.value),
          ]),
          firstForecast >= 0,
        );
      case ReportWidgetType.assetsLiabilities:
        final b = summarizeBalances(i.accounts, i.loans);
        if (b.assets == 0 && b.liabilities == 0) return (_empty(context, 'Add accounts to see what you own and owe.'), false);
        final ratio = b.assets > 0 ? '${(b.liabilities * 100 / b.assets).round()}%' : '—';
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (config.chart == ReportChart.bar)
              PaisaBarChart(labels: const ['Assets', 'Liabilities'], series: [[b.assets / 100, b.liabilities / 100]], colors: [c.positive]),
            LegendRow(label: 'Assets', amount: b.assets, color: c.positive),
            LegendRow(label: 'Liabilities', amount: b.liabilities, color: c.red),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Debt-to-asset ratio $ratio', style: PaisaText.sub.copyWith(color: c.ink2)),
            ),
          ]),
          false,
        );
      case ReportWidgetType.budgetPerformance:
        final lines = budgetPerformance(i.txs, i.categories, cal.key(today), categoryIds: config.categoryIds.toSet(), cal: cal);
        if (lines.isEmpty) return (_empty(context, 'No budgets set. Add them in Plans → Budgets.'), false);
        final names = {for (final x in i.categories) x.id: x.name};
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(names[l.categoryId] ?? '—', style: PaisaText.sub.copyWith(color: c.ink), overflow: TextOverflow.ellipsis),
                  Wrap(children: [
                    MoneyText(l.spent, style: PaisaText.hint),
                    Text(' of ', style: PaisaText.hint.copyWith(color: c.ink3)),
                    MoneyText(l.limit, style: PaisaText.hint, color: c.ink3),
                  ]),
                  const SizedBox(height: 4),
                  ProgressBar(
                    value: l.ratio,
                    color: switch (l.state) { BudgetState.over => c.red, BudgetState.nearLimit => c.amber, BudgetState.ok => c.positive },
                  ),
                ]),
              ),
          ]),
          false,
        );
      case ReportWidgetType.loanProgress:
        final loans = loanProgress(i.loans, loanIds: config.loanIds.toSet());
        if (loans.isEmpty) return (_empty(context, 'No open loans 🎉'), false);
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final l in loans)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(l.loan.name, style: PaisaText.sub.copyWith(color: c.ink))),
                    Text('${(l.repaidRatio * 100).round()}% repaid', style: PaisaText.hint.copyWith(color: c.ink3)),
                  ]),
                  const SizedBox(height: 4),
                  ProgressBar(value: l.repaidRatio, color: c.positive),
                  const SizedBox(height: 2),
                  Row(children: [
                    MoneyText(l.loan.outstanding, style: PaisaText.hint, color: c.ink3),
                    Expanded(
                      child: Text(
                        l.monthsLeft == null
                            ? ' left · never repaid at this installment'
                            : ' left · debt-free ${cal.monthYear(cal.shift(cal.key(today), l.monthsLeft!))}',
                        style: PaisaText.hint.copyWith(color: c.ink3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ]),
              ),
          ]),
          false,
        );
      case ReportWidgetType.interestPaid:
        List<ReportPoint> pointsFor(DateRange r) => interestPaid(i.txs, r, loanIds: config.loanIds.toSet(), cal: cal);
        final pts = pointsFor(range);
        final total = pts.fold<Paisa>(0, (t, p) => t + p.value);
        if (total == 0) return (_empty(context, 'No loan interest paid in this period.'), false);
        final labels = [for (final p in pts) cal.monthShort(p.label)];
        final series = [[for (final p in pts) p.value / 100]];
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            config.chart == ReportChart.line
                ? PaisaLineChart(labels: labels, series: series, colors: [c.red])
                : PaisaBarChart(labels: labels, series: series, colors: [c.red]),
            const SizedBox(height: 8),
            LegendRow(label: 'Interest paid', amount: total, color: c.red),
            if (config.compare) _compare(context, 'Interest', total, pointsFor(previousRange(range, cal: cal)).fold<Paisa>(0, (t, p) => t + p.value)),
          ]),
          false,
        );
      case ReportWidgetType.savingsRate:
        final pts = savingsSeries(i.txs, range, accountIds: accounts, cal: cal);
        if (pts.every((p) => p.saved == 0)) return (_empty(context, 'No income or spending in this period.'), false);
        final labels = [for (final p in pts) cal.monthShort(p.month)];
        final series = [[for (final p in pts) p.rate * 100]];
        final withIncome = pts.where((p) => p.rate != 0).toList();
        final avg = withIncome.isEmpty ? 0 : (withIncome.fold<double>(0, (t, p) => t + p.rate) / withIncome.length * 100).round();
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            config.chart == ReportChart.bar
                ? PaisaBarChart(labels: labels, series: series, colors: [c.positive])
                : PaisaLineChart(labels: labels, series: series, colors: [c.positive]),
            const SizedBox(height: 8),
            LegendRow(label: 'Saved in this period', amount: pts.last.cumulative, color: c.positive),
            Text('Average savings rate $avg% · aim for 20%', style: PaisaText.sub.copyWith(color: c.ink2)),
          ]),
          false,
        );
      case ReportWidgetType.topPayees:
        List<ReportSlice> payees(DateRange r) => topPayees(i.txs, r, i.parties, accountIds: accounts);
        final top = payees(range);
        if (top.isEmpty) return (_empty(context, 'Pick “Paid to” on expenses to see who you pay most.'), false);
        final total = top.fold<Paisa>(0, (t, s) => t + s.value);
        return (
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (config.chart == ReportChart.bar)
              PaisaBarChart(
                labels: [for (final s in top) s.label.length > 6 ? s.label.substring(0, 6) : s.label],
                series: [[for (final s in top) s.value / 100]],
                colors: [palette.first],
              ),
            SliceList(slices: top, colors: palette),
            if (config.compare) _compare(context, 'Paid', total, payees(previousRange(range, cal: cal)).fold<Paisa>(0, (t, s) => t + s.value)),
          ]),
          false,
        );
    }
  }
}
