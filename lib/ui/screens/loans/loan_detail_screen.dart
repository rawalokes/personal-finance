import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/empty_state.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/money_text.dart';
import '../../components/surfaces.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../loans/loan_presentation.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../../txn/txn_sheet.dart';
import 'repay_sheet.dart';

class _LoanData {
  const _LoanData(this.loan, this.types, this.accounts, this.repayments);
  final Loan? loan;
  final List<LoanType> types;
  final List<Account> accounts;
  final List<Txn> repayments;
}

final _loanDataProvider = FutureProvider.family<_LoanData, String>((ref, id) async {
  final loans = await ref.watch(loansProvider.future);
  return _LoanData(
    loans.where((l) => l.id == id).firstOrNull,
    await ref.watch(loanTypesProvider.future),
    await ref.watch(accountsProvider.future),
    await ref.watch(loanRepaymentsProvider(id).future),
  );
});

/// One loan: outstanding, next installment split, terms, 6-row schedule and
/// repayment history (spec §7 Loan detail).
class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});
  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_loanDataProvider(loanId));
    final loan = data.value?.loan;
    return DetailPage(
      title: loan?.name ?? 'Loan',
      actions: [
        if (loan != null)
          PaisaIconButton(icon: PaisaIcons.edit, label: 'Edit loan', onPressed: () => context.push('/loans/$loanId/edit')),
      ],
      body: AsyncView(
        value: data,
        data: (d) => d.loan == null
            ? const EmptyState(icon: PaisaIcons.rupee, title: 'Loan not found', body: 'It may have been removed.')
            : _Body(d),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body(this.d);
  final _LoanData d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final today = ref.watch(clockProvider).today();
    final l = d.loan!;
    final type = d.types.where((t) => t.id == l.loanTypeId).firstOrNull?.name ?? 'Loan';
    final account = d.accounts.where((a) => a.id == l.repaymentAccountId).firstOrNull?.shortName ?? 'Not set';
    final paid = l.principal <= 0 ? 0.0 : (1 - l.outstanding / l.principal).clamp(0.0, 1.0).toDouble();
    final schedule = buildSchedule(l);
    final split = splitRepayment(l, l.installment);
    final done = l.outstanding <= 0;
    final overdue = !done && l.nextDueDate != null && daysBetween(l.nextDueDate!, today) < 0;
    final kv = PaisaText.numeric(PaisaText.body.copyWith(fontSize: 14));
    String term() {
      if (done) return 'Paid off';
      if (schedule.neverRepaid) return 'Never — installment too low';
      return '${schedule.periods} installments (~${(schedule.periods / l.frequency.periodsPerYear).toStringAsFixed(1)} yrs)';
    }

    return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [Tag(type, tone: Tone.amber), Tag(l.lender)]),
              const SizedBox(height: 12),
              Text('Outstanding principal', style: PaisaText.sub.copyWith(color: c.ink3)),
              MoneyText(l.outstanding, color: done ? c.positive : c.red, style: PaisaText.h1.copyWith(fontSize: 30)),
              const SizedBox(height: 10),
              ProgressBar(value: paid, semanticLabel: 'Repaid'),
              const SizedBox(height: 6),
              Text(
                '${money.npr(l.principal - l.outstanding)} repaid of ${money.npr(l.principal)} · ${(paid * 100).round()}%',
                style: PaisaText.hint.copyWith(color: c.ink3),
              ),
            ]),
          ),
          if (overdue) ...[
            const SizedBox(height: 12),
            Note(
              'Installment of ${money.npr(l.installment)} was due ${longDate(l.nextDueDate)}. Record the payment once made.',
              tone: Tone.red,
              icon: PaisaIcons.alert,
            ),
          ],
          if (schedule.neverRepaid && !done) ...[
            const SizedBox(height: 12),
            const Note(
              'The installment does not cover the interest, so this loan would never be repaid. Check the installment and rate.',
              tone: Tone.red,
              icon: PaisaIcons.alert,
            ),
          ],
          if (!done) ...[
            const SizedBox(height: 12),
            PaisaButton(label: 'Record repayment', icon: PaisaIcons.check, onPressed: () => showRepaySheet(context, l)),
          ],
          const SizedBox(height: 12),
          KeyValueCard(rows: [
            KeyValueRow('Interest', value: rateText(l)),
            KeyValueRow('Installment', valueWidget: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: MoneyText(l.installment, style: kv)),
              Text(' · ${frequencyLabel(l.frequency)}', style: kv.copyWith(color: c.ink)),
            ])),
            KeyValueRow('Next due', value: l.nextDueDate == null ? 'Not set' : '${longDate(l.nextDueDate)} · ${dueText(l.nextDueDate, today)}'),
            KeyValueRow('Remaining term', value: term()),
            KeyValueRow('Original principal', valueWidget: MoneyText(l.principal, style: kv)),
            KeyValueRow('Start · Maturity', value: '${longDate(l.startDate)} · ${l.maturityDate == null ? 'Not set' : longDate(l.maturityDate)}'),
            KeyValueRow('Repayment account', value: account),
            KeyValueRow('Fees & prepayment', value: l.feesAndPrepayment ?? 'Not entered'),
          ]),
          if (!done) ...[
            const SizedBox(height: 12),
            PaisaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Next installment split', style: PaisaText.h2.copyWith(color: c.ink)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 10,
                    child: Row(children: [
                      if (split.principal > 0) Expanded(flex: split.principal, child: ColoredBox(color: c.primary)),
                      if (split.interest > 0) Expanded(flex: split.interest, child: ColoredBox(color: c.red)),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 4, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    MoneyText(split.principal, style: kv.copyWith(fontVariations: const [FontVariation('wght', 700)])),
                    Text(' principal', style: PaisaText.sub.copyWith(color: c.ink3)),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    MoneyText(split.interest, style: kv.copyWith(fontVariations: const [FontVariation('wght', 700)])),
                    Text(' interest', style: PaisaText.sub.copyWith(color: c.ink3)),
                  ]),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Only interest is counted as an expense (Loan Interest). Principal reduces your liability.',
                  style: PaisaText.hint.copyWith(color: c.ink3),
                ),
              ]),
            ),
          ],
        ]),
      ),
      if (!done && schedule.rows.isNotEmpty) ...[
        SectionHeader(title: 'Repayment schedule', trailing: Text('Forecast', style: PaisaText.sub.copyWith(color: c.ink3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PaisaCard(
            child: Column(children: [
              _ScheduleRow(cells: const ['Due', 'Pay', 'Princ.', 'Int.', 'Balance'], header: true),
              for (final r in schedule.rows)
                _ScheduleRow(cells: [
                  r.dueDate == null ? '—' : shortDate(r.dueDate),
                  money.short(r.payment),
                  money.short(r.principal),
                  money.short(r.interest),
                  money.short(r.balanceAfter),
                ]),
              const SizedBox(height: 8),
              Text(
                '${switch (l.method) {
                  InterestMethod.none => 'No interest entered — every payment reduces principal.',
                  InterestMethod.flat => 'Flat rate: interest is charged on the original principal every period.',
                  InterestMethod.reducing => 'Reducing balance: interest is charged on what is still owed, so it falls each period.',
                }} Forecast assumes on-time payments.',
                style: PaisaText.hint.copyWith(color: c.ink3),
              ),
            ]),
          ),
        ),
      ],
      SectionHeader(
        title: 'Repayment history',
        trailing: Text('${d.repayments.length} payments', style: PaisaText.sub.copyWith(color: c.ink3)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: d.repayments.isEmpty
            ? PaisaCard(child: Text('No repayments recorded yet.', style: PaisaText.sub.copyWith(color: c.ink3)))
            : PaisaListCard(children: [
                for (final t in d.repayments)
                  ListRow(
                    title: longDate(t.date),
                    subtitle: 'Principal ${money.plain(t.principal ?? 0)} · Interest ${money.plain(t.interest ?? 0)}',
                    leading: const IconWell(icon: PaisaIcons.check, tone: Tone.positive, size: 36),
                    trailing: MoneyText(t.amount, style: kv),
                    onTap: () => showTxnSheet(context, t),
                  ),
              ]),
      ),
    ]);
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.cells, this.header = false});
  final List<String> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = PaisaText.numeric(
      (header ? PaisaText.hint : PaisaText.sub).copyWith(color: header ? c.ink3 : c.ink),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        for (final (i, t) in cells.indexed)
          Expanded(
            flex: i == 0 ? 3 : 2,
            child: Text(t, textAlign: i == 0 ? TextAlign.left : TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
      ]),
    );
  }
}
