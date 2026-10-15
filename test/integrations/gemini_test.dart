import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/integrations/gemini/client.dart';
import 'package:paisa/integrations/gemini/prompts.dart';
import 'package:paisa/integrations/gemini/redact.dart';
import 'package:paisa/integrations/gemini/schemas.dart';

import '../data/sample_data.dart';

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// A Gemini generateContent reply whose text is [text].
Map<String, Object?> reply(String text) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    };

const goodAnalysis = {
  'healthScore': 72,
  'headline': 'Spending is under control, but loans cost NPR 5,965 in interest a month.',
  'findings': [
    {'title': 'Entertainment over budget', 'detail': 'NPR 5,640 of NPR 5,000.', 'severity': 'warning'},
  ],
  'actions': [
    {'title': 'Pay NPR 5,000 extra on Personal loan A', 'why': 'Highest rate.', 'deepLink': 'planner'},
  ],
  'risks': ['Credit card bill due 18 Oct'],
};

SummaryInput sampleSummary(AiPrivacy privacy) => SummaryInput(
      today: '2026-10-14',
      accounts: sampleAccounts,
      loans: sampleLoans,
      transactions: sampleTransactions,
      categories: const [],
      goals: const [],
      privacy: privacy,
    );

void main() {
  group('client', () {
    test('lists models that can generate content and picks a flash model by default', () async {
      late http.Request seen;
      final client = GeminiClient(MockClient((req) async {
        seen = req;
        return json({
          'models': [
            {'name': 'models/text-embedding-004', 'supportedGenerationMethods': ['embedContent']},
            {'name': 'models/gemini-pro-x', 'supportedGenerationMethods': ['generateContent']},
            {'name': 'models/gemini-fast-flash', 'supportedGenerationMethods': ['generateContent']},
          ],
        });
      }));
      final models = await client.listModels('AIza-good');
      expect(models, ['models/gemini-pro-x', 'models/gemini-fast-flash']);
      expect(defaultModel(models), 'models/gemini-fast-flash');
      expect(seen.headers['x-goog-api-key'], 'AIza-good');
      expect(seen.url.toString(), isNot(contains('AIza')), reason: 'the key never goes in the URL');
    });

    test('a bad key is reported as invalid, a 429 as a rate limit', () async {
      final bad = GeminiClient(MockClient((_) async => json({'error': {'message': 'API key not valid'}}, 400)));
      await expectLater(bad.listModels('nope'), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.invalidKey)));
      final busy = GeminiClient(MockClient((_) async => json({'error': {'message': 'quota'}}, 429)));
      await expectLater(busy.listModels('k'), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.rateLimited)));
    });

    test('offline and timeout are typed errors too', () async {
      final offline = GeminiClient(MockClient((_) async => throw http.ClientException('no route')));
      await expectLater(offline.listModels('k'), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.offline)));
      final slow = GeminiClient(
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(slow.listModels('k'), throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.timeout)));
    });

    test('generateJson sends the system prompt and schema and returns the parsed JSON', () async {
      late Map<String, Object?> body;
      final client = GeminiClient(MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, Object?>;
        return json(reply(jsonEncode(goodAnalysis)));
      }));
      final out = await client.generateJson(
        apiKey: 'k', model: 'models/x-flash', system: 'SYS', prompt: 'PROMPT', schema: analysisSchema,
      );
      expect(out['healthScore'], 72);
      expect((body['systemInstruction']! as Map)['parts'], [{'text': 'SYS'}]);
      final config = body['generationConfig']! as Map;
      expect(config['responseMimeType'], 'application/json');
      expect(config['temperature'], 0.3);
    });

    test('acceptance 19: malformed AI JSON is a friendly BAD_RESPONSE error', () async {
      final client = GeminiClient(MockClient((_) async => json(reply('{"healthScore": oops'))));
      await expectLater(
        client.generateJson(apiKey: 'k', model: 'm', system: 's', prompt: 'p', schema: analysisSchema),
        throwsA(isA<AiError>().having((e) => e.code, 'code', AiErrorCode.badResponse)),
      );
    });
  });

  group('schemas', () {
    test('a valid analysis parses; one breaking the schema is rejected', () {
      final a = AiAnalysis.fromJson(goodAnalysis);
      expect(a.healthScore, 72);
      expect(a.actions.single.deepLink, 'planner');
      expect(() => AiAnalysis.fromJson({...goodAnalysis, 'healthScore': 140}), throwsA(isA<AiError>()));
      expect(() => AiAnalysis.fromJson({'headline': 'x'}), throwsA(isA<AiError>()));
    });

    test('budget suggestions and chat answers parse', () {
      final s = BudgetSuggestions.fromJson({
        'suggestions': [
          {'categoryId': 'fun', 'limitNpr': 6000, 'reason': 'You spent 5,640'},
        ],
      });
      expect(s.items.single.limit, fromRupees(6000));
      final c = ChatAnswer.fromJson({'answer': 'Pay Personal loan A first.', 'usedData': ['loans']});
      expect(c.usedData, ['loans']);
    });
  });

  group('redaction', () {
    test('acceptance 18: "Summaries only" holds no merchant names, SMS text or account numbers', () {
      final payload = jsonEncode(buildSummaryPayload(sampleSummary(AiPrivacy.summaries)));
      for (final secret in ['Bhat-Bhateni', 'WorldLink', 'Big Mart', 'Daraz', 'QFX', '4821', '2290', '5512', '3307', '0915', 'Nabil ••', 'A/C']) {
        expect(payload.contains(secret), isFalse, reason: 'leaked "$secret"');
      }
      final map = jsonDecode(payload) as Map<String, Object?>;
      expect(map['currency'], 'NPR');
      expect(map['available'], 184020);
      expect((map['loans']! as List).first, containsPair('name', 'Scooter loan'));
      expect(map.containsKey('recentTransactions'), isFalse);
    });

    test('"Summaries + merchants" adds transaction titles, still without account numbers', () {
      final payload = jsonEncode(buildSummaryPayload(sampleSummary(AiPrivacy.merchants)));
      expect(payload, contains('WorldLink internet'));
      expect(payload.contains('4821'), isFalse);
    });

    test('category spending is sent by category id, with recent months, even without budgets', () {
      final input = sampleSummary(AiPrivacy.summaries);
      final map = buildSummaryPayload(SummaryInput(
        today: input.today,
        accounts: input.accounts,
        loans: input.loans,
        transactions: input.transactions,
        categories: [for (final c in seedCategories) c],
        goals: const [],
        privacy: input.privacy,
      ));
      final cats = (map['categories']! as List).cast<Map<String, Object?>>();
      final groceries = cats.firstWhere((c) => c['categoryId'] == 'groceries');
      expect(groceries['name'], 'Groceries');
      expect(groceries.containsKey('budget'), isFalse, reason: 'a clean install has no budgets');
      final months = (groceries['spentByMonth']! as Map).cast<String, Object?>();
      expect(months['2026-10'], greaterThan(0));
      expect(months.length, lessThanOrEqualTo(6));
      expect(budgetPrompt(map), contains('"categories"'));
    });

    test('amounts are sent in whole rupees, not paisa', () {
      final map = buildSummaryPayload(sampleSummary(AiPrivacy.summaries));
      expect(map['income'], 26240);
      expect(map['expenses'], 53674);
    });
  });
}
