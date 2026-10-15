import 'dart:convert';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../db/database.dart';
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
}
