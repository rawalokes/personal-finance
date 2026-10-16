import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/repos/sms_repo.dart';
import 'package:paisa/data/repos/transaction_repo.dart';
import 'dart:convert';

import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/ai.dart';
import 'package:paisa/store/app_lock.dart';
import 'package:paisa/sms/sms_models.dart';
import 'package:paisa/sms/sms_source.dart';
import 'package:paisa/store/sms_sync.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/toast.dart';

import '../../data/data_fixtures.dart';
import '../../sms/fake_sms_source.dart';
import '../app_harness.dart';
import 'ai_screens_test.dart' show FakeGemini;

const bhatBhateni =
    'Dear Customer, your A/C ##4821 has been debited by NPR 2,450.00 on 14/10/2026 08:41. Rmks: POS BHAT-BHATENI SUPERMARKET MAHARAJGUNJ. Avl Bal NPR 1,39,900.00.';
const salary =
    'Dear Customer, your A/C ##4821 has been credited by NPR 92,789.00 on 14/10/2026 09:12. Rmks: SAL ASOJ 2083 HIMAL TECH. Avl Bal NPR ●●●●●●. -Nabil Bank';

void main() {
  late FakeSmsSource phone;
  setUp(() => phone = FakeSmsSource()..state = SmsAccess.granted);

  Future<(AppDatabase, SmsRepository)> open(WidgetTester tester, {String location = '/activity?seg=inbox'}) async {
    final db = await pumpPaisa(tester, location: location, overrides: [smsSourceProvider.overrideWithValue(phone)]);
    final audit = AuditLog(db, clock: testClock, newId: counterIds('t-sms-audit'));
    final repo = SmsRepository(db, audit, TransactionRepository(db, audit, clock: testClock), clock: testClock, newId: counterIds('t-sms'));
    return (db, repo);
  }

  Future<SmsMessage> add(WidgetTester tester, SmsRepository repo, String body, DateTime at) async {
    final r = await repo.ingest(sender: 'NABIL_ALERT', body: body, receivedAt: at);
    await tester.pumpAndSettle();
    return r.message!;
  }

  testWidgets('Home shows the pending bar; it opens the Transaction Inbox', (tester) async {
    final (_, repo) = await open(tester, location: '/home');
    await add(tester, repo, bhatBhateni, DateTime(2026, 10, 14, 8, 41));
    expect(find.text('1 SMS to review'), findsOneWidget);
    await scrollAndTap(tester, find.text('1 SMS to review'));
    expect(find.text('Needs review · 1'), findsOneWidget);
    expect(find.text('Bhat-Bhateni Supermarket Maharajgunj'), findsOneWidget);
  });

  testWidgets('an inbox card shows the suggestion; Confirm saves it with undo', (tester) async {
    final (db, repo) = await open(tester);
    await add(tester, repo, bhatBhateni, DateTime(2026, 10, 14, 8, 41));
    expect(find.text('Suggested: Expense'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('High confidence'), findsOneWidget);
    expect(find.text('1 waiting · nothing saved until you confirm'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Expense saved · NPR 2,450'), findsOneWidget);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 2450));
    expect(find.text('All caught up'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect(find.text('Needs review · 1'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('Ignore asks first, then the message waits in Rejected / Ignored to be restored', (tester) async {
    final (_, repo) = await open(tester);
    await add(tester, repo, bhatBhateni, DateTime(2026, 10, 14, 8, 41));
    await tester.tap(find.widgetWithText(PaisaButton, 'Ignore'));
    await tester.pumpAndSettle();
    expect(find.text('Ignore this message?'), findsOneWidget);
    await tester.tap(find.text('Ignore message'));
    await tester.pumpAndSettle();
    await tester.pump(kUndoWindow);
    await tapChip(tester, 'Rejected / Ignored · 1');
    expect(find.text('Not counted anywhere.'), findsOneWidget);
    await tester.tap(find.text('Restore to review'));
    await tester.pumpAndSettle();
    expect((await repo.list()).single.status, SmsStatus.review);
    await tester.pump(kUndoWindow);
  });

  testWidgets('acceptance 12: confirming a possible duplicate offers Ignore duplicate / Save anyway', (tester) async {
    final (db, repo) = await open(tester);
    await add(tester, repo, bhatBhateni, DateTime(2026, 10, 14, 8, 41));
    await add(tester, repo, bhatBhateni.replaceFirst('08:41', '08:43'), DateTime(2026, 10, 14, 8, 43));
    expect(find.text('Possible duplicate'), findsOneWidget);
    await tester.tap(find.text('Possible duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Review transaction'), findsOneWidget);
    await scrollAndTap(tester, find.text('Confirm transaction'));
    expect(find.text('This looks like a duplicate'), findsOneWidget);
    await tester.tap(find.text('Ignore duplicate'));
    await tester.pumpAndSettle();
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    final statuses = (await repo.list()).map((m) => m.status);
    expect(statuses, containsAll([SmsStatus.rejected, SmsStatus.review]));
    await tester.pump(kUndoWindow);
  });

  testWidgets('review: proposed accounting, masked SMS, change type and edit details', (tester) async {
    final (_, repo) = await open(tester);
    final m = await add(tester, repo, bhatBhateni, DateTime(2026, 10, 14, 8, 41));
    await tester.tap(find.text('Bhat-Bhateni Supermarket Maharajgunj'));
    await tester.pumpAndSettle();
    expect(find.text('Review transaction'), findsOneWidget);
    await scrollPageTo(tester, find.text('Proposed accounting'));
    expect(find.text('Expense · Groceries'), findsOneWidget);
    await scrollPageTo(tester, find.textContaining('Original SMS'));
    expect(find.textContaining('Avl Bal NPR ●●●●●●'), findsOneWidget);
    expect(find.textContaining('1,39,900'), findsNothing);
    await tester.scrollUntilVisible(find.text('Transaction type'), -200, scrollable: pageScrollable);
    await tester.tap(find.text('Transaction type'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect((await repo.get(m.id)).type, TxType.transfer);
    await scrollPageTo(tester, find.text('From Nabil ••4821'));
    expect(find.text('From Nabil ••4821'), findsOneWidget);
    await tester.tap(find.widgetWithText(PaisaButton, 'Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Amount (NPR)'), '2500');
    await tester.tap(find.widgetWithText(PaisaButton, 'Save details'));
    await tester.pumpAndSettle();
    expect((await repo.get(m.id)).amount, fromRupees(2500));
    await scrollPageTo(tester, find.text('Edited · awaiting your approval'));
    expect(find.text('Edited · awaiting your approval'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('without permission: allow reading SMS, then recent bank SMS are imported for review', (tester) async {
    phone
      ..state = SmsAccess.denied
      ..inbox = [RawSms(sender: 'NABIL_ALERT', body: bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41), sourceKey: '1')];
    await open(tester);
    expect(find.text('Let Paisa read bank SMS'), findsOneWidget);
    await tester.tap(find.text('Allow reading SMS'));
    await tester.pumpAndSettle();
    expect(find.text('Bhat-Bhateni Supermarket Maharajgunj'), findsOneWidget);
    expect(find.textContaining('Reading SMS from'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('paste an SMS when reading is not possible', (tester) async {
    phone.state = SmsAccess.unsupported;
    await open(tester);
    await tester.tap(find.text('Paste an SMS'));
    await tester.pumpAndSettle();
    await tapChip(tester, 'Khalti');
    await tester.enterText(fieldLabelled('Message text'), 'Khalti: Rs 380.00 paid to PATHAO NEPAL on 14/10/2026. Txn ID KH-A71C.');
    await tester.tap(find.widgetWithText(PaisaButton, 'Add to inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Pathao Nepal'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('acceptance 13 (UI): a live salary SMS for an auto-update account is saved with an undo toast', (tester) async {
    final (db, _) = await open(tester, location: '/home');
    await (db.update(db.accounts)..where((a) => a.id.equals('nabil'))).write(const AccountsCompanion(autoUpdateFromSms: Value(true)));
    await tester.pumpAndSettle();
    phone.live.add(RawSms(sender: 'NABIL_ALERT', body: salary, receivedAt: DateTime(2026, 10, 14, 9, 12)));
    await tester.pumpAndSettle();
    expect(find.text('Auto-saved from SMS: + NPR 92,789 · Nabil ••4821'), findsOneWidget);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 + 92789));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    await tester.pump(kUndoWindow);
  });

  testWidgets('a live message that needs review says so', (tester) async {
    await open(tester, location: '/home');
    phone.live.add(RawSms(sender: 'NABIL_ALERT', body: bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41)));
    await tester.pumpAndSettle();
    expect(find.text('New transaction detected — needs your review'), findsOneWidget);
    expect(find.text('1 SMS to review'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('acceptance 20: AI help on a low-confidence SMS is marked "Suggested by AI" and saves nothing', (tester) async {
    final gemini = FakeGemini()
      ..answer = jsonEncode({'type': 'expense', 'categoryId': 'fun', 'confidence': 'high', 'reason': 'A coffee shop.'});
    final secrets = MemorySecretStore();
    await secrets.write(AiService.keyName, 'AIza-key');
    final db = await pumpPaisa(tester, location: '/activity?seg=inbox', overrides: [
      smsSourceProvider.overrideWithValue(phone),
      secretStoreProvider.overrideWithValue(secrets),
      httpClientProvider.overrideWithValue(gemini.client),
    ]);
    final audit = AuditLog(db, clock: testClock, newId: counterIds('t-sms-audit'));
    await SettingsRepository(db, audit)
        .saveAi(const AiSettings(enabled: true, model: 'models/gemini-x-flash', privacy: AiPrivacy.sms), audited: false);
    final repo = SmsRepository(db, audit, TransactionRepository(db, audit, clock: testClock), clock: testClock, newId: counterIds('t-sms'));
    final m = await add(tester, repo,
        'Your A/C ##4821 has been debited by NPR 700.00 on 14/10/2026 11:02. Rmks: POS KATHMANDU KITCHENWARE.', DateTime(2026, 10, 14, 11, 2));
    expect(m.confidence, SmsConfidence.low);
    await tester.tap(find.text('Kathmandu Kitchenware'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('Ask AI for a suggestion'));
    final after = await repo.get(m.id);
    expect(after.suggestedBy, SmsSuggestedBy.ai);
    expect(after.categoryId, 'fun');
    expect(after.confidence, SmsConfidence.medium, reason: 'an AI guess never shows as high confidence');
    expect(after.status, SmsStatus.review, reason: 'AI never approves SMS');
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    await tester.scrollUntilVisible(find.text('Suggested by AI · may be wrong'), -200, scrollable: pageScrollable);
    expect(find.text('Suggested by AI · may be wrong'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });
}
