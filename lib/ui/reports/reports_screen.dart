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
import '../../store/data_providers.dart';
import '../components/buttons.dart';
import '../components/dialog.dart';
import '../components/sheet.dart';
import '../components/surfaces.dart';
import '../components/toast.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../typography.dart';
import 'report_widget_sheet.dart';

/// Reports tab (spec §3): "For you" nudges, then the user's widgets.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  /// "One period for all", not saved.
  ReportPeriod? _override;
  bool _editing = false;

  Future<void> _save(List<ReportWidgetConfig> widgets) => ref.read(settingsRepoProvider).saveDashboard(DashboardConfig(widgets));

  Future<void> _remove(List<ReportWidgetConfig> widgets, ReportWidgetConfig w) async {
    await _save([for (final x in widgets) if (x.id != w.id) x]);
    ref.read(toastProvider.notifier).show('${w.type.title} removed', onUndo: () => _save(widgets));
  }

  Future<void> _add(List<ReportWidgetConfig> widgets) async {
    final type = await showPaisaSheet<ReportWidgetType>(
      context,
      title: 'Add widget',
      builder: (ctx) => PaisaListCard(children: [
        for (final t in ReportWidgetType.values)
          ListRow(title: t.title, subtitle: t.description, onTap: () => Navigator.of(ctx).pop(t)),
      ]),
    );
    if (type == null) return;
    await _save([...widgets, ReportWidgetConfig.create(ref.read(idGenProvider)(), type)]);
    ref.read(toastProvider.notifier).show('${type.title} added');
  }

  Future<void> _configure(List<ReportWidgetConfig> widgets, ReportWidgetConfig w) async {
    final next = await showReportWidgetSheet(context, w);
    if (next == null) return;
    await _save([for (final x in widgets) x.id == w.id ? next : x]);
  }

  Future<void> _reset() async {
    final choice = await showConfirmDialog(
      context,
      title: 'Reset Reports?',
      body: 'Your widgets go back to the starting layout.',
      okLabel: 'Reset',
    );
    if (choice != ConfirmChoice.ok) return;
    await ref.read(settingsRepoProvider).resetDashboard();
    ref.read(toastProvider.notifier).show('Reports reset');
  }

  String _summary(ReportWidgetConfig w) => [
        w.size == WidgetSize.half ? 'Half width' : 'Full width',
        if (w.type.charts.length > 1) w.chart.label,
        if (w.type.settings.contains(WidgetSetting.period)) w.period.label,
      ].join(' · ');

  Widget _editList(List<ReportWidgetConfig> widgets) {
    final c = context.colors;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      buildDefaultDragHandles: false,
      itemCount: widgets.length,
      onReorderItem: (from, to) {
        final list = [...widgets];
        list.insert(to, list.removeAt(from));
        _save(list);
      },
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaButton(label: 'Add widget', icon: PaisaIcons.plus, variant: ButtonVariant.outline, onPressed: () => _add(widgets)),
          const SizedBox(height: 8),
          PaisaButton(label: 'Reset to default', variant: ButtonVariant.ghost, onPressed: _reset),
        ]),
      ),
      itemBuilder: (ctx, k) {
        final w = widgets[k];
        return Padding(
          key: ValueKey(w.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: PaisaCard(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: Row(children: [
              ReorderableDragStartListener(
                key: ValueKey('drag-${w.id}'),
                index: k,
                child: Semantics(
                  label: 'Drag to move ${w.type.title}',
                  child: Padding(padding: const EdgeInsets.all(12), child: PaisaIcon(PaisaIcons.dots, size: 20, color: c.ink3)),
                ),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.type.title, style: PaisaText.h3.copyWith(color: c.ink)),
                  Text(_summary(w), style: PaisaText.hint.copyWith(color: c.ink3)),
                ]),
              ),
              PaisaIconButton(icon: PaisaIcons.sliders, label: 'Settings for ${w.type.title}', onPressed: () => _configure(widgets, w)),
              PaisaIconButton(icon: PaisaIcons.close, label: 'Remove ${w.type.title}', onPressed: () => _remove(widgets, w)),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(challengeRolloverProvider);
    final nudges = ref.watch(nudgesProvider).value ?? const <Nudge>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaTopBar(title: 'Reports', actions: [
        PaisaLink(label: _editing ? 'Done' : 'Edit', onPressed: () => setState(() => _editing = !_editing)),
      ]),
      if (!_editing)
      ChipRow(children: [
        PaisaChip(label: 'As set', selected: _override == null, onTap: () => setState(() => _override = null)),
        for (final p in ReportPeriod.values) PaisaChip(label: p.label, selected: _override == p, onTap: () => setState(() => _override = p)),
      ]),
      const SizedBox(height: 6),
      Expanded(
        child: AsyncView(
          value: ref.watch(dashboardProvider),
          data: (d) => _editing ? _editList(d.widgets) : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
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
