import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/repos/sms_repo.dart';
import 'package:paisa/data/repos/transaction_repo.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/sms/sms_models.dart';

import 'data_fixtures.dart';
import 'sample_data.dart';
import 'test_db.dart';

const _bhatBhateni =
    'Dear Customer, your A/C ##4821 has been debited by NPR 2,450.00 on 14/10/2026 08:41. Rmks: POS BHAT-BHATENI SUPERMARKET MAHARAJGUNJ. Avl Bal NPR 1,39,900.00.';
const _salary =
    'Dear Customer, your A/C ##4821 has been credited by NPR 92,789.00 on 14/10/2026 09:12. Rmks: SAL ASOJ 2083 HIMAL TECH. Avl Bal NPR 2,32,689.00. -Nabil Bank';
const _transfer = 'A/C ##4821 debited by NPR 15,000.00 on 13/10/2026 19:20. Rmks: FONEPAY TRF TO NIC ASIA ##2290 SELF. Avl Bal NPR 1,27,350.00.';

void main() {
  late AppDatabase db;
  late SmsRepository sms;
  late AuditLog audit;

  setUp(() async {
    db = openTestDb();
    await seedWithSampleData(db);
    // The sample salary is NPR 92,789 into Nabil.
    await (db.update(db.incomeTypes)..where((t) => t.id.equals('salary')))
        .write(IncomeTypesCompanion(expectedAmount: Value(fromRupees(92789))));
    audit = AuditLog(db, clock: testClock, newId: counterIds('sms-audit'));
    sms = SmsRepository(db, audit, TransactionRepository(db, audit, clock: testClock), clock: testClock, newId: counterIds('sms'));
  });

  Future<SmsMessage> only() async => (await sms.watchAll().first).single;

  test('a bank SMS lands in the inbox masked, waiting for review; nothing is saved', () async {
    final r = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    expect(r.outcome, IngestOutcome.inbox);
    final m = await only();
    expect(m.status, SmsStatus.review);
    expect(m.maskedBody, contains('Avl Bal NPR ●●●●●●'));
    expect(m.maskedBody, isNot(contains('1,39,900')));
    expect(m.type, TxType.expense);
    expect(m.categoryId, 'groceries');
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect(await auditSummaries(db), contains('New SMS detected: Bhat-Bhateni Supermarket Maharajgunj'));
  });

  test('OTPs, offers and unknown senders are not stored', () async {
    expect((await sms.ingest(sender: 'NABIL_ALERT', body: 'Your OTP is 123456', receivedAt: DateTime(2026, 10, 14))).outcome,
        IngestOutcome.ignored);
    expect((await sms.ingest(sender: 'SPAMMER', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14))).outcome,
        IngestOutcome.ignored);
    expect(await sms.watchAll().first, isEmpty);
  });

  test('the same phone message is imported once (rescan or broadcast + scan)', () async {
    await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41), sourceKey: '77');
    final again = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41), sourceKey: '77');
    final viaBroadcast = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    expect(again.outcome, IngestOutcome.alreadySeen);
    expect(viaBroadcast.outcome, IngestOutcome.alreadySeen);
    expect(await sms.watchAll().first, hasLength(1));
  });

  test('an imported old message never auto-saves, and identical text later is a possible duplicate', () async {
    await (db.update(db.accounts)..where((a) => a.id.equals('nabil'))).write(const AccountsCompanion(autoUpdateFromSms: Value(true)));
    final old = await sms.ingest(sender: 'NABIL_ALERT', body: _salary, receivedAt: DateTime(2026, 10, 14, 9, 12), allowAutoSave: false);
    expect(old.outcome, IngestOutcome.inbox);
    final repeat = await sms.ingest(sender: 'NABIL_ALERT', body: _salary, receivedAt: DateTime(2026, 10, 14, 9, 13));
    expect(repeat.outcome, IngestOutcome.inbox);
    expect(repeat.message!.duplicateOfId, old.message!.id);
  });

  test('confirming saves an SMS transaction, updates the balance, and undo puts it back', () async {
    final r = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    final undo = await sms.confirm(r.message!.id);
    final m = await only();
    expect(m.status, SmsStatus.approved);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 2450));
    final tx = txnFromRow(await (db.select(db.transactions)..where((t) => t.id.equals(m.transactionId!))).getSingle());
    expect(tx.source, TxSource.sms);
    expect(tx.smsId, m.id);
    expect(tx.categoryId, 'groceries');
    expect(tx.title, 'Bhat-Bhateni Supermarket Maharajgunj');
    await undo();
    expect((await only()).status, SmsStatus.review);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
  });

  test('acceptance 12: a repeat within 10 minutes is flagged and confirming it asks first', () async {
    await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    final second = await sms.ingest(
      sender: 'NABIL_ALERT',
      body: _bhatBhateni.replaceFirst('08:41', '08:43'),
      receivedAt: DateTime(2026, 10, 14, 8, 43),
    );
    expect(second.message!.duplicateOfId, isNotNull);
    await expectLater(sms.confirm(second.message!.id), throwsA(isA<SmsPossibleDuplicate>()));
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    await sms.confirm(second.message!.id, force: true);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 2450));
  });

  test('acceptance 13: auto-update saves confident income at once, audited as SMS; undo reverses it', () async {
    await (db.update(db.accounts)..where((a) => a.id.equals('nabil'))).write(const AccountsCompanion(autoUpdateFromSms: Value(true)));
    final r = await sms.ingest(sender: 'NABIL_ALERT', body: _salary, receivedAt: DateTime(2026, 10, 14, 9, 12));
    expect(r.outcome, IngestOutcome.autoSaved);
    expect((await only()).autoSaved, isTrue);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 + 92789));
    final entry = (await db.select(db.auditEntries).get()).lastWhere((e) => e.action == 'transaction.add');
    expect(entry.actor, 'sms');
    await r.undo!();
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
    expect((await only()).status, SmsStatus.review);
  });

  test('auto-update never saves a transfer or a possible duplicate', () async {
    await (db.update(db.accounts)..where((a) => a.id.equals('nabil'))).write(const AccountsCompanion(autoUpdateFromSms: Value(true)));
    expect((await sms.ingest(sender: 'NABIL_ALERT', body: _transfer, receivedAt: DateTime(2026, 10, 13, 19, 20))).outcome,
        IngestOutcome.inbox);
    await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    final dup = await sms.ingest(
        sender: 'NABIL_ALERT', body: _bhatBhateni.replaceFirst('08:41', '08:44'), receivedAt: DateTime(2026, 10, 14, 8, 44));
    expect(dup.outcome, IngestOutcome.inbox);
  });

  test('a transfer moves money between own accounts and is not spending', () async {
    final r = await sms.ingest(sender: 'NABIL_ALERT', body: _transfer, receivedAt: DateTime(2026, 10, 13, 19, 20));
    await sms.confirm(r.message!.id);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350 - 15000));
    expect(await balanceOf(db, 'nic'), fromRupees(385000 + 15000));
  });

  test('ignore (reject) keeps it out of every balance; restore brings it back', () async {
    final r = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    final undo = await sms.reject(r.message!.id);
    expect((await only()).status, SmsStatus.rejected);
    await undo();
    expect((await only()).status, SmsStatus.review);
    await sms.reject(r.message!.id);
    await sms.restore(r.message!.id);
    expect((await only()).status, SmsStatus.review);
    await sms.later(r.message!.id);
    expect((await only()).status, SmsStatus.later);
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
  });

  test('edit, change type and change category are kept until confirmed', () async {
    final r = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    final id = r.message!.id;
    await sms.edit(id, SmsEdit(amount: fromRupees(2500), accountId: 'nabil', date: '2026-10-14', time: '08:41', merchant: 'Bhat-Bhateni', description: 'Weekly shop'));
    await sms.setCategory(id, 'family');
    var m = await only();
    expect(m.amount, fromRupees(2500));
    expect(m.edited, isTrue);
    expect(m.categoryId, 'family');
    await sms.setType(id, TxType.transfer);
    m = await only();
    expect(m.type, TxType.transfer);
    expect(m.counterAccountId, isNotNull, reason: 'a transfer gets another own account to start with');
    expect(m.counterAccountId, isNot('nabil'));
    expect(await balanceOf(db, 'nabil'), fromRupees(142350));
  });

  test('a message with no matching account cannot be confirmed until one is picked', () async {
    final r = await sms.ingest(
        sender: 'NABIL_ALERT', body: 'Your A/C ##9999 has been debited by NPR 700.00 on 14/10/2026. Rmks: POS BIG MART.', receivedAt: DateTime(2026, 10, 14));
    await expectLater(sms.confirm(r.message!.id), throwsA(isA<SmsNotReady>()));
  });

  test('a loan EMI confirms as a repayment split into principal and interest', () async {
    final r = await sms.ingest(
      sender: 'GIBL',
      body: 'GIBL: Dear Customer, NPR 11,501.00 debited from A/C ##3307 on 13/10/2026 06:05 towards LOAN EMI RECOVERY LN-0042. Thank you.',
      receivedAt: DateTime(2026, 10, 13, 6, 5),
    );
    await sms.confirm(r.message!.id);
    final tx = txnFromRow((await db.select(db.transactions).get()).firstWhere((t) => t.smsId == r.message!.id));
    expect(tx.type, TxType.loanRepayment);
    expect(tx.interest, fromRupees(2144));
    expect(tx.principal, fromRupees(9357));
    expect(tx.title, 'Scooter loan installment');
  });

  test('pending count covers review and later', () async {
    final a = await sms.ingest(sender: 'NABIL_ALERT', body: _bhatBhateni, receivedAt: DateTime(2026, 10, 14, 8, 41));
    await sms.ingest(sender: 'NABIL_ALERT', body: _transfer, receivedAt: DateTime(2026, 10, 13, 19, 20));
    await sms.later(a.message!.id);
    expect(await sms.watchPendingCount().first, 2);
  });
}
