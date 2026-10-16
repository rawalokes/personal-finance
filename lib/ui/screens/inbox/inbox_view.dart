import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../finance/finance.dart';
import '../../../sms/sms_models.dart';
import '../../../sms/sms_source.dart';
import '../../../store/data_providers.dart';
import '../../../store/sms_sync.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/surfaces.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../sms/sms_actions.dart';
import '../../sms/sms_presentation.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/txn_presentation.dart';

enum InboxTab { review, approved, rejected, all }

/// Activity → Transaction Inbox (spec §7): detected bank and wallet SMS,
/// each a suggestion waiting for Confirm, Edit or Ignore.
class InboxView extends ConsumerStatefulWidget {
  const InboxView({super.key});

  @override
  ConsumerState<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends ConsumerState<InboxView> {
  InboxTab _tab = InboxTab.review;

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: ref.watch(smsMessagesProvider),
      data: (all) {
        int count(Set<SmsStatus> s) => all.where((m) => s.contains(m.status)).length;
        final waiting = count({SmsStatus.review, SmsStatus.later});
        const order = {SmsStatus.review: 0, SmsStatus.later: 1, SmsStatus.approved: 2, SmsStatus.rejected: 3};
        final shown = all
            .where((m) => switch (_tab) {
                  InboxTab.review => m.pending,
                  InboxTab.approved => m.status == SmsStatus.approved,
                  InboxTab.rejected => m.status == SmsStatus.rejected,
                  InboxTab.all => true,
                })
            .toList()
          ..sort((a, b) {
            final s = order[a.status]!.compareTo(order[b.status]!);
            return s != 0 ? s : '${b.date}${b.time}'.compareTo('${a.date}${a.time}');
          });
        final c = context.colors;
        return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 6), child: _SmsAccessCard()),
          ChipRow(children: [
            for (final (t, label) in [
              (InboxTab.review, 'Needs review · $waiting'),
              (InboxTab.approved, 'Approved · ${count({SmsStatus.approved})}'),
              (InboxTab.rejected, 'Rejected / Ignored · ${count({SmsStatus.rejected})}'),
              (InboxTab.all, 'All messages · ${all.length}'),
            ])
              PaisaChip(label: label, selected: _tab == t, onTap: () => setState(() => _tab = t)),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              _tab == InboxTab.review
                  ? (waiting > 0 ? '$waiting waiting · nothing saved until you confirm' : 'Inbox clear')
                  : '${shown.length} message${shown.length == 1 ? '' : 's'}',
              style: PaisaText.sub.copyWith(color: c.ink3),
            ),
          ),
          if (shown.isEmpty)
            EmptyState(
              icon: PaisaIcons.sms,
              title: _tab == InboxTab.review ? 'All caught up' : 'Nothing here yet',
              body: _tab == InboxTab.review
                  ? 'Every detected transaction has been reviewed. New bank and wallet messages will appear here for approval.'
                  : 'Messages you approve or ignore will be listed here.',
            ),
          for (final m in shown) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: SmsCard(m)),
        ]);
      },
    );
  }
}

/// Whether Paisa may read SMS here, and what to do about it.
class _SmsAccessCard extends ConsumerStatefulWidget {
  const _SmsAccessCard();

  @override
  ConsumerState<_SmsAccessCard> createState() => _SmsAccessCardState();
}

class _SmsAccessCardState extends ConsumerState<_SmsAccessCard> {
  bool _busy = false;

  Future<void> _sync({bool ask = false}) async {
    setState(() => _busy = true);
    final toast = ref.read(toastProvider.notifier);
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      if (ask && !await ref.read(smsSourceProvider).requestAccess()) {
        toast.show('Paisa can’t read SMS without permission. You can paste messages instead.');
        return;
      }
      container.invalidate(smsAccessProvider);
      final report = await container.read(smsSyncProvider).catchUp();
      toast.show(report.added == 0
          ? 'No new bank or wallet messages'
          : '${report.added} message${report.added == 1 ? '' : 's'} added to the inbox for review');
    } on Object {
      toast.show('Couldn’t read SMS just now. Try again, or paste the message.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final access = ref.watch(smsAccessProvider).value;
    final senders = ref.watch(trustedSendersProvider).value ?? const <String>[];
    final paste = PaisaLink(label: 'Paste an SMS', onPressed: () => showPasteSmsSheet(context));
    return switch (access) {
      null => const SizedBox(height: 8),
      SmsAccess.unsupported => PaisaCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Paisa can’t read SMS on this device. Paste a bank or wallet message to add it.',
                style: PaisaText.sub.copyWith(color: c.ink2)),
            paste,
          ]),
        ),
      SmsAccess.denied => PaisaCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Let Paisa read bank SMS', style: PaisaText.h3.copyWith(color: c.ink)),
            const SizedBox(height: 4),
            Text(
              'Only messages from the banks and wallets you approve are read, account numbers and balances are '
              'masked, and nothing is saved until you confirm it.',
              style: PaisaText.sub.copyWith(color: c.ink3),
            ),
            const SizedBox(height: 12),
            PaisaButton(label: _busy ? 'Reading…' : 'Allow reading SMS', icon: PaisaIcons.sms, onPressed: _busy ? null : () => _sync(ask: true)),
            Align(alignment: Alignment.centerLeft, child: paste),
          ]),
        ),
      SmsAccess.granted => Row(children: [
          Expanded(
            child: Text(
              'Reading SMS from ${senders.length} approved sender${senders.length == 1 ? '' : 's'}',
              style: PaisaText.sub.copyWith(color: c.ink3),
            ),
          ),
          PaisaLink(label: _busy ? 'Checking…' : 'Check now', onPressed: _busy ? null : _sync),
          paste,
        ]),
    };
  }
}

/// One message in the inbox list.
class SmsCard extends ConsumerWidget {
  const SmsCard(this.m, {super.key});
  final SmsMessage m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final account = accounts.where((a) => a.id == m.accountId).firstOrNull;
    final (head, headTone) = inboxHead(m);
    final credit = m.direction == Direction.credit;
    final catName = switch (m.type) {
      TxType.income => (ref.watch(incomeTypesProvider).value ?? const <IncomeType>[]).where((t) => t.id == m.incomeTypeId).firstOrNull?.name,
      TxType.expense || TxType.refund =>
        (ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[]).where((x) => x.id == m.categoryId).firstOrNull?.name,
      _ => null,
    };
    final today = ref.watch(clockProvider).today();
    void open() => context.push('/inbox/${m.id}');
    return PaisaCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: open,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Flexible(child: Align(alignment: Alignment.centerLeft, child: Tag(head, tone: headTone))),
              const SizedBox(width: 8),
              Text('${relativeDay(m.date, today)}, ${m.time}', style: PaisaText.hint.copyWith(color: c.ink3)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              IconWell(icon: credit ? PaisaIcons.moneyIn : PaisaIcons.bank, tone: credit ? Tone.positive : Tone.neutral, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.merchant, maxLines: 2, overflow: TextOverflow.ellipsis, style: PaisaText.h3.copyWith(color: c.ink)),
                  Text(smsAccountText(m, account), maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.sub.copyWith(color: c.ink3)),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  '${credit ? '+' : '−'} ${money.npr(m.amount)}',
                  style: PaisaText.numeric(PaisaText.h3.copyWith(color: credit ? c.positive : c.ink)),
                ),
                Text(credit ? 'Credit' : 'Debit', style: PaisaText.hint.copyWith(color: c.ink3)),
              ]),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          Tag('Suggested: ${kTxTypeInfo[m.type]!.name}', tone: Tone.blue),
          if (catName != null) Tag(catName),
          Tag(confidenceLabel(m.confidence), tone: confidenceTone(m.confidence)),
          if (m.suggestedBy == SmsSuggestedBy.ai) const Tag('Suggested by AI', tone: Tone.blue),
        ]),
        if (isPossibleDuplicate(m)) ...[
          const SizedBox(height: 10),
          const Note('Same amount and account as another message a few minutes earlier. Saving both would double count.',
              tone: Tone.amber),
        ],
        if (m.pending) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PaisaButton(label: 'Confirm', small: true, onPressed: () => confirmSmsFlow(context, ref, m))),
            const SizedBox(width: 8),
            Expanded(
              child: PaisaButton(label: 'Edit', small: true, variant: ButtonVariant.secondary, onPressed: () => showSmsEditSheet(context, m)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PaisaButton(label: 'Ignore', small: true, variant: ButtonVariant.ghost, onPressed: () => rejectSmsFlow(context, ref, m)),
            ),
          ]),
        ],
        if (m.status == SmsStatus.rejected) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('Not counted anywhere.', style: PaisaText.sub.copyWith(color: c.ink3))),
            PaisaLink(label: 'Restore to review', onPressed: () => restoreSms(ref, m)),
          ]),
        ],
        if (m.status == SmsStatus.approved) ...[
          const SizedBox(height: 10),
          Text('Saved to history and balances', style: PaisaText.sub.copyWith(color: c.positive)),
        ],
      ]),
    );
  }
}
