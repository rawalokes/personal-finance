import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/store/ai.dart';
import 'package:paisa/store/app_lock.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';

import '../../data/data_fixtures.dart';
import '../../integrations/gemini_test.dart' show goodAnalysis, reply;
import '../app_harness.dart';

const _models = {
  'models': [
    {'name': 'models/gemini-x-flash', 'supportedGenerationMethods': ['generateContent']},
    {'name': 'models/gemini-x-pro', 'supportedGenerationMethods': ['generateContent']},
  ],
};

/// A fake Google AI: answers the models list, and every generate call with
/// [answer] (a JSON string the model "wrote").
class FakeGemini {
  int calls = 0;
  Duration delay = Duration.zero;
  int generateCalls = 0;
  String answer = jsonEncode(goodAnalysis);
  bool rejectKey = false;

  http.Client get client => MockClient((req) async {
        calls++;
        if (rejectKey) return http.Response('{"error":{"message":"API key not valid. Please pass a valid API key."}}', 400);
        if (req.url.path.endsWith('/models')) return http.Response(jsonEncode(_models), 200);
        generateCalls++;
        if (delay > Duration.zero) await Future<void>.delayed(delay);
        return http.Response(jsonEncode(reply(answer)), 200);
      });
}

void main() {
  late FakeGemini gemini;
  late MemorySecretStore secrets;

  setUp(() {
    gemini = FakeGemini();
    secrets = MemorySecretStore();
  });

  Future<AppDatabase> open(WidgetTester tester, {String location = '/home', bool on = false, bool key = false}) async {
    if (key) await secrets.write(AiService.keyName, 'AIzaSyD-1234567893kQ');
    final db = await pumpPaisa(tester, location: location, overrides: [
      secretStoreProvider.overrideWithValue(secrets),
      httpClientProvider.overrideWithValue(gemini.client),
    ]);
    if (on) {
      await SettingsRepository(db, AuditLog(db, clock: testClock, newId: counterIds('t-audit')))
          .saveAi(const AiSettings(enabled: true, model: 'models/gemini-x-flash'), audited: false);
      await tester.pumpAndSettle();
    }
    return db;
  }

  testWidgets('acceptance 16: with AI off there is no AI UI and nothing is sent', (tester) async {
    await open(tester, key: true);
    expect(find.textContaining('AI insight'), findsNothing);
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();
    expect(find.text('Suggest budgets with AI'), findsNothing);
    expect(gemini.calls, 0);
  });

  testWidgets('acceptance 17: on without a key, Home asks for the key; a bad key shows the error', (tester) async {
    await open(tester, on: true);
    await scrollAndTap(tester, find.text('Add your Google AI key to get insights'));
    expect(find.text('AI assistant'), findsWidgets);
    gemini.rejectKey = true;
    await tester.enterText(fieldLabelled('Google AI key'), 'AIza-bad');
    await scrollAndTap(tester, find.text('Test key'));
    expect(find.textContaining('Google didn’t accept this key'), findsOneWidget);
    expect(await secrets.read(AiService.keyName), isNull, reason: 'a rejected key is not saved');
  });

  testWidgets('settings: turn on, test a key, pick the model, preview the payload, remove the key', (tester) async {
    await open(tester, location: '/settings/ai');
    expect(find.text('Use AI to analyse my finances'), findsOneWidget);
    await tester.tap(find.byType(PaisaToggle).first);
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Google AI key'), 'AIzaSyD-1234567893kQ');
    await scrollAndTap(tester, find.text('Test key'));
    expect(find.text('✓ Connected'), findsOneWidget);
    expect(await secrets.read(AiService.keyName), 'AIzaSyD-1234567893kQ');
    await scrollPageTo(tester, find.text('AIza••••••••3kQ'));
    expect(find.text('AIza••••••••3kQ'), findsOneWidget);
    await tapChip(tester, 'gemini-x-pro');
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Preview what will be sent'));
    expect(find.textContaining('"month": "2026-10"'), findsOneWidget);
    expect(find.textContaining('Nabil'), findsNothing, reason: 'no account names at any privacy level');
    expect(find.textContaining('recentTransactions'), findsNothing, reason: 'summaries only by default');
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Remove'), -200, scrollable: pageScrollable);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(await secrets.read(AiService.keyName), isNull);
    await tester.pump(kUndoWindow);
  });

  testWidgets('insights: from the Home card, with score, findings, actions and the AI label; cached', (tester) async {
    await open(tester, on: true, key: true);
    await scrollAndTap(tester, find.text('Get this month’s analysis'));
    expect(find.text('72'), findsOneWidget);
    expect(find.text('Entertainment over budget'), findsOneWidget);
    expect(find.text('Pay NPR 5,000 extra on Personal loan A'), findsOneWidget);
    expect(find.text('Credit card bill due 18 Oct'), findsOneWidget);
    expect(find.textContaining('Generated by AI · may be wrong · 14 Oct 2026'), findsOneWidget);
    expect(gemini.generateCalls, 1);
    await scrollAndTap(tester, find.text('Pay NPR 5,000 extra on Personal loan A'));
    expect(find.text('Payoff planner'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Health score 72'), findsOneWidget, reason: 'Home shows the cached analysis');
    await scrollAndTap(tester, find.textContaining('Health score 72'));
    expect(gemini.generateCalls, 1, reason: 'served from the cache');
    await scrollAndTap(tester, find.text('Regenerate'));
    expect(gemini.generateCalls, 2);
  });

  testWidgets('leaving AI Insights before the answer arrives is safe; Home then shows the result', (tester) async {
    await open(tester, on: true, key: true);
    gemini.delay = const Duration(seconds: 2);
    await scrollPageTo(tester, find.text('Get this month’s analysis'));
    await tester.tap(find.text('Get this month’s analysis'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Analysing'), findsOneWidget, reason: 'the request is still running');
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('AI insights'), findsNothing, reason: 'the screen is gone before the answer');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Health score 72'), findsOneWidget);
  });

  testWidgets('acceptance 19: a malformed answer shows a friendly error and the app keeps working', (tester) async {
    await open(tester, on: true, key: true);
    await scrollAndTap(tester, find.text('Get this month’s analysis'));
    // The first analysis was good; regenerate with a broken one.
    gemini.answer = '{"healthScore": "high"}';
    await scrollAndTap(tester, find.text('Regenerate'));
    expect(find.textContaining('The AI returned an unexpected answer'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('AVAILABLE TO SPEND'), findsOneWidget);
  });

  testWidgets('Ask Paisa: a suggested question gets an answer, kept on the phone', (tester) async {
    final db = await open(tester, location: '/ai/chat', on: true, key: true);
    gemini.answer = jsonEncode({
      'answer': 'Pay Personal loan A first: it has the highest rate.',
      'usedData': ['loans'],
      'deepLink': 'planner',
    });
    await tester.tap(find.text('Which loan should I pay off first?'));
    await tester.pumpAndSettle();
    expect(find.text('Pay Personal loan A first: it has the highest rate.'), findsOneWidget);
    expect(find.text('Used: loans'), findsOneWidget);
    expect(find.text('Open payoff planner'), findsOneWidget);
    final saved = await SettingsRepository(db, AuditLog(db, clock: testClock, newId: counterIds('t-audit'))).aiChat();
    expect(saved, hasLength(2));
  });

  testWidgets('budget suggestions apply only on a tap, audited as AI', (tester) async {
    final db = await open(tester, location: '/plans?seg=budgets', on: true, key: true);
    gemini.answer = jsonEncode({
      'suggestions': [
        {'categoryId': 'fun', 'limitNpr': 4000, 'reason': 'Entertainment ran over in 3 of the last 4 months.'},
      ],
    });
    await scrollAndTap(tester, find.text('Suggest budgets with AI'));
    expect(find.text('Entertainment ran over in 3 of the last 4 months.'), findsOneWidget);
    final before = (await (db.select(db.expenseCategories)..where((c) => c.id.equals('fun'))).getSingle()).monthlyBudget;
    expect(before, isNot(400000));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    final after = (await (db.select(db.expenseCategories)..where((c) => c.id.equals('fun'))).getSingle()).monthlyBudget;
    expect(after, 400000);
    final audit = await (db.select(db.auditEntries)..where((a) => a.action.equals('category.budget'))).get();
    expect(audit.last.actor, 'ai');
    await tester.pump(kUndoWindow);
  });

  testWidgets('payoff planner: Explain with AI shows the explanation', (tester) async {
    await open(tester, location: '/loans/planner', on: true, key: true);
    gemini.answer = jsonEncode({
      'explanation': 'Avalanche clears the costliest loan first.',
      'tradeoffs': ['Less money for goals this year'],
      'sustainableExtraNpr': 8000,
    });
    await scrollAndTap(tester, find.text('Explain with AI'));
    expect(find.text('Avalanche clears the costliest loan first.'), findsOneWidget);
    expect(find.text('Less money for goals this year'), findsOneWidget);
    expect(find.textContaining('8,000'), findsWidgets);
  });

  testWidgets('salary: Check with AI flags issues and changes nothing', (tester) async {
    await open(tester, location: '/settings/salary', on: true, key: true);
    gemini.answer = jsonEncode({'summary': 'Looks consistent.', 'flags': ['Verify the SSF rate with your payslip']});
    await scrollAndTap(tester, find.text('Check with AI'));
    expect(find.text('Looks consistent.'), findsOneWidget);
    expect(find.text('Verify the SSF rate with your payslip'), findsOneWidget);
  });
}
