import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/reports.dart';
import '../../../store/ui_state.dart';
import '../../components/indicators.dart';
import '../../components/money_text.dart';
import '../../theme.dart';
import '../../typography.dart';

/// Top of Home: this month's plan — what to save, what to repay, how the
/// budgets are doing — then what you have and what is really free to spend.
class PlanHero extends ConsumerWidget {
  const PlanHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final p = ref.watch(monthPlanProvider).value;
    if (p == null) return const SizedBox(height: 220);
    final cal = ref.watch(monthCalendarProvider);
    final today = ref.watch(clockProvider).today();
    final categories = ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    final money = ref.watch(moneyFormatProvider);
    final caps = PaisaText.hint.copyWith(color: c.ink3, letterSpacing: 12.5 * 0.08);
    final sub = PaisaText.sub.copyWith(color: c.ink3);
    final free = p.freeToSpend;
    final freeColor = free < 0 ? c.red : c.ink;

    Widget row(String label, Widget value, {Widget? below}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 104, child: Text(label, style: PaisaText.sub.copyWith(color: c.ink2))),
              Expanded(child: value),
            ]),
            if (below != null) Padding(padding: const EdgeInsets.only(left: 104, top: 4), child: below),
          ]),
        );

    // Save.
    final Widget save;
    if (p.saveTarget == 0) {
      save = row('Save', Text('Add your income or a goal to get a target', style: sub));
    } else {
      final behind = p.behindBy;
      final (status, color) = p.saveLeft == 0
          ? ('Target reached 🎉', c.positive)
          : behind > 0
              ? ('Behind by ${money.npr(behind)}', c.red)
              : behind < 0
                  ? ('Ahead by ${money.npr(-behind)}', c.positive)
                  : ('On track', c.positive);
      save = row(
        'Save',
        Wrap(children: [
          MoneyText(p.saved, style: PaisaText.sub.copyWith(color: c.ink)),
          Text(' of ', style: sub),
          MoneyText(p.saveTarget, style: PaisaText.sub.copyWith(color: c.ink)),
        ]),
        below: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ProgressBar(value: p.saved / p.saveTarget, color: color),
          const SizedBox(height: 3),
          Text(status, style: PaisaText.hint.copyWith(color: color)),
        ]),
      );
    }

    // Repay loans.
    Widget? repay;
    if (p.emisDue > 0) {
      final due = p.nextDue;
      final overdue = due != null && due.compareTo(today) < 0;
      repay = row(
        'Repay loans',
        p.emiLeft == 0
            ? Text('All EMIs paid ✓', style: PaisaText.sub.copyWith(color: c.positive))
            : Wrap(children: [
                MoneyText(p.emiLeft, style: PaisaText.sub.copyWith(color: overdue ? c.red : c.ink)),
                Text(
                  due == null ? '' : overdue ? ' · overdue since ${cal.shortDate(due)}' : ' · due ${cal.shortDate(due)}',
                  style: PaisaText.sub.copyWith(color: overdue ? c.red : c.ink3),
                ),
              ]),
        below: Text('${p.emisPaid} of ${p.emisDue} EMIs paid', style: PaisaText.hint.copyWith(color: c.ink3)),
      );
    }

    // Budgets.
    Widget? budgets;
    if (p.budgetsSet > 0) {
      final closest = p.closestBudget;
      final name = closest == null ? null : categories.where((x) => x.id == closest.$1).firstOrNull?.name;
      final parts = [
        p.budgetsOver == 0 ? 'All within budget' : '${p.budgetsOver} over',
        if (name != null) '$name ${(closest!.$2 * 100).round()}% used',
      ];
      budgets = row('Budgets', Text(parts.join(' · '), style: PaisaText.sub.copyWith(color: p.budgetsOver > 0 ? c.red : c.ink)));
    }

    final netColor = p.netWorth < 0 ? c.red : c.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('${cal.monthLong(p.month).toUpperCase()} PLAN', style: caps)),
          Text(p.daysLeft == 1 ? '1 day left' : '${p.daysLeft} days left', style: PaisaText.hint.copyWith(color: c.ink3)),
        ]),
        const SizedBox(height: 12),
        save,
        ?repay,
        ?budgets,
        Divider(color: c.line, height: 16),
        row('You have', MoneyText(p.youHave, style: PaisaText.sub.copyWith(color: c.ink))),
        const SizedBox(height: 4),
        Text('FREE TO SPEND', style: caps),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText(free, withCurrency: false, style: PaisaText.balance, color: freeColor),
            ),
          ),
          const SizedBox(width: 6),
          Text('NPR', style: PaisaText.h2.copyWith(color: c.ink3, letterSpacing: 0)),
        ]),
        Text(free < 0 ? 'Short by ${money.npr(-free)} — after saving and EMIs' : 'after saving and EMIs', style: sub),
        const SizedBox(height: 8),
        Row(children: [
          Text('Net worth', style: PaisaText.body.copyWith(fontSize: 14, color: netColor)),
          const SizedBox(width: 6),
          Flexible(child: MoneyText(p.netWorth, color: netColor, style: PaisaText.body.copyWith(fontSize: 14))),
        ]),
      ]),
    );
  }
}
