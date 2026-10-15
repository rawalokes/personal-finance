import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/money.dart';
import '../../store/ui_state.dart';
import '../theme.dart';
import '../typography.dart';

/// Every displayed amount goes through this widget so "hide balances" and
/// the grouping preference apply everywhere.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.color,
    this.sign = '',
    this.withCurrency = true,
    this.short = false,
  });

  final Paisa amount;
  final TextStyle? style;
  final Color? color;

  /// '+', [kMinus] or '' — prefixed like "+ NPR 1,500".
  final String sign;
  final bool withCurrency;
  final bool short;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final text = short
        ? f.short(amount)
        : withCurrency
            ? f.signed(amount, sign)
            : f.plain(amount);
    final base = PaisaText.numeric(style ?? PaisaText.body);
    return Text(
      text,
      maxLines: 1,
      // Never break "NPR 3,85,000" after "NPR": a clipped second line would
      // hide every digit. Too-long amounts end in an ellipsis instead.
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: base.copyWith(color: color ?? base.color ?? context.colors.ink),
      semanticsLabel: f.masked ? 'Amount hidden' : null,
    );
  }
}
