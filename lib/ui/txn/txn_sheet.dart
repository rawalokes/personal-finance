import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/dialog.dart';
import '../components/indicators.dart';
import '../components/layout.dart';
import '../components/money_text.dart';
import '../components/sheet.dart';
import '../components/toast.dart';
import '../components/tone.dart';
import '../feedback.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../typography.dart';
import 'txn_presentation.dart';

/// Transaction detail sheet: amount, facts, what it means for totals, and
/// Delete (confirm → reverse → toast with Undo).
Future<void> showTxnSheet(BuildContext context, Txn t) {
  return showPaisaSheet<void>(
    context,
    title: t.title,
    builder: (ctx) => _TxnSheetBody(t),
    footerBuilder: (ctx) => Consumer(builder: (ctx, ref, _) {
      return Row(children: [
        Expanded(
          child: PaisaButton(
            label: 'Delete',
            icon: PaisaIcons.trash,
            variant: ButtonVariant.danger,
            onPressed: () => _confirmDelete(ctx, ref, t),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PaisaButton(label: 'Done', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop()),
        ),
      ]);
    }),
  );
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Txn t) async {
  final choice = await showConfirmDialog(
    context,
    title: 'Delete this transaction?',
    body: 'Balances${t.type == TxType.loanRepayment ? ', the loan' : ''} and totals will be reversed. '
        'You can undo right after.',
    okLabel: 'Delete',
    okVariant: ButtonVariant.danger,
  );
  if (choice != ConfirmChoice.ok || !context.mounted) return;
  final toast = ref.read(toastProvider.notifier);
  try {
    final undo = await ref.read(transactionRepoProvider).delete(t.id);
    if (context.mounted) Navigator.of(context).pop();
    showUndoToast(toast, 'Transaction deleted', undo);
  } catch (_) {
    toast.show('Couldn’t delete — nothing was changed');
  }
}

class _TxnSheetBody extends ConsumerWidget {
  const _TxnSheetBody(this.t);
  final Txn t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lookup = ref.watch(txnLookupProvider).value;
    final money = ref.watch(moneyFormatProvider);
    if (lookup == null) return const SizedBox(height: 120);
    final view = describeTxn(t, lookup, today: ref.watch(clockProvider).today(), money: money);
    final color = switch (view.tone) {
      AmountTone.positive => c.positive,
      AmountTone.ink => c.ink,
      AmountTone.muted => c.ink2,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MoneyText(
        view.amount,
        sign: view.sign,
        color: color,
        style: PaisaText.h1.copyWith(fontSize: 30, fontVariations: const [FontVariation('wght', 650)]),
      ),
      const SizedBox(height: 14),
      KeyValueCard(
        color: c.surface2,
        rows: [for (final (k, v) in txnDetailRows(t, lookup, money)) KeyValueRow(k, value: v)],
      ),
      const SizedBox(height: 14),
      Note(kTxTypeNote[t.type]!, tone: Tone.blue),
    ]);
  }
}
