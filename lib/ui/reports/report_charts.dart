import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../finance/finance.dart';
import '../components/money_text.dart';
import '../theme.dart';
import '../typography.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// 'Oct' for '2026-10'.
String shortMonth(String monthKey) => _months[int.parse(monthKey.substring(5, 7)) - 1];

/// Series colours, in order.
List<Color> chartPalette(BuildContext context) {
  final c = context.colors;
  return [c.primary, c.positive, c.amber, c.blue, c.red, c.ink3];
}

/// The [n] biggest slices and one "Other" for the rest.
List<ReportSlice> topSlices(List<ReportSlice> s, {int n = 6}) {
  if (s.length <= n) return s;
  final rest = s.skip(n - 1).fold<Paisa>(0, (t, x) => t + x.value);
  return [...s.take(n - 1), ReportSlice('other', 'Other', rest)];
}

/// Axis labels only — amounts never go on axes or tooltips, so "Hide
/// balances" can't leak through a chart.
FlTitlesData _titles(BuildContext context, List<String> labels) {
  final c = context.colors;
  return FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final i = value.round();
          if (i < 0 || i >= labels.length || value != i.toDouble()) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(labels[i], style: PaisaText.hint.copyWith(color: c.ink3), overflow: TextOverflow.ellipsis),
          );
        },
      ),
    ),
  );
}

(double, double) _yRange(List<List<double>> series) {
  final all = [for (final s in series) ...s];
  final hi = all.isEmpty ? 0.0 : all.reduce(math.max);
  final lo = all.isEmpty ? 0.0 : all.reduce(math.min);
  final minY = lo < 0 ? lo * 1.15 : 0.0;
  final maxY = hi > 0 ? hi * 1.15 : (minY < 0 ? 0.0 : 1.0);
  return (minY, maxY);
}

/// Grouped bars; [series][s][i] is series s at label i. [faded] label
/// indexes are forecasts.
class PaisaBarChart extends StatelessWidget {
  const PaisaBarChart({super.key, required this.labels, required this.series, required this.colors, this.faded = const {}, this.height = 160});

  final List<String> labels;
  final List<List<double>> series;
  final List<Color> colors;
  final Set<int> faded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (minY, maxY) = _yRange(series);
    return SizedBox(
      height: height,
      child: BarChart(BarChartData(
        minY: minY,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, labels),
        barGroups: [
          for (var i = 0; i < labels.length; i++)
            BarChartGroupData(x: i, barsSpace: 3, barRods: [
              for (var s = 0; s < series.length; s++)
                BarChartRodData(
                  toY: series[s][i],
                  color: faded.contains(i) ? colors[s].withValues(alpha: 0.4) : colors[s],
                  width: series.length > 1 ? 7 : 12,
                  borderRadius: BorderRadius.circular(3),
                ),
            ]),
        ],
      )),
    );
  }
}

/// Lines; points from [forecastFrom] on are drawn dashed.
class PaisaLineChart extends StatelessWidget {
  const PaisaLineChart({super.key, required this.labels, required this.series, required this.colors, this.forecastFrom, this.height = 160});

  final List<String> labels;
  final List<List<double>> series;
  final List<Color> colors;
  final int? forecastFrom;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (minY, maxY) = _yRange(series);
    final split = forecastFrom ?? labels.length;
    return SizedBox(
      height: height,
      child: LineChart(LineChartData(
        minX: 0,
        maxX: math.max(1, labels.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, labels),
        lineBarsData: [
          for (var s = 0; s < series.length; s++) ...[
            LineChartBarData(
              spots: [for (var i = 0; i < split; i++) FlSpot(i.toDouble(), series[s][i])],
              color: colors[s],
              barWidth: 2.5,
              dotData: FlDotData(show: split == 1),
            ),
            if (split < labels.length && split > 0)
              LineChartBarData(
                spots: [for (var i = split - 1; i < labels.length; i++) FlSpot(i.toDouble(), series[s][i])],
                color: colors[s].withValues(alpha: 0.6),
                barWidth: 2,
                dashArray: const [5, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
        ],
      )),
    );
  }
}

class PaisaDonut extends StatelessWidget {
  const PaisaDonut({super.key, required this.values, required this.colors, this.size = 140});

  final List<double> values;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: size * 0.28,
          pieTouchData: PieTouchData(enabled: false),
          sections: [
            for (var i = 0; i < values.length; i++)
              PieChartSectionData(value: values[i], color: colors[i % colors.length], radius: size * 0.18, showTitle: false),
          ],
        )),
      );
}

/// Coloured dot, label and amount.
class LegendRow extends StatelessWidget {
  const LegendRow({super.key, required this.label, required this.amount, this.color, this.trailing});

  final String label;
  final Paisa amount;
  final Color? color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = color == null
        ? null
        : Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    final name = Text(label, style: PaisaText.sub.copyWith(color: c.ink2), overflow: TextOverflow.ellipsis);
    final value = Wrap(children: [
      MoneyText(amount, style: PaisaText.sub),
      if (trailing != null) Text(' · $trailing', style: PaisaText.sub.copyWith(color: c.ink3)),
    ]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      // Half-width cards are too narrow for label and amount on one line.
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 240
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [?dot, Expanded(child: name)]),
                value,
              ])
            : Row(children: [?dot, Expanded(child: name), value]),
      ),
    );
  }
}

/// Slices as legend rows with their share of the total.
class SliceList extends StatelessWidget {
  const SliceList({super.key, required this.slices, required this.colors});

  final List<ReportSlice> slices;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<Paisa>(0, (t, s) => t + s.value);
    return Column(children: [
      for (var i = 0; i < slices.length; i++)
        LegendRow(
          label: slices[i].label,
          amount: slices[i].value,
          color: colors[i % colors.length],
          trailing: total > 0 ? '${(slices[i].value * 100 / total).round()}%' : null,
        ),
    ]);
  }
}
