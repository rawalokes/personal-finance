import 'package:flutter/material.dart';

import '../components/money_text.dart';
import '../components/surfaces.dart';
import '../theme.dart';
import '../typography.dart';
import 'txn_presentation.dart';

/// One transaction row: icon well, title, subtitle, signed amount and a
/// small trailing line ([view.dateText] by default, or [view.meta]).
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.view, required this.onTap, this.showMeta = false});

  final TxnView view;
  final VoidCallback onTap;

  /// History shows the time ('SMS · 18:02'); other lists show the day.
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (view.tone) {
      AmountTone.positive => c.positive,
      AmountTone.ink => c.ink,
      AmountTone.muted => c.ink2,
    };
    return ListRow(
      title: view.title,
      subtitle: view.subtitle,
      leading: IconWell(icon: view.icon, tone: view.iconTone),
      onTap: onTap,
      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        MoneyText(
          view.amount,
          sign: view.sign,
          color: color,
          style: PaisaText.body.copyWith(fontVariations: const [FontVariation('wght', 700)]),
        ),
        Text(showMeta ? view.meta : view.dateText, style: PaisaText.hint.copyWith(fontSize: 12, color: c.ink3)),
      ]),
    );
  }
}
