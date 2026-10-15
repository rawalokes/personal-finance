import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/records.dart';
import '../../../data/settings_models.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../txn/txn_presentation.dart';
import '../../typography.dart';

/// Settings → Currency & date & display.
class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final grouping = ref.watch(groupingProvider);
    final calendar = ref.watch(calendarProvider);
    final theme = ref.watch(themeModeProvider);
    final rules = ref.watch(taxRulesProvider).value;
    Widget hint(String t) => Text(t, style: PaisaText.hint.copyWith(color: c.ink3));
    return DetailPage(
      title: 'Currency, date & display',
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
        KeyValueCard(rows: const [KeyValueRow('Currency', value: 'Nepalese Rupee (NPR)')]),
        const SizedBox(height: 16),
        FieldGroup(
          label: 'Number grouping',
          footer: hint('Example: ${MoneyFormat(grouping: grouping).npr(fromRupees(1255000))}'),
          child: Segmented<Grouping>(
            segments: const [(Grouping.lakh, '1,00,000 (Lakh)'), (Grouping.international, '100,000')],
            selected: grouping,
            onChanged: ref.read(groupingProvider.notifier).set,
          ),
        ),
        const SizedBox(height: 16),
        FieldGroup(
          label: 'Primary calendar',
          footer: hint('Used in the Home header. Transactions keep AD dates.'),
          child: Segmented<CalendarPref>(
            segments: const [(CalendarPref.bs, 'Bikram Sambat'), (CalendarPref.ad, 'Gregorian (AD)')],
            selected: calendar,
            onChanged: ref.read(calendarProvider.notifier).set,
          ),
        ),
        const SizedBox(height: 16),
        FieldGroup(
          label: 'Appearance',
          footer: hint('Night is the default. Both themes use the same design tokens.'),
          child: Segmented<ThemeMode>(
            segments: const [(ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark')],
            selected: theme == ThemeMode.light ? ThemeMode.light : ThemeMode.dark,
            onChanged: ref.read(themeModeProvider.notifier).set,
          ),
        ),
        const SizedBox(height: 16),
        KeyValueCard(rows: [
          KeyValueRow('Fiscal year', value: 'Shrawan – Ashadh${rules == null ? '' : ' · FY ${rules.fiscalYear}'}'),
        ]),
      ]),
    );
  }
}

const _configMeta = {
  ConfigList.accountTypes: ('Account types', 'How each account type counts: liquid, reserved, locked or owed.'),
  ConfigList.contributionTypes: ('Contribution types', 'Retirement and payroll contribution types available for salary deductions.'),
  ConfigList.classificationRules: (
    'Classification rules',
    'Rules that suggest a type and category for detected SMS. Suggestions always wait for your approval.'
  ),
  ConfigList.banks: ('Banks & wallets', 'Only messages from these senders are read. Disable a sender to stop detection.'),
};

/// One of the generic configurable lists (spec §4 ConfigItem).
class ConfigListScreen extends ConsumerWidget {
  const ConfigListScreen({super.key, required this.listKey});
  final String listKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (title, blurb) = _configMeta[listKey] ?? ('List', '');
    final c = context.colors;
    return DetailPage(
      title: title,
      actions: [PaisaLink(label: 'New', onPressed: () => _showAdd(context))],
      body: AsyncView(
        value: ref.watch(configListProvider(listKey)),
        data: (items) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
          Text(blurb, style: PaisaText.sub.copyWith(color: c.ink3)),
          const SizedBox(height: 12),
          PaisaListCard(children: [
            for (final i in items)
              Opacity(
                opacity: i.active ? 1 : 0.55,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          Text(i.name, style: PaisaText.h3.copyWith(color: c.ink)),
                          if (i.isDefault) const Tag('Default', tone: Tone.positive),
                        ]),
                        if (i.description.isNotEmpty) Text(i.description, style: PaisaText.sub.copyWith(color: c.ink3)),
                        if (!i.isDefault && i.active && listKey != ConfigList.classificationRules)
                          PaisaLink(
                            label: 'Set default',
                            onPressed: () async {
                              await ref.read(catalogRepoProvider).setConfigDefault(listKey, i.id);
                              ref.read(toastProvider.notifier).show('${i.name} is now the default');
                            },
                          ),
                      ]),
                    ),
                    PaisaToggle(
                      value: i.active,
                      label: '${i.active ? 'Disable' : 'Enable'} ${i.name}',
                      onChanged: (on) => ref.read(catalogRepoProvider).setConfigActive(i.id, on),
                    ),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _showAdd(BuildContext context) => showPaisaFormSheet<void, _NameForm>(
        context,
        title: 'New entry',
        create: _NameForm.new,
        body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaTextField(label: 'Name', controller: f.name, errorText: f.error),
          const SizedBox(height: 14),
          PaisaTextField(label: 'Description', controller: f.description, hint: 'Optional'),
        ]),
        footer: (ctx, f) => Consumer(
          builder: (ctx, ref, _) => Row(children: [
            Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PaisaButton(
                label: 'Add',
                onPressed: () async {
                  if (f.name.text.trim().isEmpty) {
                    f.setError('Enter a name');
                    return;
                  }
                  await ref.read(catalogRepoProvider).addConfigItem(listKey, f.name.text, f.description.text);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ref.read(toastProvider.notifier).show('${f.name.text.trim()} added');
                },
              ),
            ),
          ]),
        ),
      );
}

class _NameForm extends ChangeNotifier {
  final name = TextEditingController();
  final description = TextEditingController();
  String? error;
  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }
}

final _recurringDataProvider = FutureProvider<(List<RecurringRule>, TxnLookup)>(
  (ref) async => (await ref.watch(recurringProvider.future), await ref.watch(txnLookupProvider.future)),
);

/// Settings → Recurring rules: reminders for rent, bills, salary and the
/// payoff plan's extra payment. Pause or resume each one.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(clockProvider).today();
    return DetailPage(
      title: 'Recurring rules',
      body: AsyncView(
        value: ref.watch(_recurringDataProvider),
        data: (d) {
          final (rules, lookup) = d;
          final monthlyOut = rules
              .where((r) => r.active && r.kind != RecurringKind.income && r.frequency == RecurringFrequency.monthly)
              .fold<int>(0, (t, r) => t + r.amount);
          final monthlyIn = rules.where((r) => r.active && r.kind == RecurringKind.income).fold<int>(0, (t, r) => t + r.amount);
          if (rules.isEmpty) {
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(
                'No recurring rules yet. Turn on “Repeat monthly” when adding an expense, or save a payoff plan.',
                style: PaisaText.sub.copyWith(color: c.ink3),
              ),
            ]);
          }
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            Row(children: [
              Expanded(
                child: PaisaCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Monthly out', style: PaisaText.sub.copyWith(color: c.ink3)),
                    MoneyText(monthlyOut, style: PaisaText.h3),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PaisaCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Monthly in', style: PaisaText.sub.copyWith(color: c.ink3)),
                    MoneyText(monthlyIn, color: c.positive, style: PaisaText.h3),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            PaisaListCard(children: [
              for (final r in rules)
                Opacity(
                  opacity: r.active ? 1 : 0.55,
                  child: ListRow(
                    title: r.name,
                    subtitle: '${r.frequency.name[0].toUpperCase()}${r.frequency.name.substring(1)} · '
                        '${r.kind == RecurringKind.income ? lookup.incomeTypeName(r.incomeTypeId) : r.kind == RecurringKind.loanExtra ? 'Loan extra' : lookup.categoryName(r.categoryId)}'
                        ' · ${lookup.accountShort(r.accountId)} · ${dueText(r.nextDate, today)}',
                    leading: IconWell(
                      icon: r.kind == RecurringKind.income ? PaisaIcons.moneyIn : PaisaIcons.repeat,
                      tone: r.kind == RecurringKind.income ? Tone.positive : Tone.neutral,
                      size: 36,
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      MoneyText(r.amount, style: PaisaText.sub, sign: r.kind == RecurringKind.income ? '+' : ''),
                      PaisaToggle(
                        value: r.active,
                        label: '${r.active ? 'Pause' : 'Resume'} ${r.name}',
                        onChanged: (on) => ref.read(catalogRepoProvider).setRecurringActive(r.id, on),
                      ),
                    ]),
                  ),
                ),
            ]),
          ]);
        },
      ),
    );
  }
}

/// Settings → Audit history: every change with its time and source.
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  static String when(String at) => '${shortDate(at.substring(0, 10))} · ${at.substring(11, 16)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return DetailPage(
      title: 'Audit history',
      body: AsyncView(
        value: ref.watch(auditProvider),
        data: (entries) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
          Text(
            'Every financial change is logged with its time and source, so edits can be traced and corrected.',
            style: PaisaText.sub.copyWith(color: c.ink3),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty) Text('Nothing has changed yet.', style: PaisaText.sub.copyWith(color: c.ink3)),
          if (entries.isNotEmpty)
            PaisaListCard(children: [
              for (final e in entries)
                ListRow(
                  title: e.summary,
                  subtitle: when(e.at),
                  leading: IconWell(
                    icon: switch (e.actor) {
                      AuditActor.sms => PaisaIcons.sms,
                      AuditActor.ai => PaisaIcons.bolt,
                      AuditActor.system => PaisaIcons.gear,
                      AuditActor.user => e.action.contains('delete') ? PaisaIcons.trash : PaisaIcons.edit,
                    },
                    tone: e.actor == AuditActor.ai ? Tone.blue : Tone.neutral,
                    size: 36,
                  ),
                  trailing: switch (e.actor) {
                    AuditActor.user => null,
                    AuditActor.sms => const Tag('SMS'),
                    AuditActor.ai => const Tag('AI', tone: Tone.blue),
                    AuditActor.system => const Tag('System'),
                  },
                ),
            ]),
        ]),
      ),
    );
  }
}
