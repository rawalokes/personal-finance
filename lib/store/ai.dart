import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/audit_log.dart';
import '../data/clock.dart';
import '../data/db/database.dart';
import '../data/mappers.dart';
import '../data/records.dart';
import '../data/repos/settings_repo.dart';
import '../data/secret_store.dart';
import '../data/settings_models.dart';
import '../finance/finance.dart';
import '../integrations/gemini/client.dart';
import '../integrations/gemini/prompts.dart';
import '../integrations/gemini/redact.dart';
import '../integrations/gemini/schemas.dart';
import '../sms/sms_models.dart';
import 'app_lock.dart';
import 'data_providers.dart';

/// 'AIza••••••••3kQ' (spec §9.2).
String maskKey(String key) => key.length <= 7 ? '••••' : '${key.substring(0, 4)}••••••••${key.substring(key.length - 3)}';

/// The AI assistant (spec §9). Enforces the guardrails in code:
/// - nothing is sent unless the assistant is on and a key is set;
/// - a monthly request limit;
/// - the summary is redacted by privacy level;
/// - every request is audited with actor `ai`;
/// - answers are validated, and the monthly analysis is cached.
/// The AI never writes balances: suggestions are applied by the user.
class AiService {
  AiService({
    required this.settings,
    required this.secrets,
    required this.client,
    required this.clock,
    required this.audit,
    required this.db,
  });

  static const keyName = 'gemini_api_key';

  final SettingsRepository settings;
  final SecretStore secrets;
  final GeminiClient client;
  final Clock clock;
  final AuditLog audit;
  final AppDatabase db;

  Future<String?> key() => secrets.read(keyName);
  Future<void> saveKey(String key) => secrets.write(keyName, key.trim());
  Future<void> removeKey() => secrets.delete(keyName);

  /// "Test key": lists the models this key can use, and picks a default
  /// model if none is chosen yet.
  Future<List<String>> testKey(String apiKey) async {
    final models = await client.listModels(apiKey.trim());
    final s = await settings.ai();
    if (s.model == null || !models.contains(s.model)) {
      final pick = defaultModel(models);
      if (pick != null) await settings.saveAi(s.copyWith(model: pick), audited: false);
    }
    return models;
  }

  Future<SummaryInput> summaryInput(AiPrivacy privacy) async => SummaryInput(
        today: clock.today(),
        accounts: (await db.select(db.accounts).get()).map(accountFromRow).toList(),
        loans: (await db.select(db.loans).get()).map(loanFromRow).toList(),
        transactions: ((await db.select(db.transactions).get()).map(txnFromRow).toList()
          ..sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'))),
        categories: (await db.select(db.expenseCategories).get()).map(categoryFromRow).toList(),
        goals: (await db.select(db.goals).get()).map(goalFromRow).toList(),
        privacy: privacy,
      );

  /// Exactly what would be sent (Settings → Preview what will be sent).
  Future<String> previewPayload() async {
    final s = await settings.ai();
    return const JsonEncoder.withIndent('  ').convert(buildSummaryPayload(await summaryInput(s.privacy)));
  }

  /// Checks the guardrails and counts the request. Returns key and model.
  Future<(String, String, AiSettings)> _admit() async {
    final s = await settings.ai();
    if (!s.enabled) throw AiError(AiErrorCode.disabled);
    final k = await key();
    if (k == null || k.isEmpty) throw AiError(AiErrorCode.noKey);
    final month = monthKey(clock.today());
    final used = s.usedIn(month);
    if (used >= s.monthlyLimit) throw AiError(AiErrorCode.limitReached);
    final model = s.model ?? defaultModel(await client.listModels(k));
    if (model == null) throw AiError(AiErrorCode.server, 'Your key has no text model available.');
    await settings.saveAi(s.copyWith(usageMonth: month, usageCount: used + 1, model: model), audited: false);
    return (k, model, s);
  }

  Future<Map<String, Object?>> _ask(String task, String prompt, Map<String, Object?> schema) async {
    final (k, model, _) = await _admit();
    final out = await client.generateJson(apiKey: k, model: model, system: kSystemPrompt, prompt: prompt, schema: schema);
    await audit.write(action: 'ai.$task', entity: 'analysis', summary: _auditText(task), actor: AuditActor.ai);
    return out;
  }

  String _auditText(String task) => switch (task) {
        'analysis' => 'AI analysis of ${monthKey(clock.today())}',
        'chat' => 'Asked Paisa AI a question',
        'explain' => 'AI explained the payoff plan',
        'budgets' => 'AI suggested budgets',
        'sms' => 'AI suggested a type for an unclear SMS',
        _ => 'AI checked the salary breakdown',
      };

  /// This month's analysis: from the cache unless [force] (spec §9.4: cache
  /// per month, regenerate only on demand).
  Future<AiAnalysis> analyse({bool force = false}) async {
    final month = monthKey(clock.today());
    if (!force) {
      final cached = await settings.aiCache(month);
      if (cached != null) return AiAnalysis.fromJson(cached);
    }
    final s = await settings.ai();
    final summary = buildSummaryPayload(await summaryInput(s.privacy));
    final raw = await _ask('analysis', analysisPrompt(summary), analysisSchema);
    final parsed = AiAnalysis.fromJson(raw);
    final stamped = AiAnalysis.fromJson({...parsed.toJson(), 'generatedAt': clock.stamp()});
    await settings.saveAiCache(month, stamped.toJson());
    return stamped;
  }

  /// The cached analysis for this month, without any request.
  Future<AiAnalysis?> cachedAnalysis() async {
    final cached = await settings.aiCache(monthKey(clock.today()));
    if (cached == null) return null;
    try {
      return AiAnalysis.fromJson(cached);
    } on AiError {
      return null;
    }
  }

  /// Ask Paisa. The conversation stays on the phone.
  Future<ChatAnswer> ask(String question) async {
    final s = await settings.ai();
    final history = [
      for (final m in await settings.aiChat())
        if (m is Map) ((m['role'] ?? '') as String, (m['text'] ?? '') as String),
    ];
    final recent = history.length > 8 ? history.sublist(history.length - 8) : history;
    final summary = buildSummaryPayload(await summaryInput(s.privacy));
    final answer = ChatAnswer.fromJson(await _ask('chat', chatPrompt(summary, recent, question), chatSchema));
    await settings.saveAiChat([
      ...await settings.aiChat(),
      {'role': 'user', 'text': question},
      {'role': 'assistant', 'text': answer.answer, 'usedData': answer.usedData, 'deepLink': answer.deepLink},
    ]);
    return answer;
  }

  Future<void> clearChat() => settings.saveAiChat(const []);

  Future<PlanExplanation> explainPlan(Map<String, Object?> plan) async {
    final s = await settings.ai();
    final summary = buildSummaryPayload(await summaryInput(s.privacy));
    return PlanExplanation.fromJson(await _ask('explain', explainPlanPrompt(summary, plan), explainSchema));
  }

  Future<BudgetSuggestions> suggestBudgets() async {
    final s = await settings.ai();
    final summary = buildSummaryPayload(await summaryInput(s.privacy));
    return BudgetSuggestions.fromJson(await _ask('budgets', budgetPrompt(summary), budgetSchema));
  }

  /// Low-confidence SMS help (spec §9.4). Sends the masked SMS only when
  /// the privacy level allows SMS text; the answer is only a suggestion.
  Future<SmsAiSuggestion> suggestSms(SmsMessage m) async {
    final s = await settings.ai();
    if (s.privacy != AiPrivacy.sms) throw AiError(AiErrorCode.disabled, 'Allow “Include SMS text” in Settings → AI assistant first.');
    final categories = (await db.select(db.expenseCategories).get()).map(categoryFromRow).where((c) => c.active && c.isTopLevel && c.system == null);
    final incomeTypes = (await db.select(db.incomeTypes).get()).map(incomeTypeFromRow).where((t) => t.active);
    final accounts = (await db.select(db.accounts).get()).map(accountFromRow).where((a) => !a.archived);
    final raw = await _ask(
      'sms',
      smsHelpPrompt(
        maskedSms: m.maskedBody,
        direction: m.direction.name,
        amountNpr: toWholeRupees(m.amount),
        categories: [for (final c in categories) {'id': c.id, 'name': c.name}],
        incomeTypes: [for (final t in incomeTypes) {'id': t.id, 'name': t.name}],
        accounts: [for (final a in accounts) {'id': a.id, 'name': a.shortName}],
      ),
      smsHelpSchema,
    );
    return SmsAiSuggestion.fromJson(raw);
  }

  Future<SalaryCheck> checkSalary(Map<String, Object?> salary) async =>
      SalaryCheck.fromJson(await _ask('salary', salaryCheckPrompt(salary), salaryCheckSchema));
}

/// Real HTTP in the app; tests override with a MockClient.
final httpClientProvider = Provider<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final aiServiceProvider = Provider<AiService>((ref) => AiService(
      settings: ref.watch(settingsRepoProvider),
      secrets: ref.watch(secretStoreProvider),
      client: GeminiClient(ref.watch(httpClientProvider)),
      clock: ref.watch(clockProvider),
      audit: ref.watch(auditLogProvider),
      db: ref.watch(databaseProvider),
    ));

/// Whether a key is saved (for the Home card and settings), re-read on demand.
final aiKeyProvider = FutureProvider<String?>((ref) {
  ref.watch(aiSettingsProvider);
  return ref.watch(aiServiceProvider).key();
});

/// This month's cached analysis for the Home card (no request is made).
final aiCachedAnalysisProvider = FutureProvider<AiAnalysis?>((ref) {
  ref.watch(aiSettingsProvider);
  return ref.watch(aiServiceProvider).cachedAnalysis();
});

/// Runs [run] and turns any failure into an [AiError] the UI can show.
Future<T> runAi<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on AiError {
    rethrow;
  } on Object {
    throw AiError(AiErrorCode.server);
  }
}
