import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../sms/sms_models.dart';
import '../../../sms/treatment.dart';
import '../../../store/data_providers.dart';
import '../../../store/sms_sync.dart';
import '../../../store/ui_state.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../shell/detail_page.dart';
import '../../sms/sms_actions.dart';
import '../../sms/sms_presentation.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/txn_presentation.dart';
import 'ai_sms_help.dart';

/// Review one detected message (spec §7 Review detail): the suggestion, why,
/// what confirming would do, and the masked original.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.smsId});
  final String smsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(smsMessagesProvider);
    final m = all.value?.where((x) => x.id == smsId).firstOrNull;
    if (m == null) {
      return DetailPage(
        title: 'Review transaction',
        body: all.isLoading
            ? const SizedBox.shrink()
            : const EmptyState(icon: PaisaIcons.sms, title: 'Message not found', body: 'It may have been deleted.'),
      );
    }
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final loans = ref.watch(loansProvider).value ?? const <Loan>[];
    final categories = ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    final incomeTypes = ref.watch(incomeTypesProvider).value ?? const <IncomeType>[];
    final month = ref.watch(monthTotalsProvider).value;
    final today = ref.watch(clockProvider).today();
    final account = accounts.where((a) => a.id == m.accountId).firstOrNull;
    final t = treatSms(
      m,
      accounts: accounts,
      loans: loans,
      categories: categories,
      incomeTypes: incomeTypes,
      spentThisMonth: month?.byCategory ?? const {},
      money: money,
      monthName: monthName(today),
    );
    final credit = m.direction == Direction.credit;
    final editableCat = hasCategory(m.type);
    final catName = m.type == TxType.income
        ? incomeTypes.where((x) => x.id == m.incomeTypeId).firstOrNull?.name ?? 'Other income'
        : categories.where((x) => x.id == m.categoryId).firstOrNull?.name ?? 'Other';
    final when = '${longDate(m.date)}, ${m.time}';
    final (statusShort, statusTone) = m.pending
        ? ('Awaiting approval', Tone.amber)
        : m.status == SmsStatus.approved
            ? ('Approved', Tone.positive)
            : ('Ignored', Tone.neutral);

    Color toneColor(LineTone tone) => switch (tone) {
          LineTone.positive => c.positive,
          LineTone.negative => c.red,
          LineTone.neutral => c.ink,
        };

    return DetailPage(
      title: 'Review transaction',
      actions: [Padding(padding: const EdgeInsets.only(right: 12), child: Tag(statusShort, tone: statusTone))],
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        PaisaCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              IconWell(icon: credit ? PaisaIcons.moneyIn : PaisaIcons.bank, tone: credit ? Tone.positive : Tone.neutral, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.institution, style: PaisaText.h3.copyWith(color: c.ink)),
                  Text(smsAccountText(m, account), style: PaisaText.sub.copyWith(color: c.ink3)),
                ]),
              ),
              Tag(confidenceLabel(m.confidence), tone: confidenceTone(m.confidence)),
            ]),
            const SizedBox(height: 14),
            Text(credit ? 'Money in' : 'Money out', style: PaisaText.sub.copyWith(color: c.ink3)),
            Text(
              '${credit ? '+' : '−'} ${money.npr(m.amount)}',
              style: PaisaText.numeric(PaisaText.h1.copyWith(fontSize: 30, color: credit ? c.positive : c.ink)),
            ),
            Text('${m.merchant} · $when', style: PaisaText.sub.copyWith(color: c.ink2)),
            const SizedBox(height: 12),
            Note(m.reason, lead: 'Why this suggestion: ', tone: Tone.blue),
            if (m.suggestedBy == SmsSuggestedBy.ai) ...[
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerLeft, child: Tag('Suggested by AI · may be wrong', tone: Tone.blue)),
            ],
          ]),
        ),
        if (isPossibleDuplicate(m)) ...[
          const SizedBox(height: 10),
          const Note(
            'Same amount and account as another message a few minutes earlier. Ignore one of them unless you really paid twice.',
            lead: 'Possible duplicate. ',
            tone: Tone.amber,
          ),
        ],
        if (t.warning != null && m.pending) ...[const SizedBox(height: 10), Note(t.warning!, tone: Tone.red)],
        if (m.pending) AiSmsHelp(m),
        const SizedBox(height: 12),
        PaisaListCard(children: [
          ListRow(
            title: 'Transaction type',
            subtitle: kTxTypeInfo[m.type]!.name,
            leading: PaisaIcon(kTxTypeInfo[m.type]!.icon, size: 20, color: c.ink2),
            trailing: m.pending ? Text('Change', style: PaisaText.buttonSmall.copyWith(color: c.primary)) : null,
            onTap: m.pending ? () => showSmsTypeSheet(context, m) : null,
          ),
          ListRow(
            title: m.type == TxType.income ? 'Income type' : 'Category',
            subtitle: editableCat ? catName : 'Not applicable for ${kTxTypeInfo[m.type]!.name.toLowerCase()}',
            leading: PaisaIcon(PaisaIcons.tag, size: 20, color: c.ink2),
            trailing: m.pending && editableCat ? Text('Change', style: PaisaText.buttonSmall.copyWith(color: c.primary)) : null,
            onTap: m.pending && editableCat ? () => showSmsCategorySheet(context, m) : null,
          ),
        ]),
        const SizedBox(height: 12),
        KeyValueCard(rows: [
          KeyValueRow('Bank', value: m.institution),
          KeyValueRow('Account', value: smsAccountText(m, account)),
          KeyValueRow('Merchant / remark', value: m.merchant),
          KeyValueRow('Date & time', value: when),
          if ((m.description ?? '').isNotEmpty) KeyValueRow('Description', value: m.description),
          KeyValueRow('Status', value: statusLong(m)),
        ]),
        const SizedBox(height: 12),
        PaisaCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text('Proposed accounting', style: PaisaText.h3.copyWith(color: c.ink))),
              Tag(kTxTypeInfo[m.type]!.name),
            ]),
            const SizedBox(height: 8),
            for (final l in t.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Text(l.label, style: PaisaText.body.copyWith(color: c.ink2))),
                  Text(l.value, style: PaisaText.numeric(PaisaText.body.copyWith(color: toneColor(l.tone)))),
                ]),
              ),
            const SizedBox(height: 6),
            Text(t.note, style: PaisaText.sub.copyWith(color: c.ink3)),
          ]),
        ),
        const SizedBox(height: 12),
        PaisaCard(
          color: c.surface2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Original SMS · ${m.sender}', style: PaisaText.hint.copyWith(color: c.ink3)),
            const SizedBox(height: 6),
            Text(m.maskedBody, style: PaisaText.sub.copyWith(color: c.ink2)),
            const SizedBox(height: 6),
            Text('Account numbers and balances are masked before storage.', style: PaisaText.hint.copyWith(color: c.ink3)),
          ]),
        ),
      ]),
      footer: m.pending
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PaisaButton(
                label: 'Confirm transaction',
                onPressed: () async {
                  if (await confirmSmsFlow(context, ref, m) && context.mounted) leavePage(context);
                },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: PaisaButton(label: 'Edit', small: true, variant: ButtonVariant.secondary, onPressed: () => showSmsEditSheet(context, m)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PaisaButton(
                    label: 'Later',
                    small: true,
                    variant: ButtonVariant.outline,
                    onPressed: () async {
                      await laterSms(ref, m);
                      if (context.mounted) leavePage(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PaisaButton(
                    label: 'Reject',
                    small: true,
                    variant: ButtonVariant.danger,
                    onPressed: () async {
                      if (await rejectSmsFlow(context, ref, m) && context.mounted) leavePage(context);
                    },
                  ),
                ),
              ]),
            ])
          : m.status == SmsStatus.rejected
              ? PaisaButton(label: 'Restore to Needs review', variant: ButtonVariant.secondary, onPressed: () => restoreSms(ref, m))
              : null,
    );
  }
}
