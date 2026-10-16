import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/content/lessons.dart';
import 'package:paisa/content/quotes.dart';
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

void main() {
  testWidgets('Home shows a quote; tapping it shows the next one', (tester) async {
    await pumpPaisa(tester);
    await scrollPageTo(tester, find.byType(QuoteCard));
    final first = kQuotes.firstWhere((q) => find.text('“${q.text}”').evaluate().isNotEmpty);
    await tester.tap(find.byType(QuoteCard));
    await tester.pumpAndSettle();
    expect(find.text('“${first.text}”'), findsNothing);
    final i = kQuotes.indexOf(first);
    expect(find.text('“${kQuotes[(i + 1) % kQuotes.length].text}”'), findsOneWidget);
  });

  testWidgets('pulling Home down shows another quote', (tester) async {
    await pumpPaisa(tester);
    await scrollPageTo(tester, find.byType(QuoteCard));
    final first = kQuotes.firstWhere((q) => find.text('“${q.text}”').evaluate().isNotEmpty);
    await tester.scrollUntilVisible(find.text('FREE TO SPEND'), -300, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    for (var k = 0; k < 10; k++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await scrollPageTo(tester, find.byType(QuoteCard));
    expect(find.text('“${first.text}”'), findsNothing);
  });

  testWidgets('Learn lists every lesson by topic; opening one marks it read', (tester) async {
    final db = await pumpPaisa(tester, location: '/learn');
    expect(find.text('0 of ${kLessons.length} read'), findsOneWidget);
    expect(find.text('Saving habits'), findsOneWidget);
    await tester.tap(find.text('Pay yourself first'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Save More Tomorrow'), findsWidgets);
    await scrollPageTo(tester, find.text('Sources'));
    expect(find.text('Sources'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(await repo(db).learnRead(), {'pay-yourself-first'});
    expect(find.text('1 of ${kLessons.length} read'), findsOneWidget);
  });

  testWidgets('Home has a Learn card that opens the next unread lesson', (tester) async {
    await pumpPaisa(tester);
    await scrollAndTap(tester, find.byType(LearnCard));
    expect(find.text(kLessons.first.title), findsOneWidget);
  });

  testWidgets('with AI on, Today’s lesson is written from the user’s numbers and cached for the day', (tester) async {
    final gemini = FakeGemini()
      ..answer = jsonEncode({'title': 'Tame the Food spending', 'body': 'Food is 40% above normal.\n\nTry cooking twice more a week.', 'takeaway': 'Plan 5 home meals this week.'});
    final secrets = MemorySecretStore();
    await secrets.write(AiService.keyName, 'AIzaSyD-1234567893kQ');
    final db = await pumpPaisa(tester, location: '/learn', overrides: [
      secretStoreProvider.overrideWithValue(secrets),
      httpClientProvider.overrideWithValue(gemini.client),
    ]);
    await repo(db).saveAi(const AiSettings(enabled: true, model: 'models/gemini-x-flash'), audited: false);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PaisaButton, 'Write today’s lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Tame the Food spending'), findsOneWidget);
    expect(find.textContaining('Plan 5 home meals'), findsOneWidget);
    expect(await repo(db).aiLesson('2026-10-14'), isNotNull);
  });

  testWidgets('a big want offers to wait 24 hours, and goes to the Waiting list instead of being saved', (tester) async {
    final db = await pumpPaisa(tester, location: '/expense/new');
    await tester.tap(find.bySemanticsLabel('Entertainment'));
    await tester.pump();
    await tester.enterText(fieldLabelled('Amount'), '8500');
    await tester.enterText(fieldLabelled('Merchant'), 'Headphones');
    await tester.tap(find.widgetWithText(PaisaButton, 'Save expense'));
    await tester.pumpAndSettle();
    expect(find.text('Wait 24 hours?'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Wait 24 hours'));
    await tester.pumpAndSettle();
    final w = await repo(db).waitList();
    expect(w.items.single.title, 'Headphones');
    expect((await db.select(db.transactions).get()).where((t) => t.title == 'Headphones'), isEmpty);
    await tester.pump(kUndoWindow);
  });

  testWidgets('after 24 hours, Skip counts the money as saved by waiting', (tester) async {
    final db = await pumpPaisa(tester);
    await repo(db).saveWaitList(
      const WaitList(items: [WaitItem(id: 'w', title: 'Headphones', amount: 850000, addedAt: '2026-10-13T08:00:00', categoryId: 'fun')]),
      summary: 'test',
    );
    await tester.pumpAndSettle();
    await scrollPageTo(tester, find.text('Headphones'));
    await tester.tap(find.widgetWithText(PaisaButton, 'Skip'));
    await tester.pumpAndSettle();
    expect(find.text('You saved NPR 8,500 by waiting 🎉'), findsOneWidget);
    expect((await repo(db).waitList()).savedByWaiting, 850000);
    await tester.pump(kUndoWindow);
  });

  testWidgets('after 24 hours, Buy records the expense', (tester) async {
    final db = await pumpPaisa(tester);
    await repo(db).saveWaitList(
      const WaitList(items: [WaitItem(id: 'w', title: 'Headphones', amount: 850000, addedAt: '2026-10-13T08:00:00', categoryId: 'fun')]),
      summary: 'test',
    );
    await tester.pumpAndSettle();
    await scrollPageTo(tester, find.text('Headphones'));
    await tester.tap(find.widgetWithText(PaisaButton, 'Buy'));
    await tester.pumpAndSettle();
    expect((await db.select(db.transactions).get()).where((t) => t.title == 'Headphones'), hasLength(1));
    expect((await repo(db).waitList()).items, isEmpty);
    await tester.pump(kUndoWindow);
  });

  testWidgets('the plan shows what saving becomes in 10 years and what loan interest costs', (tester) async {
    await pumpPaisa(tester);
    expect(find.textContaining('in 10 years'), findsOneWidget);
    expect(find.textContaining('money that buys nothing'), findsOneWidget);
  });
}
