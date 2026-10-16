import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_settings.dart';
import '../../finance/finance.dart';
import '../../store/reports.dart';
import '../components/buttons.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/sheet.dart';

class _WidgetForm extends ChangeNotifier {
  _WidgetForm(this.config);
  ReportWidgetConfig config;
  void set(ReportWidgetConfig c) {
    config = c;
    notifyListeners();
  }
}

List<String> _toggled(List<String> ids, String id) => ids.contains(id) ? [for (final x in ids) if (x != id) x] : [...ids, id];

/// ⚙ for one widget: only the settings its type uses (spec §3.4).
Future<ReportWidgetConfig?> showReportWidgetSheet(BuildContext context, ReportWidgetConfig config) =>
    showPaisaFormSheet<ReportWidgetConfig, _WidgetForm>(
      context,
      title: config.type.title,
      create: () => _WidgetForm(config),
      body: (ctx, f) => Consumer(builder: (ctx, ref, _) {
        final i = ref.watch(reportInputsProvider).value;
        final w = f.config;
        final s = w.type.settings;
        Widget gap() => const SizedBox(height: 14);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (s.contains(WidgetSetting.period)) ...[
            FieldGroup(
              label: 'Period',
              child: ChipWrap(children: [
                for (final p in ReportPeriod.values) PaisaChip(label: p.label, selected: w.period == p, onTap: () => f.set(w.copyWith(period: p))),
              ]),
            ),
            gap(),
          ],
          if (s.contains(WidgetSetting.accounts) && i != null) ...[
            FieldGroup(
              label: 'Accounts',
              child: ChipWrap(children: [
                PaisaChip(label: 'All', selected: w.accountIds.isEmpty, onTap: () => f.set(w.copyWith(accountIds: const []))),
                for (final a in i.accounts)
                  if (!a.archived)
                    PaisaChip(label: a.shortName, selected: w.accountIds.contains(a.id), onTap: () => f.set(w.copyWith(accountIds: _toggled(w.accountIds, a.id)))),
              ]),
            ),
            gap(),
          ],
          if (s.contains(WidgetSetting.categories) && i != null) ...[
            FieldGroup(
              label: 'Categories',
              child: ChipWrap(children: [
                PaisaChip(label: 'All', selected: w.categoryIds.isEmpty, onTap: () => f.set(w.copyWith(categoryIds: const []))),
                for (final x in i.categories)
                  if (x.active && x.isTopLevel)
                    PaisaChip(label: x.name, selected: w.categoryIds.contains(x.id), onTap: () => f.set(w.copyWith(categoryIds: _toggled(w.categoryIds, x.id)))),
              ]),
            ),
            gap(),
          ],
          if (s.contains(WidgetSetting.loans) && i != null) ...[
            FieldGroup(
              label: 'Loans',
              child: ChipWrap(children: [
                PaisaChip(label: 'All', selected: w.loanIds.isEmpty, onTap: () => f.set(w.copyWith(loanIds: const []))),
                for (final l in i.loans)
                  if (!l.closed) PaisaChip(label: l.name, selected: w.loanIds.contains(l.id), onTap: () => f.set(w.copyWith(loanIds: _toggled(w.loanIds, l.id)))),
              ]),
            ),
            gap(),
          ],
          if (s.contains(WidgetSetting.groupBy)) ...[
            FieldGroup(
              label: 'Group by',
              child: Segmented<IncomeGrouping>(
                segments: const [(IncomeGrouping.type, 'Income type'), (IncomeGrouping.party, 'Party')],
                selected: w.groupBy,
                onChanged: (g) => f.set(w.copyWith(groupBy: g)),
              ),
            ),
            gap(),
          ],
          if (w.type.charts.length > 1) ...[
            FieldGroup(
              label: 'Chart',
              child: Segmented<ReportChart>(
                segments: [for (final ch in w.type.charts) (ch, ch.label)],
                selected: w.chart,
                onChanged: (ch) => f.set(w.copyWith(chart: ch)),
              ),
            ),
            gap(),
          ],
          FieldGroup(
            label: 'Size',
            child: Segmented<WidgetSize>(
              segments: const [(WidgetSize.half, 'Half width'), (WidgetSize.full, 'Full width')],
              selected: w.size,
              onChanged: (z) => f.set(w.copyWith(size: z)),
            ),
          ),
          if (s.contains(WidgetSetting.compare)) ...[
            gap(),
            ToggleRow(title: 'Compare with the previous period', value: w.compare, onChanged: (v) => f.set(w.copyWith(compare: v))),
          ],
        ]);
      }),
      footer: (ctx, f) => Row(children: [
        Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: PaisaButton(label: 'Save', onPressed: () => Navigator.of(ctx).pop(f.config))),
      ]),
    );
