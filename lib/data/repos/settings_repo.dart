import 'dart:async';
import 'dart:convert';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../db/database.dart';
import '../records.dart' show AuditActor;
import '../report_settings.dart';
import '../settings_models.dart';

/// Saving tax rules whose brackets have gaps, overlaps or bad rates.
class TaxRulesInvalid implements Exception {
  TaxRulesInvalid(this.issues);
  final List<BracketIssue> issues;
  @override
  String toString() => 'TaxRulesInvalid: ${issues.map((i) => i.message).join('; ')}';
}

abstract final class SettingKey {
  static const prefs = 'prefs';
  static const salaryProfile = 'salary.profile';
  static const deductions = 'salary.deductions';
  static const taxRules = 'tax.rules';
  static const security = 'security';
  static const ai = 'ai.settings';
  static const payoff = 'payoff.plan';
  static const aiChat = 'ai.chat';
  static String aiCache(String month) => 'ai.analysis.$month';
  static String aiLesson(String day) => 'ai.lesson.$day';
  static const learnRead = 'learn.read';
  static const waitList = 'waitlist';
  static const smsLastScan = 'sms.last_scan';
  static const smsScannedSenders = 'sms.scanned_senders';
  static const reportsDashboard = 'reports.dashboard';
  static const nudges = 'nudges.state';
  static const challenges = 'challenges';
}

/// Typed access to the `settings` table. A missing document means "use the
/// default": a clean install has no salary, the sample deductions and tax
/// rules (labelled as samples in the UI), AI off.
class SettingsRepository {
  SettingsRepository(this.db, this._audit);

  final AppDatabase db;
  final AuditLog _audit;

  Future<Object?> _read(String key) async {
    final row = await (db.select(db.settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value);
  }

  Stream<Object?> _watch(String key) => (db.select(db.settings)..where((s) => s.key.equals(key)))
      .watchSingleOrNull()
      .map((row) => row == null ? null : jsonDecode(row.value));

  Future<void> _write(String key, Object? value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: jsonEncode(value)));

  Future<void> _save(String key, Object? value, String summary) => db.transaction(() async {
        await _write(key, value);
        await _audit.write(action: 'settings.$key', entity: 'settings', entityId: key, summary: summary);
      });

  T _decode<T>(Object? raw, T Function(Json) decode, T fallback) =>
      raw == null ? fallback : decode((raw as Map).cast<String, Object?>());

  // Preferences change often (theme, grouping, hide balances): not audited.
  Future<AppPrefs> prefs() async => _decode(await _read(SettingKey.prefs), AppPrefs.fromJson, const AppPrefs());
  Stream<AppPrefs> watchPrefs() =>
      _watch(SettingKey.prefs).map((r) => _decode(r, AppPrefs.fromJson, const AppPrefs()));
  Future<void> savePrefs(AppPrefs p) => _write(SettingKey.prefs, p.toJson());

  Future<SalaryProfile> salaryProfile() async =>
      _decode(await _read(SettingKey.salaryProfile), SalaryProfile.fromJson, const SalaryProfile());
  Stream<SalaryProfile> watchSalaryProfile() =>
      _watch(SettingKey.salaryProfile).map((r) => _decode(r, SalaryProfile.fromJson, const SalaryProfile()));
  Future<void> saveSalaryProfile(SalaryProfile p) =>
      _save(SettingKey.salaryProfile, p.toJson(), 'Updated salary settings');

  Future<List<Deduction>> deductions() async {
    final raw = await _read(SettingKey.deductions);
    return raw == null ? sampleDeductions() : deductionsFromJson(raw);
  }

  Stream<List<Deduction>> watchDeductions() =>
      _watch(SettingKey.deductions).map((r) => r == null ? sampleDeductions() : deductionsFromJson(r));
  Future<void> saveDeductions(List<Deduction> list) =>
      _save(SettingKey.deductions, deductionsToJson(list), 'Updated payroll deductions');

  Future<TaxRuleSet> taxRules() async =>
      _decode(await _read(SettingKey.taxRules), taxRulesFromJson, sampleTaxRules());
  Stream<TaxRuleSet> watchTaxRules() =>
      _watch(SettingKey.taxRules).map((r) => _decode(r, taxRulesFromJson, sampleTaxRules()));

  /// Refuses rules with any bracket issue (spec acceptance 9).
  Future<void> saveTaxRules(TaxRuleSet rules) async {
    final issues = [for (final b in rules.categories.values) ...validateBrackets(b)];
    if (issues.isNotEmpty) throw TaxRulesInvalid(issues);
    await _save(SettingKey.taxRules, taxRulesToJson(rules), 'Updated tax rules for FY ${rules.fiscalYear}');
  }

  Future<void> resetTaxRules() => db.transaction(() async {
        await (db.delete(db.settings)..where((s) => s.key.equals(SettingKey.taxRules))).go();
        await _audit.write(
          action: 'settings.${SettingKey.taxRules}',
          entity: 'settings',
          summary: 'Reset tax rules to sample defaults',
        );
      });

  Future<SecuritySettings> security() async =>
      _decode(await _read(SettingKey.security), SecuritySettings.fromJson, const SecuritySettings());
  Stream<SecuritySettings> watchSecurity() =>
      _watch(SettingKey.security).map((r) => _decode(r, SecuritySettings.fromJson, const SecuritySettings()));
  Future<void> saveSecurity(SecuritySettings s) =>
      _save(SettingKey.security, s.toJson(), 'Updated security settings');

  Future<AiSettings> ai() async => _decode(await _read(SettingKey.ai), AiSettings.fromJson, const AiSettings());
  Stream<AiSettings> watchAi() =>
      _watch(SettingKey.ai).map((r) => _decode(r, AiSettings.fromJson, const AiSettings()));

  /// [audited] is false for usage counters, true for user changes.
  Future<void> saveAi(AiSettings s, {bool audited = true}) =>
      audited ? _save(SettingKey.ai, s.toJson(), 'Updated AI assistant settings') : _write(SettingKey.ai, s.toJson());

  Future<PayoffPlanSettings> payoffPlan() async =>
      _decode(await _read(SettingKey.payoff), PayoffPlanSettings.fromJson, const PayoffPlanSettings());
  Stream<PayoffPlanSettings> watchPayoffPlan() =>
      _watch(SettingKey.payoff).map((r) => _decode(r, PayoffPlanSettings.fromJson, const PayoffPlanSettings()));
  Future<void> savePayoffPlan(PayoffPlanSettings p, {required String summary}) =>
      _save(SettingKey.payoff, p.toJson(), summary);

  Future<Json?> aiCache(String month) async => (await _read(SettingKey.aiCache(month)) as Map?)?.cast<String, Object?>();
  Future<void> saveAiCache(String month, Json analysis) => _write(SettingKey.aiCache(month), analysis);

  Future<List<Object?>> aiChat() async => (await _read(SettingKey.aiChat) as List?) ?? const [];
  Future<void> saveAiChat(List<Object?> messages) => _write(SettingKey.aiChat, messages);

  /// When Paisa last read the phone's SMS inbox (ms since epoch).
  Future<int?> smsLastScan() async => await _read(SettingKey.smsLastScan) as int?;
  Future<void> saveSmsLastScan(int millis) => _write(SettingKey.smsLastScan, millis);

  /// The sender IDs that scan covered; a sender added later gets its own
  /// 30-day scan. Null before 1.3.2.
  Future<List<String>?> smsScannedSenders() async => (await _read(SettingKey.smsScannedSenders) as List?)?.cast<String>();
  Future<void> saveSmsScannedSenders(List<String> senders) => _write(SettingKey.smsScannedSenders, senders);

  /// Like [_decode], but a document this version can't read is deleted (so
  /// defaults apply) and its text is kept in the audit log (spec §5).
  T _decodeSafe<T>(String key, Object? raw, T Function(Json) decode, T fallback) {
    if (raw == null) return fallback;
    try {
      return decode((raw as Map).cast<String, Object?>());
    } on Object {
      unawaited(_resetUnreadable(key, raw));
      return fallback;
    }
  }

  Future<void> _resetUnreadable(String key, Object? raw) => db.transaction(() async {
        await (db.delete(db.settings)..where((s) => s.key.equals(key))).go();
        final text = jsonEncode(raw);
        await _audit.write(
          action: 'settings.reset',
          entity: 'settings',
          entityId: key,
          summary: 'Reset unreadable $key to defaults: ${text.length > 500 ? '${text.substring(0, 500)}…' : text}',
          actor: AuditActor.system,
        );
      });

  /// Null = no saved layout (show the default).
  Future<DashboardConfig?> dashboard() async =>
      _decodeSafe<DashboardConfig?>(SettingKey.reportsDashboard, await _read(SettingKey.reportsDashboard), DashboardConfig.fromJson, null);
  Stream<DashboardConfig?> watchDashboard() => _watch(SettingKey.reportsDashboard)
      .map((r) => _decodeSafe<DashboardConfig?>(SettingKey.reportsDashboard, r, DashboardConfig.fromJson, null));

  // Layout edits are frequent and not financial: not audited (like prefs).
  Future<void> saveDashboard(DashboardConfig d) => _write(SettingKey.reportsDashboard, d.toJson());
  Future<void> resetDashboard() => (db.delete(db.settings)..where((s) => s.key.equals(SettingKey.reportsDashboard))).go();

  Future<NudgeState> nudgeState() async =>
      _decodeSafe(SettingKey.nudges, await _read(SettingKey.nudges), NudgeState.fromJson, const NudgeState());
  Stream<NudgeState> watchNudgeState() =>
      _watch(SettingKey.nudges).map((r) => _decodeSafe(SettingKey.nudges, r, NudgeState.fromJson, const NudgeState()));
  Future<void> saveNudgeState(NudgeState s) => _write(SettingKey.nudges, s.toJson());

  Future<ChallengeState> challengeState() async =>
      _decodeSafe(SettingKey.challenges, await _read(SettingKey.challenges), challengeStateFromJson, const ChallengeState());
  Stream<ChallengeState> watchChallengeState() => _watch(SettingKey.challenges)
      .map((r) => _decodeSafe(SettingKey.challenges, r, challengeStateFromJson, const ChallengeState()));

  /// Audited when [summary] is given (the user started, changed or removed one).
  Future<void> saveChallengeState(ChallengeState s, {String? summary}) => summary == null
      ? _write(SettingKey.challenges, challengeStateToJson(s))
      : _save(SettingKey.challenges, challengeStateToJson(s), summary);

  Future<Json?> aiLesson(String day) async => (await _read(SettingKey.aiLesson(day)) as Map?)?.cast<String, Object?>();
  Future<void> saveAiLesson(String day, Json lesson) => _write(SettingKey.aiLesson(day), lesson);

  /// Ids of the Learn lessons the user has read.
  Stream<Set<String>> watchLearnRead() =>
      _watch(SettingKey.learnRead).map((r) => r is List ? {for (final x in r) if (x is String) x} : <String>{});
  Future<Set<String>> learnRead() async {
    final r = await _read(SettingKey.learnRead);
    return r is List ? {for (final x in r) if (x is String) x} : <String>{};
  }

  Future<void> saveLearnRead(Set<String> ids) => _write(SettingKey.learnRead, ids.toList()..sort());

  Future<WaitList> waitList() async => _decodeSafe(SettingKey.waitList, await _read(SettingKey.waitList), waitListFromJson, const WaitList());
  Stream<WaitList> watchWaitList() =>
      _watch(SettingKey.waitList).map((r) => _decodeSafe(SettingKey.waitList, r, waitListFromJson, const WaitList()));
  Future<void> saveWaitList(WaitList w, {required String summary}) => _save(SettingKey.waitList, waitListToJson(w), summary);
}
