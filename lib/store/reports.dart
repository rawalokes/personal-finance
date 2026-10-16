import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../data/clock.dart';
import '../data/records.dart';
import '../data/report_settings.dart';
import '../data/repos/settings_repo.dart';
import '../finance/finance.dart';
import 'data_providers.dart';
import 'ui_state.dart';

/// 1 Shrawan of the Nepali fiscal year [today] falls in.
IsoDate fiscalYearStart(IsoDate today) {
  final d = parseIsoDate(today);
  final bs = DateTime(d.year, d.month, d.day).toNepaliDateTime();
  final ad = NepaliDateTime(bs.month >= 4 ? bs.year : bs.year - 1, 4, 1).toDateTime();
  return toIsoDate(DateTime.utc(ad.year, ad.month, ad.day));
}

final fyStartProvider = Provider<IsoDate>((ref) => fiscalYearStart(ref.watch(clockProvider).today()));

/// Everything the report, score, nudge and challenge maths reads.
class ReportInputs {
  const ReportInputs({
    required this.txs,
    required this.accounts,
    required this.loans,
    required this.categories,
    required this.incomeTypes,
    required this.recurring,
    required this.goals,
    required this.parties,
  });

  final List<Txn> txs;
  final List<Account> accounts;
  final List<Loan> loans;
  final List<ExpenseCategory> categories;
  final List<IncomeType> incomeTypes;
  final List<RecurringRule> recurring;
  final List<Goal> goals;

  /// Party id → name.
  final Map<String, String> parties;
}

final reportInputsProvider = FutureProvider<ReportInputs>((ref) async => ReportInputs(
      txs: await ref.watch(transactionsProvider.future),
      accounts: await ref.watch(accountsProvider.future),
      loans: await ref.watch(loansProvider.future),
      categories: await ref.watch(categoriesProvider.future),
      incomeTypes: await ref.watch(incomeTypesProvider.future),
      recurring: await ref.watch(recurringProvider.future),
      goals: await ref.watch(goalsProvider.future),
      parties: {for (final p in await ref.watch(configListProvider(ConfigList.parties).future)) p.id: p.name},
    ));

final _savedDashboardProvider = StreamProvider<DashboardConfig?>((ref) => ref.watch(settingsRepoProvider).watchDashboard());

/// The saved layout (or the default), without ids that no longer exist.
final dashboardProvider = FutureProvider<DashboardConfig>((ref) async {
  final saved = await ref.watch(_savedDashboardProvider.future);
  final i = await ref.watch(reportInputsProvider.future);
  return normaliseDashboard(
    saved ?? defaultDashboard(),
    accountIds: {for (final a in i.accounts) a.id},
    categoryIds: {for (final c in i.categories) c.id},
    loanIds: {for (final l in i.loans) l.id},
  );
});

final nudgeStateProvider = StreamProvider<NudgeState>((ref) => ref.watch(settingsRepoProvider).watchNudgeState());

final challengeStateProvider = StreamProvider<ChallengeState>((ref) => ref.watch(settingsRepoProvider).watchChallengeState());

final nudgesProvider = FutureProvider<List<Nudge>>((ref) async {
  final i = await ref.watch(reportInputsProvider.future);
  final state = await ref.watch(nudgeStateProvider.future);
  final challenges = await ref.watch(challengeStateProvider.future);
  final today = ref.watch(clockProvider).today();
  return buildNudges(
    NudgeInput(
      today: today,
      txs: i.txs,
      accounts: i.accounts,
      categories: i.categories,
      loans: i.loans,
      goals: i.goals,
      parties: i.parties,
      challengeDoneThisMonth: challengeDoneThisMonth(challenges, i.txs, i.loans, today),
    ),
    ref.watch(moneyFormatProvider),
    dismissed: state.dismissed,
    disabled: state.disabled,
  );
});

/// The last 6 months' scores, oldest first; `.last` is this month so far.
final savingsScoreProvider = FutureProvider<List<SavingsScore>>((ref) async {
  final i = await ref.watch(reportInputsProvider.future);
  return scoreTrend(
    txs: i.txs,
    categories: i.categories,
    loans: i.loans,
    today: ref.watch(clockProvider).today(),
    money: ref.watch(moneyFormatProvider),
  );
});

class NudgeController {
  NudgeController(this._repo, this._clock);
  final SettingsRepository _repo;
  final Clock _clock;

  Future<void> dismiss(String id) async => _repo.saveNudgeState((await _repo.nudgeState()).dismiss(id, _clock.today()));

  Future<void> setEnabled(NudgeKind kind, bool enabled) async =>
      _repo.saveNudgeState((await _repo.nudgeState()).withKind(kind, enabled: enabled));
}

final nudgeControllerProvider = Provider<NudgeController>(
  (ref) => NudgeController(ref.watch(settingsRepoProvider), ref.watch(clockProvider)),
);

class ChallengeController {
  ChallengeController(this._repo, this._clock, this._newId);
  final SettingsRepository _repo;
  final Clock _clock;
  final String Function() _newId;

  /// Finishes past months, suggests for this month once, awards badges.
  /// Saves only when something changed.
  Future<void> rollOver(ReportInputs i) async {
    final before = await _repo.challengeState();
    final after = rollOverChallenges(before,
        txs: i.txs, loans: i.loans, categories: i.categories, accounts: i.accounts, today: _clock.today());
    if (jsonEncode(challengeStateToJson(after)) != jsonEncode(challengeStateToJson(before))) {
      await _repo.saveChallengeState(after);
    }
  }

  /// Adds (or accepts) [draft]; returns why it couldn't, or null.
  Future<String?> add(Challenge draft) async {
    final s = await _repo.challengeState();
    if (s.acceptedIn(draft.month).where((c) => c.id != draft.id).length >= kMaxActiveChallenges) {
      return 'You can have up to $kMaxActiveChallenges challenges a month.';
    }
    final c = Challenge(
      id: draft.id.isEmpty ? _newId() : draft.id,
      template: draft.template,
      month: draft.month,
      target: draft.target,
      categoryId: draft.categoryId,
      loanId: draft.loanId,
      source: draft.source,
    );
    await _repo.saveChallengeState(
      s.copyWith(active: [for (final x in s.active) if (x.id != c.id) x, c]),
      summary: 'Started challenge: ${c.template.label}',
    );
    return null;
  }

  Future<String?> accept(String id) async {
    final c = (await _repo.challengeState()).active.where((x) => x.id == id).firstOrNull;
    return c == null ? 'That suggestion is gone.' : add(c);
  }

  Future<void> update(Challenge c) async {
    final s = await _repo.challengeState();
    await _repo.saveChallengeState(
      s.copyWith(active: [for (final x in s.active) x.id == c.id ? c : x]),
      summary: 'Changed challenge: ${c.template.label}',
    );
  }

  /// Skips a suggestion or removes a challenge.
  Future<void> remove(String id) async {
    final s = await _repo.challengeState();
    await _repo.saveChallengeState(
      s.copyWith(active: [for (final x in s.active) if (x.id != id) x]),
      summary: 'Removed a challenge',
    );
  }
}

final challengeControllerProvider = Provider<ChallengeController>(
  (ref) => ChallengeController(ref.watch(settingsRepoProvider), ref.watch(clockProvider), ref.watch(idGenProvider)),
);

/// Watched by Home, Reports and Plans → Challenges so the month rolls over
/// once per app run; reads (not watches) inputs so it never re-runs on edits.
final challengeRolloverProvider = FutureProvider<void>((ref) async {
  final inputs = await ref.read(reportInputsProvider.future);
  await ref.read(challengeControllerProvider).rollOver(inputs);
});
