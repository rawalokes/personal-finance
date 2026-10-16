import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_settings.dart';
import '../../finance/finance.dart';
import '../../store/reports.dart';
import '../components/async_view.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/top_bar.dart';
import '../encourage/nudge_card.dart';
import 'report_widget_card.dart';

/// Reports tab (spec §3): "For you" nudges, then the user's widgets.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  /// "One period for all", not saved.
  ReportPeriod? _override;

  @override
  Widget build(BuildContext context) {
    ref.watch(challengeRolloverProvider);
    final nudges = ref.watch(nudgesProvider).value ?? const <Nudge>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PaisaTopBar(title: 'Reports'),
      ChipRow(children: [
        PaisaChip(label: 'As set', selected: _override == null, onTap: () => setState(() => _override = null)),
        for (final p in ReportPeriod.values) PaisaChip(label: p.label, selected: _override == p, onTap: () => setState(() => _override = p)),
      ]),
      const SizedBox(height: 6),
      Expanded(
        child: AsyncView(
          value: ref.watch(dashboardProvider),
          data: (d) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            if (nudges.isNotEmpty) ...[
              const SectionHeader(title: 'For you', padding: EdgeInsets.fromLTRB(0, 12, 0, 8)),
              for (final n in nudges) Padding(padding: const EdgeInsets.only(bottom: 8), child: NudgeCard(n)),
            ],
            const SizedBox(height: 8),
            ..._grid(d.widgets),
          ]),
        ),
      ),
    ]);
  }

  /// Full-width widgets alone; consecutive half-width widgets side by side.
  List<Widget> _grid(List<ReportWidgetConfig> widgets) {
    final out = <Widget>[];
    for (var k = 0; k < widgets.length; k++) {
      final w = widgets[k];
      Widget card(ReportWidgetConfig x) => ReportWidgetCard(key: ValueKey(x.id), config: x, periodOverride: _override);
      if (w.size == WidgetSize.half) {
        final next = k + 1 < widgets.length && widgets[k + 1].size == WidgetSize.half ? widgets[k + 1] : null;
        out.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: card(w)),
          const SizedBox(width: 10),
          Expanded(child: next == null ? const SizedBox.shrink() : card(next)),
        ]));
        if (next != null) k++;
      } else {
        out.add(card(w));
      }
      out.add(const SizedBox(height: 10));
    }
    return out;
  }
}
