import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/integrations/gemini/client.dart';
import 'package:paisa/integrations/gemini/schemas.dart';
import 'package:paisa/store/ai.dart';

import '../data/data_fixtures.dart';
import '../data/sample_data.dart';
import '../data/test_db.dart';
import '../integrations/gemini_test.dart' show goodAnalysis, reply;

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late MemorySecretStore secrets;
  late int calls;
  late String Function(http.Request) respond;

  AiService service() => AiService(
        settings: settings,
        secrets: secrets,
        client: GeminiClient(MockClient((req) async {
          calls++;
          return http.Response(respond(req), 200);
        })),
        clock: testClock,
        audit: AuditLog(db, clock: testClock, newId: counterIds('ai-audit')),
        db: db,
      );

  setUp(() async {
    db = openTestDb();
    await seedWithSampleData(db);
    settings = SettingsRepository(db, testAudit(db));
    secrets = MemorySecretStore();
    calls = 0;
    respond = (_) => jsonEncode(reply(jsonEncode(goodAnalysis)));
  });

  test('acceptance 16: with AI off nothing is sent', () async {
    await secrets.write(AiService.keyName, 'AIza-k');
    await expectLater(service().analyse(), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.disabled)));
    expect(calls, 0);
  });

  test('acceptance 17: on but no key → NO_KEY, nothing sent', () async {
    await settings.saveAi(const AiSettings(enabled: true, model: 'models/x-flash'));
    await expectLater(service().analyse(), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.noKey)));
    expect(calls, 0);
  });

  test('an analysis is made once per month and then served from the cache; regenerate asks again', () async {
    await settings.saveAi(const AiSettings(enabled: true, model: 'models/x-flash'));
    await secrets.write(AiService.keyName, 'AIza-k');
    final s = service();
    final a = await s.analyse();
    expect(a.healthScore, 72);
    expect(a.generatedAt, '2026-10-14T10:30:00');
    await s.analyse();
    expect(calls, 1, reason: 'cached for October');
    await s.analyse(force: true);
    expect(calls, 2);
    expect((await settings.ai()).usedIn('2026-10'), 2);
    expect(await auditSummaries(db), contains('AI analysis of 2026-10'));
  });

  test('the monthly request limit stops further requests', () async {
    await settings.saveAi(const AiSettings(enabled: true, model: 'models/x-flash', monthlyLimit: 1));
    await secrets.write(AiService.keyName, 'AIza-k');
    final s = service();
    await s.analyse();
    await expectLater(s.analyse(force: true), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.limitReached)));
    expect(calls, 1);
  });

  test('acceptance 19: a malformed answer is an error and nothing is cached', () async {
    await settings.saveAi(const AiSettings(enabled: true, model: 'models/x-flash'));
    await secrets.write(AiService.keyName, 'AIza-k');
    respond = (_) => jsonEncode(reply('{"healthScore": 500}'));
    await expectLater(service().analyse(), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.badResponse)));
    expect(await settings.aiCache('2026-10'), isNull);
  });

  test('testing a key lists models and picks a default model', () async {
    respond = (_) => jsonEncode({
          'models': [
            {'name': 'models/gemini-x-flash', 'supportedGenerationMethods': ['generateContent']},
          ],
        });
    final models = await service().testKey('AIza-new');
    expect(models, ['models/gemini-x-flash']);
    expect((await settings.ai()).model, 'models/gemini-x-flash');
  });

  test('the key is kept only in secure storage, shown masked', () async {
    final s = service();
    await s.saveKey('AIzaSyD-1234567893kQ');
    expect(await secrets.read(AiService.keyName), 'AIzaSyD-1234567893kQ');
    expect(maskKey('AIzaSyD-1234567893kQ'), 'AIza••••••••3kQ');
    expect((await db.select(db.settings).get()).any((r) => r.value.contains('AIzaSyD')), isFalse);
    await s.removeKey();
    expect(await secrets.read(AiService.keyName), isNull);
  });

  group('reality checks', () {
    const answer = {
      'verdict': 'wait',
      'headline': 'Wait a week',
      'points': ['It is 9 hours of work', 'Bike moves back 5 days'],
      'actions': ['Put it on your wish list'],
    };

    setUp(() async {
      await settings.saveAi(const AiSettings(enabled: true, model: 'models/x-flash'));
      await secrets.write(AiService.keyName, 'AIza-k');
      respond = (_) => jsonEncode(reply(jsonEncode(answer)));
    });

    test('can I afford it sends the computed facts and the question, every time', () async {
      String? sent;
      respond = (req) {
        sent = req.body;
        return jsonEncode(reply(jsonEncode(answer)));
      };
      final s = service();
      final a = await s.reality(RealityTopic.afford, {'priceNpr': 6500, 'verdict': 'wait'}, question: 'Perfume');
      expect((a.verdict, a.headline, a.points.length, a.actions.single), ('wait', 'Wait a week', 2, 'Put it on your wish list'));
      expect(sent, contains('priceNpr'));
      expect(sent, contains('Perfume'));
      await s.reality(RealityTopic.afford, {'priceNpr': 6500}, question: 'Perfume');
      expect(calls, 2, reason: 'purchases are never cached');
      expect(await auditSummaries(db), contains('AI reality check: can I afford Perfume'));
    });

    test('habit, goal, review and budget checks are cached for the month', () async {
      final s = service();
      expect(await s.cachedReality(RealityTopic.habits), isNull);
      await s.reality(RealityTopic.habits, {'emiLoad': 0.4});
      await s.reality(RealityTopic.habits, {'emiLoad': 0.4});
      expect(calls, 1);
      expect((await s.cachedReality(RealityTopic.habits))!.headline, 'Wait a week');
      await s.reality(RealityTopic.habits, {'emiLoad': 0.4}, force: true);
      expect(calls, 2);
      await s.reality(RealityTopic.goals, const {});
      expect(calls, 3, reason: 'each topic has its own cache');
    });

    test('a malformed answer is an error, never half-shown', () async {
      respond = (_) => jsonEncode(reply(jsonEncode({'verdict': 'yes'})));
      await expectLater(service().reality(RealityTopic.afford, const {}, question: 'x'), throwsA(isA<AiError>()));
    });
  });
}
