import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/records.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../accounts/account_presentation.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../components/tone.dart';
import '../../components/top_bar.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';
import 'add_account_sheet.dart';

class _AccountsData {
  const _AccountsData(this.accounts, this.summary, this.loans, this.types);
  final List<Account> accounts;
  final BalanceSummary summary;
  final List<Loan> loans;
  final List<ConfigItem> types;
}

final _accountsDataProvider = FutureProvider<_AccountsData>((ref) async => _AccountsData(
      await ref.watch(accountsProvider.future),
      await ref.watch(balanceSummaryProvider.future),
      await ref.watch(loansProvider.future),
      await ref.watch(accountTypesProvider.future),
    ));

/// Accounts tab: net worth bar, accounts by group, loans link.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaTopBar(title: 'Accounts', actions: [
        PaisaIconButton(icon: PaisaIcons.plus, label: 'Add account', onPressed: () => showAddAccountSheet(context)),
      ]),
      Expanded(
        child: AsyncView(
          value: ref.watch(_accountsDataProvider),
          data: (d) => _AccountsBody(d),
        ),
      ),
    ]);
  }
}

class _AccountsBody extends StatelessWidget {
  const _AccountsBody(this.d);
  final _AccountsData d;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final live = d.accounts.where((a) => !a.archived).toList();
    final archived = d.accounts.length - live.length;
    final activeLoans = d.loans.where((l) => !l.closed && l.outstanding > 0).length;
    final hasLoans = d.loans.isNotEmpty;
    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      if (live.isEmpty && !hasLoans)
        EmptyState(
          icon: PaisaIcons.wallet,
          title: 'No accounts yet',
          body: 'Add a bank, wallet, cash or card with its current balance. Linked SMS can keep it up to date.',
          actionLabel: 'Add your first account',
          onAction: () => showAddAccountSheet(context),
        )
      else
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: NetWorthCard(summary: d.summary)),
      for (final g in kAccountGroups)
        if (live.any((a) => a.group == g.group)) ...[
          SectionHeader(
            title: g.title,
            subtitle: g.subtitle,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            trailing: MoneyText(
              shownBalance(g.group, _total(live, g.group)),
              sign: owedSign(g.group, _total(live, g.group)),
              color: switch (g.group) {
                AccountGroup.liquid => c.primary,
                AccountGroup.liability => isOwed(g.group, _total(live, g.group)) ? c.red : c.ink,
                _ => c.ink,
              },
              style: PaisaText.body.copyWith(fontVariations: const [FontVariation('wght', 600)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: PaisaListCard(children: [
              for (final a in live.where((a) => a.group == g.group)) _AccountRow(account: a, types: d.types),
            ]),
          ),
        ],
      if (hasLoans) ...[
        SectionHeader(
          title: 'Loans',
          subtitle: 'Tracked in Plans · $activeLoans active',
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          trailing: MoneyText(
            d.summary.loans,
            color: c.red,
            style: PaisaText.body.copyWith(fontVariations: const [FontVariation('wght', 600)]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: PaisaCard(
            padding: EdgeInsets.zero,
            onTap: () => context.go('/plans?seg=loans'),
            child: ListRow(
              title: 'View loans & schedules',
              leading: const IconWell(icon: PaisaIcons.rupee, tone: Tone.amber),
              trailing: PaisaIcon(PaisaIcons.chevR, size: 19, color: c.ink3),
            ),
          ),
        ),
      ],
      if (archived > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('$archived archived account(s) hidden from totals', style: PaisaText.sub.copyWith(color: c.ink3)),
        ),
    ]);
  }
}

Paisa _total(List<Account> accounts, AccountGroup group) =>
    accounts.where((a) => a.group == group).fold(0, (t, a) => t + a.balance);

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.types});
  final Account account;
  final List<ConfigItem> types;

  @override
  Widget build(BuildContext context) {
    final a = account;
    final owed = isOwed(a.group, a.balance);
    final type = isInCredit(a.group, a.balance) ? '${accountTypeLabel(a, types)} · in credit' : accountTypeLabel(a, types);
    return ListRow(
      title: a.name,
      subtitle: a.note == null ? type : '$type · ${a.note}',
      leading: IconWell(icon: accountIcon(a), tone: accountTone(a)),
      onTap: () => context.push('/accounts/${a.id}'),
      trailing: MoneyText(
        shownBalance(a.group, a.balance),
        sign: owedSign(a.group, a.balance),
        color: owed ? context.colors.red : null,
        style: PaisaText.body.copyWith(fontVariations: const [FontVariation('wght', 700)]),
      ),
    );
  }
}

/// Net worth with the liquid / reserved / locked / owed bar and legend.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({super.key, required this.summary});
  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = summary;
    final parts = [
      (s.liquid, c.primary, 'Liquid'),
      (s.reserved, c.reservedBar, 'Reserved'),
      (s.locked, c.lockedBar, 'Locked'),
      (s.liabilities, c.red, 'Owed'),
    ];
    final total = parts.fold<int>(0, (t, p) => t + (p.$1 > 0 ? p.$1 : 0));
    return PaisaCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Net worth', style: PaisaText.sub.copyWith(color: c.ink3)),
        const SizedBox(height: 12),
        MoneyText(s.netWorth, style: PaisaText.h1.copyWith(fontSize: 30, fontVariations: const [FontVariation('wght', 650)])),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 12,
            child: Row(children: [
              for (final (value, color, _) in parts)
                if (value > 0 && total > 0)
                  Expanded(
                    flex: (value * 1000 ~/ total).clamp(1, 1000).toInt(),
                    child: Padding(padding: const EdgeInsets.only(right: 2), child: ColoredBox(color: color)),
                  ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(runSpacing: 6, children: [
          for (final (value, color, label) in parts)
            FractionallySizedBox(
              widthFactor: 0.5,
              child: Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('$label ', maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.hint.copyWith(color: c.ink2)),
                ),
                MoneyText(value, short: true, style: PaisaText.hint.copyWith(color: c.ink2)),
              ]),
            ),
        ]),
      ]),
    );
  }
}
