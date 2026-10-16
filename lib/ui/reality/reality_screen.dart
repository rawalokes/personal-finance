import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../finance/finance.dart';
import '../../integrations/gemini/schemas.dart';
import '../../store/reality.dart';
import '../../store/reports.dart';
import '../../store/ui_state.dart';
import '../components/buttons.dart';
import '../components/indicators.dart';
import '../components/inputs.dart';
import '../components/layout.dart';
import '../components/money_text.dart';
import '../components/surfaces.dart';
import '../components/tone.dart';
import '../icons/paisa_icons.dart';
import '../shell/detail_page.dart';
import '../theme.dart';
import '../typography.dart';
import 'reality_widgets.dart';

String habitTitle(HabitKind k) => switch (k) {
      HabitKind.emiLoad => 'EMIs vs income',
      HabitKind.debtSize => 'Total debt',
      HabitKind.savingsRate => 'Savings rate',
      HabitKind.afterEmis => 'Left after EMIs',
      HabitKind.emergencyFund => 'Emergency fund',
      HabitKind.interest => 'Interest cost',
    };

String goalVerdictLabel(GoalVerdict v) => switch (v) {
      GoalVerdict.done => 'Done',
      GoalVerdict.realistic => 'Realistic',
      GoalVerdict.stretch => 'Stretch',
      GoalVerdict.notRealistic => 'Not realistic',
      GoalVerdict.noDate => 'No date',
    };

Tone goalVerdictTone(GoalVerdict v) => switch (v) {
      GoalVerdict.done || GoalVerdict.realistic => Tone.positive,
      GoalVerdict.stretch => Tone.amber,
      GoalVerdict.notRealistic => Tone.red,
      GoalVerdict.noDate => Tone.neutral,
    };

/// "My money reality": habits against proven rules of thumb, goals against
/// what you really save, and this month's plan against what happened.
class RealityScreen extends ConsumerStatefulWidget {
  const RealityScreen({super.key});

  @override
  ConsumerState<RealityScreen> createState() => _RealityScreenState();
}

class _RealityScreenState extends ConsumerState<RealityScreen> {
  int _month = 0;

  @override
  Widget build(BuildContext context) {
    final h = ref.watch(habitReportProvider).value;
    final goals = ref.watch(goalChecksProvider).value;
    final review = ref.watch(monthReviewProvider(_month)).value;
    final inputs = ref.watch(reportInputsProvider).value;
    final names = {for (final x in inputs?.categories ?? const <ExpenseCategory>[]) x.id: x.name};
    return DetailPage(
      title: 'My money reality',
      body: h == null || goals == null
          ? const SizedBox.shrink()
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
              _Habits(h: h, names: names),
              const SizedBox(height: 10),
              RealityAiCard(
                topic: RealityTopic.habits,
                blurb: 'A frank summary of your habits and the three fixes that matter most.',
                facts: () => habitFacts(h, names: names),
              ),
              const SectionHeader(padding: kInsetSection, title: 'Goals reality', subtitle: 'Against what you really put aside'),
              _Goals(goals: goals, averages: h.averages),
              const SectionHeader(padding: kInsetSection, title: 'Plan vs reality'),
              ChipWrap(children: [
                PaisaChip(label: 'This month', selected: _month == 0, onTap: () => setState(() => _month = 0)),
                PaisaChip(label: 'Last month', selected: _month == -1, onTap: () => setState(() => _month = -1)),
              ]),
              const SizedBox(height: 10),
              if (review != null) _Review(r: review, names: names),
              const SectionHeader(padding: kInsetSection, title: 'Budget plan', subtitle: 'Built from proven rules and your real spending'),
              PaisaCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('50/30/20, zero-based or debt-first: Paisa builds every budget from your last few months.',
                      style: PaisaText.sub.copyWith(color: context.colors.ink2)),
                  const SizedBox(height: 10),
                  PaisaButton(label: 'Build my budget plan', icon: PaisaIcons.sliders, onPressed: () => context.push('/reality/budget')),
                ]),
              ),
            ]),
    );
  }
}

class _Habits extends ConsumerWidget {
  const _Habits({required this.h, required this.names});
  final HabitReport h;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final cal = ref.watch(monthCalendarProvider);
    final income = h.averages.income;
    String value(HabitMetric m) => switch (m.kind) {
          HabitKind.debtSize => income <= 0 ? money.npr(h.totalDebt) : '${m.value.toStringAsFixed(1)} months of income',
          HabitKind.emergencyFund => '${m.value.toStringAsFixed(1)} months',
          HabitKind.interest => '${money.npr(h.interestPerMonth)} / month',
          _ => percent(m.value),
        };
    String hint(HabitMetric m) => switch (m.kind) {
          HabitKind.emiLoad => '${money.npr(h.monthlyEmi)} a month · healthy under 30%',
          HabitKind.debtSize => '${money.npr(h.totalDebt)} owed · under 6 months of income is comfortable',
          HabitKind.savingsRate => 'Kept from income · aim for 20% or more',
          HabitKind.afterEmis => '${money.npr(h.averages.cashLeft)} a month left after spending and loan principal',
          HabitKind.emergencyFund => 'Reserved savings in months of spending · aim for 6',
          HabitKind.interest => '${percent(m.value)} of income paid as interest · keep it under 5%',
        };
    final (headline, sub) = switch (h.overall) {
      Level.good => ('Your money habits look healthy', 'Keep going — and put the surplus to work.'),
      Level.watch => ('A few habits need attention', 'Nothing alarming, but fix the amber and red ones before they grow.'),
      Level.bad => ('Your money needs attention now', 'Several warning signs at once. Start with the red ones below.'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: LevelDot(h.overall, size: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(headline, style: PaisaText.h2.copyWith(color: c.ink)),
              const SizedBox(height: 4),
              Text(sub, style: PaisaText.sub.copyWith(color: c.ink2)),
              const SizedBox(height: 6),
              Text(
                h.averages.months == 0
                    ? 'Add income and spending to see your real habits.'
                    : 'Average of the last ${h.averages.months} ${h.averages.months == 1 ? 'month' : 'months'}: '
                        '${money.npr(h.averages.income)} in, ${money.npr(h.averages.spending)} spent',
                style: PaisaText.hint.copyWith(color: c.ink3),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      PaisaListCard(children: [
        for (final m in h.metrics)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 5), child: LevelDot(m.level)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(habitTitle(m.kind), style: PaisaText.h3.copyWith(color: c.ink)),
                    Text(value(m), style: PaisaText.sub.copyWith(color: levelColor(context, m.level))),
                  ]),
                  Text(hint(m), style: PaisaText.hint.copyWith(color: c.ink3)),
                ]),
              ),
            ]),
          ),
      ]),
      const SizedBox(height: 10),
      Note(
        h.monthlyEmi == 0 && h.totalDebt == 0
            ? 'No loans or card debt. That’s freedom most people don’t have.'
            : h.debtFreeDate == null
                ? 'At today’s EMIs a loan never gets paid off — the payment doesn’t cover its interest.'
                : 'Debt-free in ${cal.monthYear(cal.key(h.debtFreeDate!))} at today’s EMIs. Paying extra brings it closer.',
        lead: 'Debt: ',
        tone: h.debtFreeDate == null && h.monthlyEmi > 0 ? Tone.red : Tone.blue,
      ),
      if (h.leaks.isNotEmpty) ...[
        const SizedBox(height: 10),
        PaisaCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Biggest leaks', style: PaisaText.h3.copyWith(color: c.ink)),
            Text('Wants you spend most on each month', style: PaisaText.hint.copyWith(color: c.ink3)),
            for (final l in h.leaks)
              InkWell(
                onTap: () => context.push('/reports/category/${l.$1}?period=last3m'),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(names[l.$1] ?? l.$1, style: PaisaText.sub.copyWith(color: c.ink), overflow: TextOverflow.ellipsis),
                        if (income > 0) Text('${percent(l.$2 / income)} of income', style: PaisaText.hint.copyWith(color: c.ink3)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    MoneyText(l.$2, style: PaisaText.sub),
                  ]),
                ),
              ),
          ]),
        ),
      ],
    ]);
  }
}

class _Goals extends ConsumerWidget {
  const _Goals({required this.goals, required this.averages});
  final List<GoalCheck> goals;
  final Averages averages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final cal = ref.watch(monthCalendarProvider);
    if (goals.isEmpty) {
      return PaisaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('No goals yet. A goal with a date gets an honest verdict here.', style: PaisaText.sub.copyWith(color: c.ink3)),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: PaisaLink(label: 'Add a goal', onPressed: () => context.go('/plans'))),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('You put aside about ${money.npr(averages.cashLeft < 0 ? 0 : averages.cashLeft)} a month.', style: PaisaText.sub.copyWith(color: c.ink2)),
      const SizedBox(height: 8),
      for (final g in goals) ...[
        PaisaCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(g.goal.name, style: PaisaText.h3.copyWith(color: c.ink), overflow: TextOverflow.ellipsis)),
              Tag(goalVerdictLabel(g.verdict), tone: goalVerdictTone(g.verdict)),
            ]),
            const SizedBox(height: 4),
            Text(
              switch (g.verdict) {
                GoalVerdict.done => 'Reached — ${money.npr(g.goal.target)} saved.',
                GoalVerdict.noDate => g.monthsAtPace == null
                    ? '${money.npr(g.remaining)} to go. Add a date to get a verdict.'
                    : '${money.npr(g.remaining)} to go · about ${g.monthsAtPace} months at your pace.',
                _ => 'Needs ${money.npr(g.need ?? 0)} a month by ${cal.longDate(g.goal.targetDate)} · '
                    '${money.npr(g.available)} a month is left for it.',
              },
              style: PaisaText.sub.copyWith(color: c.ink2),
            ),
            if (g.verdict == GoalVerdict.stretch || g.verdict == GoalVerdict.notRealistic) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (g.paceDate != null) 'At your pace: ${cal.monthYear(cal.key(g.paceDate!))}',
                  if (g.shortBy > 0) 'or find ${money.npr(g.shortBy)} more a month (cut wants, earn more)',
                  if (g.verdict == GoalVerdict.stretch) 'doable, but no slip-ups',
                ].join(' · '),
                style: PaisaText.hint.copyWith(color: c.ink3),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 8),
      ],
      RealityAiCard(
        topic: RealityTopic.goals,
        blurb: 'Which goals to keep, move or shrink — with the trade-offs in rupees.',
        facts: () => goalFacts(goals, averages),
      ),
    ]);
  }
}

class _Review extends ConsumerWidget {
  const _Review({required this.r, required this.names});
  final MonthReview r;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final cal = ref.watch(monthCalendarProvider);
    final (label, sub) = switch (r.verdict) {
      Level.good => ('On plan', r.complete ? 'You did what you planned.' : 'Keep this pace.'),
      Level.watch => ('Slightly off', r.complete ? 'Close, with a few slips.' : 'A small correction now keeps the month on track.'),
      Level.bad => ('Off plan', r.complete ? 'This month didn’t go to plan.' : 'Act now — there are ${cal.daysIn(r.month) - (r.fraction * cal.daysIn(r.month)).round()} days left.'),
    };
    String fix(ReviewFix f) => switch (f.kind) {
          FixKind.cutCategory => 'Cut ${names[f.categoryId] ?? 'that category'} by ${money.npr(f.amount)}',
          FixKind.saveFirst => 'Move ${money.npr(f.amount)} to savings the day income arrives',
          FixKind.payEmi => 'Pay the ${f.amount == 1 ? 'missed EMI' : '${f.amount} missed EMIs'} and turn on EMI reminders',
          FixKind.setBudgets => 'Set budgets — build a budget plan below',
        };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(cal.monthYear(r.month), style: PaisaText.h3.copyWith(color: c.ink))),
            Tag(label, tone: levelTone(r.verdict)),
          ]),
          Text(sub, style: PaisaText.hint.copyWith(color: c.ink3)),
          const SizedBox(height: 10),
          Text('Saved ${money.npr(r.saved)} of ${money.npr(r.saveTarget)} planned', style: PaisaText.sub.copyWith(color: c.ink)),
          const SizedBox(height: 6),
          ProgressBar(value: r.saveTarget <= 0 ? 0 : (r.saved / r.saveTarget).clamp(0.0, 1.0), color: levelColor(context, r.verdict)),
          if (!r.complete) ...[
            const SizedBox(height: 4),
            Text('By today you should have ${money.npr(r.expectedSaved)}', style: PaisaText.hint.copyWith(color: c.ink3)),
          ],
          const SizedBox(height: 10),
          KeyValueRow('Income', value: money.npr(r.income)),
          KeyValueRow('Spent', value: money.npr(r.spent)),
          KeyValueRow('Budgets', value: r.budgets.isEmpty ? 'None set' : '${r.budgetsOver} of ${r.budgets.length} over'),
          KeyValueRow('EMIs', value: r.emisExpected == 0 ? 'None' : '${r.emisPaid} of ${r.emisExpected} paid'),
          if (r.fixes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.complete ? 'Fix next month' : 'Fix it this month', style: PaisaText.sub.copyWith(color: c.ink3)),
            for (final f in r.fixes)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('→ ${fix(f)}', style: PaisaText.sub.copyWith(color: c.ink)),
              ),
          ],
        ]),
      ),
      const SizedBox(height: 10),
      RealityAiCard(
        key: ValueKey(r.month),
        topic: RealityTopic.review,
        scope: r.month,
        blurb: 'What went well, what didn’t, and next month’s fix in numbers.',
        facts: () => reviewFacts(r, names: names),
      ),
    ]);
  }
}
