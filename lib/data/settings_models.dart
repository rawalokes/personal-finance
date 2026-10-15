import '../finance/finance.dart';

// Settings documents stored as JSON in the `settings` table. Every decoder is
// strict: unknown enum values or missing required fields throw
// FormatException, so corrupt settings are noticed instead of silently reset.

typedef Json = Map<String, Object?>;

T _enum<T extends Enum>(List<T> values, Object? raw, String field) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  throw FormatException('Unknown $field: $raw');
}

T _req<T>(Json j, String key) {
  final v = j[key];
  if (v is T) return v;
  throw FormatException('Missing or invalid "$key"');
}

T? _opt<T>(Json j, String key) {
  final v = j[key];
  if (v == null) return null;
  if (v is T) return v as T;
  throw FormatException('Invalid "$key"');
}

double? _optDouble(Json j, String key) => (_opt<num>(j, key))?.toDouble();

enum CalendarPref { bs, ad }

enum ThemePref { dark, light }

/// Currency & date & display preferences (Settings → Preferences).
class AppPrefs {
  const AppPrefs({
    this.grouping = Grouping.lakh,
    this.calendar = CalendarPref.ad,
    this.theme = ThemePref.dark,
    this.hideBalances = false,
  });

  final Grouping grouping;

  /// Calendar of the Home header date line. Transactions keep AD dates.
  final CalendarPref calendar;
  final ThemePref theme;
  final bool hideBalances;

  AppPrefs copyWith({Grouping? grouping, CalendarPref? calendar, ThemePref? theme, bool? hideBalances}) => AppPrefs(
        grouping: grouping ?? this.grouping,
        calendar: calendar ?? this.calendar,
        theme: theme ?? this.theme,
        hideBalances: hideBalances ?? this.hideBalances,
      );

  Json toJson() => {
        'grouping': grouping.name,
        'calendar': calendar.name,
        'theme': theme.name,
        'hideBalances': hideBalances,
      };

  static AppPrefs fromJson(Json j) => AppPrefs(
        grouping: _enum(Grouping.values, j['grouping'] ?? 'lakh', 'grouping'),
        calendar: _enum(CalendarPref.values, j['calendar'] ?? 'ad', 'calendar'),
        theme: _enum(ThemePref.values, j['theme'] ?? 'dark', 'theme'),
        hideBalances: _opt<bool>(j, 'hideBalances') ?? false,
      );
}

enum SalaryEntryMode { gross, takeHome }

/// Spec §4 `SalaryProfile`. A clean install has no employer and no gross.
class SalaryProfile {
  const SalaryProfile({
    this.employer = '',
    this.grossMonthly = 0,
    this.basicPct = 60,
    this.entryMode = SalaryEntryMode.gross,
    this.payday = '',
    this.taxCategory = 'individual',
  });

  final String employer;
  final Paisa grossMonthly;
  final double basicPct;
  final SalaryEntryMode entryMode;
  final String payday;
  final String taxCategory;

  SalaryProfile copyWith({
    String? employer,
    Paisa? grossMonthly,
    double? basicPct,
    SalaryEntryMode? entryMode,
    String? payday,
    String? taxCategory,
  }) =>
      SalaryProfile(
        employer: employer ?? this.employer,
        grossMonthly: grossMonthly ?? this.grossMonthly,
        basicPct: basicPct ?? this.basicPct,
        entryMode: entryMode ?? this.entryMode,
        payday: payday ?? this.payday,
        taxCategory: taxCategory ?? this.taxCategory,
      );

  Json toJson() => {
        'employer': employer,
        'grossMonthly': grossMonthly,
        'basicPct': basicPct,
        'entryMode': entryMode.name,
        'payday': payday,
        'taxCategory': taxCategory,
      };

  static SalaryProfile fromJson(Json j) => SalaryProfile(
        employer: _opt<String>(j, 'employer') ?? '',
        grossMonthly: _opt<int>(j, 'grossMonthly') ?? 0,
        basicPct: _optDouble(j, 'basicPct') ?? 60,
        entryMode: _enum(SalaryEntryMode.values, j['entryMode'] ?? 'gross', 'entryMode'),
        payday: _opt<String>(j, 'payday') ?? '',
        taxCategory: _opt<String>(j, 'taxCategory') ?? 'individual',
      );
}

Json deductionToJson(Deduction d) => {
      'id': d.id,
      'name': d.name,
      'kind': d.kind.name,
      'paidBy': d.paidBy.name,
      'method': d.method.name,
      'rate': d.rate,
      'amount': d.amount,
      'base': d.base.name,
      'annualLimit': d.annualLimit,
      'retirementDeductible': d.retirementDeductible,
      'effectiveFrom': d.effectiveFrom,
      'effectiveTo': d.effectiveTo,
      'active': d.active,
      'scheme': d.scheme?.name,
    };

Deduction deductionFromJson(Json j) => Deduction(
      id: _req<String>(j, 'id'),
      name: _req<String>(j, 'name'),
      kind: _enum(DeductionKind.values, j['kind'], 'kind'),
      paidBy: _enum(PaidBy.values, j['paidBy'] ?? 'employee', 'paidBy'),
      method: _enum(CalcMethod.values, j['method'] ?? 'fixed', 'method'),
      rate: _optDouble(j, 'rate'),
      amount: _opt<int>(j, 'amount'),
      base: _enum(SalaryBase.values, j['base'] ?? 'gross', 'base'),
      annualLimit: _opt<int>(j, 'annualLimit'),
      retirementDeductible: _opt<bool>(j, 'retirementDeductible') ?? false,
      effectiveFrom: _opt<String>(j, 'effectiveFrom'),
      effectiveTo: _opt<String>(j, 'effectiveTo'),
      active: _opt<bool>(j, 'active') ?? true,
      scheme: j['scheme'] == null ? null : _enum(DeductionScheme.values, j['scheme'], 'scheme'),
    );

List<Object?> deductionsToJson(List<Deduction> list) => [for (final d in list) deductionToJson(d)];

List<Deduction> deductionsFromJson(Object? raw) {
  if (raw is! List) throw const FormatException('Deductions must be a list');
  return [for (final e in raw) deductionFromJson((e as Map).cast<String, Object?>())];
}

Json _bracketToJson(TaxBracket b) => {'min': b.min, 'max': b.max, 'ratePct': b.ratePct, 'condition': b.condition};

TaxBracket _bracketFromJson(Json j) => TaxBracket(
      min: _req<int>(j, 'min'),
      max: _opt<int>(j, 'max'),
      ratePct: (_req<num>(j, 'ratePct')).toDouble(),
      condition: _opt<String>(j, 'condition'),
    );

Json taxRulesToJson(TaxRuleSet r) => {
      'id': r.id,
      'jurisdiction': r.jurisdiction,
      'fiscalYear': r.fiscalYear,
      'effectiveFrom': r.effectiveFrom,
      'effectiveTo': r.effectiveTo,
      'calculation': r.calculation.name,
      'categories': {
        for (final e in r.categories.entries) e.key: [for (final b in e.value) _bracketToJson(b)],
      },
      'waiveFirstSlabForSsf': r.waiveFirstSlabForSsf,
      'retirementCap': r.retirementCap,
      'retirementMaxPctOfGross': r.retirementMaxPctOfGross,
      'isSampleDefault': r.isSampleDefault,
      'verifiedAt': r.verifiedAt,
    };

TaxRuleSet taxRulesFromJson(Json j) {
  final cats = _req<Map<String, Object?>>(j, 'categories');
  return TaxRuleSet(
    id: _req<String>(j, 'id'),
    jurisdiction: _req<String>(j, 'jurisdiction'),
    fiscalYear: _req<String>(j, 'fiscalYear'),
    effectiveFrom: _req<String>(j, 'effectiveFrom'),
    effectiveTo: _req<String>(j, 'effectiveTo'),
    calculation: _enum(TaxCalculation.values, j['calculation'] ?? 'annual', 'calculation'),
    categories: {
      for (final e in cats.entries)
        e.key: [for (final b in e.value! as List) _bracketFromJson((b as Map).cast<String, Object?>())],
    },
    waiveFirstSlabForSsf: _req<bool>(j, 'waiveFirstSlabForSsf'),
    retirementCap: _req<int>(j, 'retirementCap'),
    retirementMaxPctOfGross: (_req<num>(j, 'retirementMaxPctOfGross')).toDouble(),
    isSampleDefault: _req<bool>(j, 'isSampleDefault'),
    verifiedAt: _opt<String>(j, 'verifiedAt'),
  );
}

/// Security & privacy toggles. The PIN itself lives in secure storage.
class SecuritySettings {
  const SecuritySettings({
    this.appLock = false,
    this.biometric = true,
    this.autoLock = true,
    this.blockScreenshots = false,
  });

  final bool appLock;

  /// Offer fingerprint/face unlock as well as the PIN.
  final bool biometric;

  /// Lock again after 1 minute in the background.
  final bool autoLock;

  /// Android FLAG_SECURE: no screenshots, blank in the recents list.
  final bool blockScreenshots;

  SecuritySettings copyWith({bool? appLock, bool? biometric, bool? autoLock, bool? blockScreenshots}) =>
      SecuritySettings(
        appLock: appLock ?? this.appLock,
        biometric: biometric ?? this.biometric,
        autoLock: autoLock ?? this.autoLock,
        blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      );

  Json toJson() => {
        'appLock': appLock,
        'biometric': biometric,
        'autoLock': autoLock,
        'blockScreenshots': blockScreenshots,
      };

  static SecuritySettings fromJson(Json j) => SecuritySettings(
        appLock: _opt<bool>(j, 'appLock') ?? false,
        biometric: _opt<bool>(j, 'biometric') ?? true,
        autoLock: _opt<bool>(j, 'autoLock') ?? true,
        blockScreenshots: _opt<bool>(j, 'blockScreenshots') ?? false,
      );
}

/// What leaves the device when AI runs (spec §9.2).
enum AiPrivacy {
  summaries('Summaries only'),
  merchants('Summaries + merchants'),
  sms('Include SMS text');

  const AiPrivacy(this.label);
  final String label;
}

/// AI assistant settings. The API key lives in secure storage, never here.
class AiSettings {
  const AiSettings({
    this.enabled = false,
    this.model,
    this.privacy = AiPrivacy.summaries,
    this.monthlyLimit = 100,
    this.usageMonth,
    this.usageCount = 0,
  });

  final bool enabled;

  /// Full model name from the API's list, e.g. 'models/gemini-…-flash'.
  final String? model;
  final AiPrivacy privacy;
  final int monthlyLimit;

  /// 'YYYY-MM' that [usageCount] belongs to.
  final String? usageMonth;
  final int usageCount;

  /// Requests used in [month] (0 once a new month starts).
  int usedIn(String month) => usageMonth == month ? usageCount : 0;

  AiSettings copyWith({
    bool? enabled,
    String? model,
    AiPrivacy? privacy,
    int? monthlyLimit,
    String? usageMonth,
    int? usageCount,
  }) =>
      AiSettings(
        enabled: enabled ?? this.enabled,
        model: model ?? this.model,
        privacy: privacy ?? this.privacy,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
        usageMonth: usageMonth ?? this.usageMonth,
        usageCount: usageCount ?? this.usageCount,
      );

  Json toJson() => {
        'enabled': enabled,
        'model': model,
        'privacy': privacy.name,
        'monthlyLimit': monthlyLimit,
        'usageMonth': usageMonth,
        'usageCount': usageCount,
      };

  static AiSettings fromJson(Json j) => AiSettings(
        enabled: _opt<bool>(j, 'enabled') ?? false,
        model: _opt<String>(j, 'model'),
        privacy: _enum(AiPrivacy.values, j['privacy'] ?? 'summaries', 'privacy'),
        monthlyLimit: _opt<int>(j, 'monthlyLimit') ?? 100,
        usageMonth: _opt<String>(j, 'usageMonth'),
        usageCount: _opt<int>(j, 'usageCount') ?? 0,
      );
}

/// The saved payoff plan (spec §4 `PayoffPlan`).
class PayoffPlanSettings {
  const PayoffPlanSettings({this.extraMonthly = 0, this.strategy = PayoffStrategy.avalanche, this.savedAt});

  final Paisa extraMonthly;
  final PayoffStrategy strategy;
  final String? savedAt;

  Json toJson() => {'extraMonthly': extraMonthly, 'strategy': strategy.name, 'savedAt': savedAt};

  static PayoffPlanSettings fromJson(Json j) => PayoffPlanSettings(
        extraMonthly: _opt<int>(j, 'extraMonthly') ?? 0,
        strategy: _enum(PayoffStrategy.values, j['strategy'] ?? 'avalanche', 'strategy'),
        savedAt: _opt<String>(j, 'savedAt'),
      );
}
