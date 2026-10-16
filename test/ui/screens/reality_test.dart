import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart' show FlutterError, Offset, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/ai.dart';
import 'package:paisa/store/app_lock.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/ui/encourage/home_cards.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';
import 'ai_screens_test.dart' show FakeGemini;

SettingsRepository repo(AppDatabase db) => SettingsRepository(db, AuditLog(db, clock: testClock, newId: counterIds('t-audit')));

Future<void> ask(WidgetTester tester, {required String item, required String price}) async {
  await tester.enterText(fieldLabelled('What do you want to buy?'), item);
  await tester.enterText(fieldLabelled('Price (NPR)'), price);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Can I afford it: more than you have is a clear no; it can go on the wish list', (tester) async {
    final db = await pumpPaisa(tester, location: '/afford');
    expect(find.text('Can I afford it?'), findsWidgets);
    await ask(tester, item: 'Perfume', price: '1000000');
    expect(find.text('No — not right now'), findsOneWidget);
    expect(find.textContaining('more than you have'), findsOneWidget);
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Add to wish list'));
    final w = await repo(db).waitList();
    expect((w.wishes.single.title, w.wishes.single.amount), ('Perfume', fromRupees(1000000)));
    await tester.pump(kUndoWindow);
  });

  testWidgets('a small buy shows its real cost: hours of work and what it becomes in 10 years', (tester) async {
    await pumpPaisa(tester, location: '/afford');
    await ask(tester, item: 'Tea', price: '500');
    await scrollPageTo(tester, find.textContaining('in 10 years'));
    expect(find.textContaining('hours of work'), findsOneWidget);
    expect(find.textContaining('in 10 years'), findsOneWidget);
  });

  testWidgets('with AI on, the decoder asks Gemini for an honest answer', (tester) async {
    final gemini = FakeGemini()
      ..answer = jsonEncode({
        'verdict': 'wait',
        'headline': 'Perfume can wait until your EMIs are paid',
        'points': ['It is 9 hours of work'],
        'actions': ['Put it on your wish list'],
      });
    final secrets = MemorySecretStore();
    await secrets.write(AiService.keyName, 'AIzaSyD-1234567893kQ');
    final db = await pumpPaisa(tester, location: '/afford', overrides: [
      secretStoreProvider.overrideWithValue(secrets),
      httpClientProvider.overrideWithValue(gemini.client),
    ]);
    await repo(db).saveAi(const AiSettings(enabled: true, model: 'models/gemini-x-flash'), audited: false);
    await tester.pumpAndSettle();
    await ask(tester, item: 'Perfume', price: '6500');
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Ask AI for a reality check'));
    expect(find.text('Perfume can wait until your EMIs are paid'), findsOneWidget);
    expect(find.text('Put it on your wish list'), findsOneWidget);
  });

  testWidgets('Wish list: add a wish, see when you can afford it, decide you don’t want it', (tester) async {
    final db = await pumpPaisa(tester, location: '/wishlist');
    expect(find.text('Wish list'), findsWidgets);
    await tester.tap(find.widgetWithText(PaisaButton, 'Add a wish'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('What is it?'), 'Bluetooth speaker');
    await tester.enterText(fieldLabelled('Price (NPR)'), '4000');
    await tapChip(tester, 'Must have');
    await tester.tap(find.widgetWithText(PaisaButton, 'Add to wish list'));
    await tester.pumpAndSettle();
    expect(find.text('Bluetooth speaker'), findsOneWidget);
    expect(find.text('Must have'), findsOneWidget);
    expect(find.textContaining(RegExp('Can afford now|month|Not while')), findsWidgets);

    await tester.tap(find.text('Bluetooth speaker'));
    await tester.pumpAndSettle();
    expect(find.text('Can I afford it?'), findsWidgets);
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'I don’t want it'));
    final w = await repo(db).waitList();
    expect(w.items, isEmpty);
    expect(w.savedByWaiting, fromRupees(4000));
    await tester.pump(kUndoWindow);
  });

  testWidgets('My money reality: habits, plan vs reality for last month, and AI is optional', (tester) async {
    await pumpPaisa(tester, location: '/reality');
    expect(find.text('My money reality'), findsWidgets);
    expect(find.text('EMIs vs income'), findsOneWidget);
    await scrollPageTo(tester, find.text('Emergency fund'));
    await scrollPageTo(tester, find.text('Plan vs reality'));
    await tapChip(tester, 'Last month');
    await scrollPageTo(tester, find.textContaining('Saved'));
    expect(find.textContaining('Turn on the AI assistant'), findsWidgets);
  });

  testWidgets('a goal gets a reality verdict', (tester) async {
    final db = await pumpPaisa(tester, location: '/reality');
    await db.into(db.goals).insert(GoalsCompanion.insert(id: 'g', name: 'Dream car', kind: 'Major purchase', target: fromRupees(9000000), targetDate: const Value('2027-04-14')));
    await tester.pumpAndSettle();
    await scrollPageTo(tester, find.text('Dream car'));
    expect(find.text('Not realistic'), findsOneWidget);
  });

  testWidgets('Budget plan: pick a proven method and apply it as budgets', (tester) async {
    final db = await pumpPaisa(tester, location: '/reality/budget');
    expect(find.text('Recommended'), findsOneWidget);
    await tapChip(tester, '50/30/20');
    expect(find.textContaining('50% needs'), findsOneWidget);
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Apply as my budgets'));
    await tester.tap(find.widgetWithText(PaisaButton, 'Apply'));
    await tester.pumpAndSettle();
    final budgets = (await db.select(db.expenseCategories).get()).where((c) => (c.monthlyBudget ?? 0) > 0);
    expect(budgets, isNotEmpty);
    expect(find.textContaining('budgets set'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('Home has the reality check and the can-I-afford-it entry', (tester) async {
    await pumpPaisa(tester);
    await scrollPageTo(tester, find.byType(RealityCard));
    expect(find.text('Reality check'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Can I afford…?'));
    await tester.pumpAndSettle();
    expect(find.text('What do you want to buy?'), findsOneWidget);
  });

  testWidgets('Plans → Goals shows each goal’s reality verdict', (tester) async {
    final db = await pumpPaisa(tester, location: '/plans?seg=goals');
    await db.into(db.goals).insert(GoalsCompanion.insert(id: 'g', name: 'Dream car', kind: 'Major purchase', target: fromRupees(9000000), targetDate: const Value('2027-04-14')));
    await tester.pumpAndSettle();
    await scrollPageTo(tester, find.text('Dream car'));
    expect(find.text('Not realistic'), findsOneWidget);
  });

  testWidgets('Plans → Budgets links to the budget plan', (tester) async {
    await pumpPaisa(tester, location: '/plans');
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Build a budget plan'));
    expect(find.text('Budget plan'), findsWidgets);
  });

  testWidgets('every reality screen fits a small 320 px phone', (tester) async {
    for (final loc in ['/home', '/reality', '/reality/budget', '/wishlist', '/afford?item=Perfume&price=6500']) {
      await pumpPaisa(tester, location: loc, size: const Size(320, 640));
      for (var k = 0; k < 6; k++) {
        await tester.drag(pageScrollable, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      final e = tester.takeException();
      expect(e, isNull, reason: '$loc: ${e is FlutterError ? e.toStringDeep() : e}');
    }
  });
}
