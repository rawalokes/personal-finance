import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../components/top_bar.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/transaction_tile.dart';
import '../../txn/txn_presentation.dart';
import '../../txn/txn_query.dart';
import '../../txn/txn_sheet.dart';

final _historyDataProvider = FutureProvider<(List<Txn>, TxnLookup)>(
  (ref) async => (await ref.watch(transactionsProvider.future), await ref.watch(txnLookupProvider.future)),
);

/// Activity tab, titled "Transactions": History with type and date filters,
/// grouped by day. Plan 3 adds the Transaction Inbox segment.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  TxnFilter _filter = TxnFilter.all;
  TxnRange _range = TxnRange.month;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaTopBar(title: 'Transactions', actions: [
        PaisaIconButton(icon: PaisaIcons.search, label: 'Search and filter', onPressed: () => context.push('/search')),
        PaisaIconButton(icon: PaisaIcons.plus, label: 'Add expense', onPressed: () => context.push('/expense/new')),
      ]),
      Expanded(child: AsyncView(value: ref.watch(_historyDataProvider), data: (d) => _history(d.$1, d.$2))),
    ]);
  }

  Widget _history(List<Txn> all, TxnLookup lookup) {
    final c = context.colors;
    final today = ref.watch(clockProvider).today();
    final money = ref.watch(moneyFormatProvider);
    final shown = all.where((t) => _range.contains(t, today) && _filter.matches(t)).toList();
    final groups = groupByDay(shown, today);
    final (moneyIn, moneyOut) = inOutTotals(shown);
    final tileValue = PaisaText.body.copyWith(fontVariations: const [FontVariation('wght', 600)]);
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      ChipRow(children: [
        for (final f in TxnFilter.values)
          PaisaChip(label: f.label, selected: f == _filter, onTap: () => setState(() => _filter = f)),
      ]),
      const SizedBox(height: 4),
      ChipRow(children: [
        for (final r in TxnRange.values)
          PaisaChip(
            label: r.label(today),
            icon: PaisaIcons.calendar,
            selected: r == _range,
            onTap: () => setState(() => _range = r),
          ),
      ]),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          Expanded(
            child: PaisaCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Money in', style: PaisaText.sub.copyWith(color: c.ink3)),
                MoneyText(moneyIn, color: c.positive, style: tileValue),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PaisaCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Money out', style: PaisaText.sub.copyWith(color: c.ink3)),
                MoneyText(moneyOut, style: tileValue),
              ]),
            ),
          ),
        ]),
      ),
      if (groups.isEmpty)
        EmptyState(
          icon: PaisaIcons.list,
          title: 'No transactions here',
          body: 'Nothing matches this filter and date range.',
          actionLabel: 'Show all transactions',
          onAction: () => setState(() {
            _filter = TxnFilter.all;
            _range = TxnRange.all;
          }),
        ),
      for (final g in groups) ...[
        SectionHeader(
          title: g.label,
          caps: true,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          trailing: g.net == 0
              ? null
              : Text(
                  '${g.net > 0 && !money.masked ? '+' : ''}${money.plain(g.net)}',
                  style: PaisaText.numeric(PaisaText.sub.copyWith(color: c.ink3)),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PaisaListCard(children: [
            for (final t in g.items)
              TransactionTile(
                view: describeTxn(t, lookup, today: today, money: money),
                showMeta: true,
                onTap: () => showTxnSheet(context, t),
              ),
          ]),
        ),
      ],
    ]);
  }
}
