import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/records.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/reports.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../date_line.dart';
import '../../encourage/nudge_card.dart';
import '../../loans/loan_presentation.dart';
import '../../encourage/score_card.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/transaction_tile.dart';
import '../../txn/txn_presentation.dart';
import '../../txn/txn_sheet.dart';
import '../../ai/ai_insight_card.dart';
import 'account_carousel.dart';
import 'plan_hero.dart';

class HomeData {
  const HomeData({
    required this.accounts,
    required this.types,
    required this.summary,
    required this.month,
    required this.loans,
    required this.recent,
    required this.lookup,
  });

  final List<Account> accounts;
  final List<ConfigItem> types;
  final BalanceSummary summary;
  final MonthlyTotals month;
  final List<Loan> loans;
  final List<Txn> recent;
  final TxnLookup lookup;
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  return HomeData(
    accounts: await ref.watch(accountsProvider.future),
    types: await ref.watch(accountTypesProvider.future),
    summary: await ref.watch(balanceSummaryProvider.future),
    month: await ref.watch(monthTotalsProvider.future),
    loans: await ref.watch(loansProvider.future),
    recent: txns.take(3).toList(),
    lookup: await ref.watch(txnLookupProvider.future),
  );
});

String greetingFor(DateTime now) => now.hour < 12
    ? 'Good morning'
    : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

/// 'Debt-free Mar 2029' at the current installments (no extra, no rollover),
/// or null when a loan is never repaid or nothing is owed.
String? debtFreeLabel(List<Loan> loans, IsoDate today, {MonthCalendar cal = const AdCalendar()}) {
  final active = loans.where((l) => !l.closed && l.outstanding > 0).toList();
  if (active.isEmpty) return null;
  final base = simulatePayoff(active, rollover: false);
  if (base.hitLimit || base.months == 0) return null;
  return 'Debt-free ${payoffMonthLabel(today, base.months - 1, cal: cal)}';
}

/// Home tab (spec §7): available to spend, three actions, account cards,
/// SMS bar, this month, loans remaining and recent transactions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masked = ref.watch(hideBalancesProvider);
    final now = ref.watch(clockProvider).now();
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 14, 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greetingFor(now), style: PaisaText.sub.copyWith(fontSize: 14, color: c.ink3)),
              Text(
                homeDateLine(now, ref.watch(calendarProvider)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PaisaText.hint.copyWith(color: c.ink3),
              ),
            ]),
          ),
          PaisaIconButton(
            icon: PaisaIcons.search,
            label: 'Search transactions',
            boxed: true,
            iconSize: 19,
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: 8),
          PaisaIconButton(
            icon: masked ? PaisaIcons.eyeOff : PaisaIcons.eye,
            label: masked ? 'Show balances' : 'Hide balances',
            boxed: true,
            iconSize: 19,
            onPressed: () => ref.read(hideBalancesProvider.notifier).toggle(),
          ),
        ]),
      ),
      Expanded(child: AsyncView(value: ref.watch(homeDataProvider), data: (d) => _HomeBody(d))),
    ]);
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody(this.d);
  final HomeData d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(clockProvider).today();
    final cal = ref.watch(monthCalendarProvider);
    final money = ref.watch(moneyFormatProvider);
    final pending = ref.watch(inboxPendingCountProvider);
    final cards = d.accounts.where((a) => !a.archived && a.group != AccountGroup.locked).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PlanHero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Expanded(child: _QuickAction(icon: PaisaIcons.moneyIn, label: 'Income', onTap: () => context.push('/income/new'))),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: PaisaIcons.moneyOut,
                label: 'Expense',
                highlighted: true,
                onTap: () => context.push('/expense/new'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _QuickAction(icon: PaisaIcons.rupee, label: 'Loans', onTap: () => context.go('/plans?seg=loans'))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 8),
          child: Row(children: [
            Expanded(child: Text('Your accounts · swipe or scroll', style: PaisaText.sub.copyWith(color: c.ink3))),
            PaisaLink(label: 'See all', onPressed: () => context.push('/accounts')),
          ]),
        ),
        AccountCarousel(accounts: cards, types: d.types),
        if (pending > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _PendingBar(count: pending, onTap: () => context.go('/activity?seg=inbox')),
          ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: _MonthCard(month: d.month, today: today, cal: cal)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ScoreCard(compact: true, onTap: () => context.go('/reports')),
        ),
        const _HomeNudges(),
        const AiInsightCard(),
        if (d.summary.loans > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _LoansCard(loans: d.loans, outstanding: d.summary.loans, today: today, cal: cal),
          ),
        SectionHeader(title: 'Recent', trailing: PaisaLink(label: 'See all', onPressed: () => context.go('/activity'))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: d.recent.isEmpty
              ? PaisaCard(
                  padding: const EdgeInsets.all(24),
                  child: Text('No transactions yet.', textAlign: TextAlign.center, style: PaisaText.sub.copyWith(color: c.ink3)),
                )
              : PaisaListCard(children: [
                  for (final t in d.recent)
                    TransactionTile(
                      view: describeTxn(t, d.lookup, today: today, money: money),
                      onTap: () => showTxnSheet(context, t),
                    ),
                ]),
        ),
      ]),
    );
  }
}

/// Round action (`.qa3`); [highlighted] is the mint Expense action.
class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.highlighted = false});
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: highlighted ? c.primary : c.surface, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: PaisaIcon(icon, color: highlighted ? c.onPrimary : c.ink),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: (highlighted ? PaisaText.buttonSmall : PaisaText.sub).copyWith(fontSize: 12.5, color: c.ink),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PendingBar extends StatelessWidget {
  const _PendingBar({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.attentionBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.attentionLine)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$count SMS to review', style: PaisaText.h3.copyWith(color: c.attentionInk)),
                Text('Nothing is saved until you confirm', style: PaisaText.sub.copyWith(color: c.ink3)),
              ]),
            ),
            Text('Review', style: PaisaText.buttonSmall.copyWith(color: c.primary)),
          ]),
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month, required this.today, required this.cal});
  final MonthCalendar cal;
  final MonthlyTotals month;
  final IsoDate today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final net = month.surplus;
    final netColor = net >= 0 ? c.positive : c.red;
    final big = PaisaText.h2.copyWith(fontSize: 19);
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('${cal.monthLong(cal.key(today))} so far', style: PaisaText.sub.copyWith(color: c.ink3))),
          Text('${net >= 0 ? 'Surplus' : 'Deficit'} ', style: PaisaText.sub.copyWith(color: netColor)),
          Flexible(child: MoneyText(net.abs(), sign: net >= 0 ? '+' : kMinus, color: netColor, style: PaisaText.sub)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('In', style: PaisaText.hint.copyWith(color: c.ink3)),
              MoneyText(month.income, color: c.positive, style: big),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Out', style: PaisaText.hint.copyWith(color: c.ink3)),
              MoneyText(month.expenses < 0 ? 0 : month.expenses, style: big),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _LoansCard extends StatelessWidget {
  const _LoansCard({required this.loans, required this.outstanding, required this.today, required this.cal});
  final MonthCalendar cal;
  final List<Loan> loans;
  final Paisa outstanding;
  final IsoDate today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final principal = loans.where((l) => !l.closed && l.outstanding > 0).fold<int>(0, (t, l) => t + l.principal);
    final paid = principal <= 0 ? 0.0 : (1 - outstanding / principal).clamp(0.0, 1.0).toDouble();
    final free = debtFreeLabel(loans, today, cal: cal);
    return PaisaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Loans remaining', style: PaisaText.sub.copyWith(color: c.ink3))),
          Text('${(paid * 100).round()}% repaid', style: PaisaText.sub.copyWith(color: c.ink3)),
        ]),
        const SizedBox(height: 10),
        MoneyText(outstanding, style: PaisaText.h1.copyWith(fontSize: 24)),
        const SizedBox(height: 10),
        ProgressBar(value: paid, semanticLabel: 'Loans repaid'),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: PaisaLink(
            label: '${free == null ? '' : '$free · '}Plan how to pay it off →',
            onPressed: () => context.push('/loans/planner'),
          ),
        ),
      ]),
    );
  }
}

/// The top two nudges (spec §4.1); the rest are on Reports.
class _HomeNudges extends ConsumerWidget {
  const _HomeNudges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(challengeRolloverProvider);
    final nudges = ref.watch(nudgesProvider).value ?? const <Nudge>[];
    if (nudges.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title: 'For you', trailing: PaisaLink(label: 'See all', onPressed: () => context.go('/reports'))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          for (final n in nudges.take(2)) Padding(padding: const EdgeInsets.only(bottom: 8), child: NudgeCard(n)),
        ]),
      ),
    ]);
  }
}
