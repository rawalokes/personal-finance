import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/transaction_tile.dart';
import '../../txn/txn_presentation.dart';
import '../../txn/txn_query.dart';
import '../../txn/txn_sheet.dart';

final _searchDataProvider = FutureProvider<(List<Txn>, TxnLookup)>(
  (ref) async => (await ref.watch(transactionsProvider.future), await ref.watch(txnLookupProvider.future)),
);

/// Search (spec §7): text plus type filter across all transactions.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  TxnFilter _filter = TxnFilter.all;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
            child: Row(children: [
              PaisaIconButton(icon: PaisaIcons.chevL, label: 'Back', onPressed: () => leavePage(context)),
              const SizedBox(width: 6),
              Expanded(
                child: PaisaTextField(
                  label: 'Search transactions',
                  showLabel: false,
                  controller: _query,
                  prefixIcon: PaisaIcons.search,
                  hint: 'Merchant, category, amount…',
                  autofocus: true,
                ),
              ),
            ]),
          ),
          ChipRow(children: [
            for (final f in TxnFilter.values)
              PaisaChip(
                label: f == TxnFilter.all ? 'All types' : f.label,
                selected: f == _filter,
                onTap: () => setState(() => _filter = f),
              ),
          ]),
          Expanded(child: AsyncView(value: ref.watch(_searchDataProvider), data: (d) => _results(d.$1, d.$2))),
        ]),
      ),
    );
  }

  Widget _results(List<Txn> all, TxnLookup lookup) {
    final c = context.colors;
    final today = ref.watch(clockProvider).today();
    final money = ref.watch(moneyFormatProvider);
    final q = _query.text.trim();
    final found = all.where((t) => _filter.matches(t) && matchesQuery(t, q, lookup)).toList();
    final count = q.isEmpty
        ? 'All ${found.length} transactions'
        : '${found.length} result${found.length == 1 ? '' : 's'} for “$q”';
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Semantics(liveRegion: true, child: Text(count, style: PaisaText.sub.copyWith(color: c.ink3))),
      ),
      if (found.isEmpty)
        const EmptyState(
          icon: PaisaIcons.search,
          title: 'No matches',
          body: 'Try a merchant name like “Bhat-Bhateni”, a category, or an amount.',
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PaisaListCard(children: [
            for (final t in found)
              TransactionTile(
                view: describeTxn(t, lookup, today: today, money: money),
                onTap: () => showTxnSheet(context, t),
              ),
          ]),
        ),
    ]);
  }
}
