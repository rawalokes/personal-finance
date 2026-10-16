import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/records.dart';
import '../../../data/settings_models.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../components/tone.dart';
import '../../components/top_bar.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';
import 'data_actions.dart';

class _Item {
  const _Item(this.title, this.subtitle, this.icon, this.onTap, {this.tone = Tone.neutral});
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;
  final Tone tone;
}

/// More tab, titled "Settings" (spec §7): financial setup, the AI
/// assistant, preferences, security and data.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    void go(String path) => context.push(path);
    int n<T>(AsyncValue<List<T>> v, bool Function(T) where) => (v.value ?? const []).where(where).length;
    final incomeTypes = ref.watch(incomeTypesProvider);
    final categories = ref.watch(categoriesProvider);
    final loanTypes = ref.watch(loanTypesProvider);
    final recurring = ref.watch(recurringProvider);
    final rules = ref.watch(taxRulesProvider).value;
    final salary = ref.watch(salaryProfileProvider).value;
    final security = ref.watch(securityProvider).value ?? const SecuritySettings();
    final ai = ref.watch(aiSettingsProvider).value ?? const AiSettings();
    final grouping = ref.watch(groupingProvider);
    final calendar = ref.watch(calendarProvider);
    final money = ref.watch(moneyFormatProvider);
    final groups = <(String, List<_Item>)>[
      ('Financial setup', [
        _Item('Income types', '${n(incomeTypes, (IncomeType t) => t.active)} active · salary, freelance, interest…', PaisaIcons.moneyIn,
            () => go('/settings/income-types'), tone: Tone.positive),
        _Item(
          'Salary & deductions',
          salary == null || salary.grossMonthly <= 0 ? 'Not set up · SSF, CIT, tax' : 'Gross ${money.npr(salary.grossMonthly)} · SSF, CIT, tax',
          PaisaIcons.brief,
          () => go('/settings/salary'),
          tone: Tone.positive,
        ),
        _Item(
          'Tax rules',
          rules == null ? 'Income tax brackets' : 'FY ${rules.fiscalYear}${rules.isSampleDefault ? ' · sample defaults — verify' : ' · verified'}',
          PaisaIcons.percent,
          () => go('/settings/tax'),
          tone: Tone.amber,
        ),
        _Item('Expense categories', '${n(categories, (ExpenseCategory x) => x.active && x.isTopLevel)} categories · budgets', PaisaIcons.tag,
            () => go('/settings/categories')),
        _Item('Loan types', '${n(loanTypes, (LoanType t) => t.active)} types', PaisaIcons.rupee, () => go('/loans/types'), tone: Tone.amber),
        _Item('Account types', 'Liquid, reserved, locked or owed', PaisaIcons.wallet, () => go('/settings/config/${ConfigList.accountTypes}')),
        _Item('Contribution types', 'SSF, CIT, provident fund, insurance', PaisaIcons.shield,
            () => go('/settings/config/${ConfigList.contributionTypes}')),
        _Item('Parties', 'Who pays you and who you pay', PaisaIcons.user, () => go('/settings/config/${ConfigList.parties}')),
        _Item('Recurring rules', '${n(recurring, (RecurringRule r) => r.active)} active reminders', PaisaIcons.repeat,
            () => go('/settings/recurring')),
        _Item('Transaction classification rules', 'Rules for suggesting a type from bank SMS', PaisaIcons.sliders,
            () => go('/settings/config/${ConfigList.classificationRules}'), tone: Tone.blue),
        _Item('Banks & wallets', 'SMS senders you trust', PaisaIcons.bank, () => go('/settings/config/${ConfigList.banks}'), tone: Tone.blue),
      ]),
      ('Assistant', [
        _Item(
          'AI assistant',
          ai.enabled ? 'On · Google Gemini with your key · ${ai.privacy.label}' : 'Off · uses your own Google AI key',
          PaisaIcons.bolt,
          () => go('/settings/ai'),
          tone: Tone.blue,
        ),
      ]),
      ('Preferences', [
        _Item(
          'Currency & date',
          'NPR · ${grouping == Grouping.lakh ? 'Lakh grouping' : 'International grouping'} · ${calendar == CalendarPref.bs ? 'Bikram Sambat' : 'AD'}',
          PaisaIcons.calendar,
          () => go('/settings/preferences'),
        ),
        _Item(
          'Security & privacy',
          '${security.appLock ? 'App lock on' : 'App lock off'}${security.blockScreenshots ? ' · screenshots blocked' : ''}',
          PaisaIcons.lock,
          () => go('/settings/security'),
        ),
      ]),
      ('Data', [
        _Item('Export data', 'CSV for spreadsheets or a full JSON backup', PaisaIcons.download, () => showExportSheet(context)),
        _Item('Audit history', 'Every change, with its source', PaisaIcons.file, () => go('/settings/audit')),
        _Item('Delete all data', 'Start again from a clean install', PaisaIcons.trash, () => showDeleteAllSheet(context), tone: Tone.red),
      ]),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PaisaTopBar(title: 'Settings'),
      Expanded(
        child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          for (final (title, items) in groups) ...[
            SectionHeader(title: title, caps: true, padding: const EdgeInsets.fromLTRB(16, 18, 16, 8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PaisaListCard(children: [
                for (final i in items)
                  ListRow(
                    title: i.title,
                    subtitle: i.subtitle,
                    leading: IconWell(icon: i.icon, tone: i.tone, size: 38),
                    trailing: PaisaIcon(PaisaIcons.chevR, size: 19, color: c.ink3),
                    onTap: i.onTap,
                  ),
              ]),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(
              ai.enabled
                  ? 'Paisa · your data stays on this phone, except the summaries you send to Google AI.'
                  : 'Paisa · your data stays on this phone.',
              textAlign: TextAlign.center,
              style: PaisaText.hint.copyWith(color: c.ink3),
            ),
          ),
        ]),
      ),
    ]);
  }
}
