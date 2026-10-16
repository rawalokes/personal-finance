import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/repos/sms_repo.dart';
import 'package:paisa/data/repos/transaction_repo.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/sms/sms_models.dart';
import 'package:paisa/sms/sms_source.dart';
import 'package:paisa/store/sms_sync.dart';

import '../data/data_fixtures.dart';
import '../data/sample_data.dart';
import '../data/test_db.dart';
import '../sms/fake_sms_source.dart';

RawSms nabil(String rmks, num amount, DateTime at, {String dir = 'debited', String? id}) => RawSms(
      sender: 'NABIL_ALERT',
      body: 'Dear Customer, your A/C ##4821 has been $dir by NPR $amount.00 on '
          '${at.day}/${at.month}/${at.year} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}. Rmks: $rmks. Avl Bal NPR 1,00,000.00.',
      receivedAt: at,
      sourceKey: id,
    );

void main() {
  late AppDatabase db;
  late SmsRepository repo;
  late SettingsRepository settings;
  late FakeSmsSource phone;
  late SmsSync sync;

  setUp(() async {
    db = openTestDb();
    await seedWithSampleData(db);
    final audit = AuditLog(db, clock: testClock, newId: counterIds('sync-audit'));
    repo = SmsRepository(db, audit, TransactionRepository(db, audit, clock: testClock), clock: testClock, newId: counterIds('s'));
    settings = SettingsRepository(db, audit);
    phone = FakeSmsSource();
    sync = SmsSync(repo: repo, source: phone, settings: settings, clock: testClock);
  });

  test('first sync imports the last 30 days into review, never auto-saving old messages', () async {
    await (db.update(db.accounts)..where((a) => a.id.equals('nabil'))).write(const AccountsCompanion(autoUpdateFromSms: Value(true)));
    phone.inbox = [
      nabil('POS BIG MART', 1200, DateTime(2026, 10, 2, 10), id: '1'),
      nabil('POS PATHAO', 300, DateTime(2026, 8, 1, 10), id: '0'), // older than 30 days
      RawSms(sender: 'NABIL_ALERT', body: 'Your OTP is 123456', receivedAt: DateTime(2026, 10, 3), sourceKey: '2'),
    ];
    final report = await sync.catchUp();
    expect(report.added, 1);
    expect(report.autoSaved, 0);
    expect(phone.lastSince, DateTime(2026, 9, 14, 10, 30), reason: '30 days before 14 Oct 10:30');
    expect((await repo.watchAll().first).single.status, SmsStatus.review);
    expect(phone.trusted, containsAll(['NABIL_ALERT', 'eSewa', 'Khalti']));
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
  });

  test('later syncs read only since the last scan (with an hour of overlap) and may auto-save', () async {
    await sync.catchUp();
    await (db.update(db.accounts)..where((a) => a.id.equals('nabil'))).write(const AccountsCompanion(autoUpdateFromSms: Value(true)));
    phone.inbox = [nabil('SAL ASOJ HIMAL TECH', 92789, DateTime(2026, 10, 14, 10, 15), dir: 'credited', id: '9')];
    final report = await sync.catchUp();
    expect(phone.lastSince, DateTime(2026, 10, 14, 9, 30));
    expect(report.autoSaved, 1);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 + 92789));
  });

  test('two syncs at once read the phone once', () async {
    phone.inbox = [nabil('POS BIG MART', 1200, DateTime(2026, 10, 2, 10), id: '1')];
    final reports = await Future.wait([sync.catchUp(), sync.catchUp()]);
    expect(reports.map((r) => r.added), [1, 1], reason: 'the same run, reported to both callers');
    expect(await repo.list(), hasLength(1));
  });

  test('without permission nothing is read', () async {
    phone.state = SmsAccess.denied;
    phone.inbox = [nabil('POS BIG MART', 1200, DateTime(2026, 10, 2, 10), id: '1')];
    final report = await sync.catchUp();
    expect(report.added, 0);
    expect(await repo.watchAll().first, isEmpty);
  });

  test('live messages are ingested as they arrive', () async {
    final results = <IngestResult>[];
    final sub = sync.live().listen(results.add);
    phone.live.add(nabil('POS BIG MART', 1200, DateTime(2026, 10, 14, 10, 31)));
    await pumpEventQueue();
    await sub.cancel();
    expect(results.single.outcome, IngestOutcome.inbox);
  });

  test('a pasted message goes through the same pipeline', () async {
    final r = await sync.paste(sender: 'Khalti', body: 'Khalti: Rs 380.00 paid to PATHAO NEPAL on 14/10/2026. Txn ID KH-A71C.');
    expect(r.outcome, IngestOutcome.inbox);
    expect(r.message!.categoryId, 'transport');
  });
}
