import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clock.dart';
import '../data/records.dart';
import '../data/repos/settings_repo.dart';
import '../data/repos/sms_repo.dart';
import '../sms/sms_models.dart';
import '../sms/sms_source.dart';
import 'data_providers.dart';

class SyncReport {
  const SyncReport({this.added = 0, this.autoSaved = 0, this.undo = const []});
  final int added;
  final int autoSaved;
  final List<IngestResult> undo;
}

/// Brings phone SMS into the Transaction Inbox (spec §6 step 1): the phone
/// inbox since the last scan, and live messages while Paisa runs.
class SmsSync {
  SmsSync({required this.repo, required this.source, required this.settings, required this.clock});

  final SmsRepository repo;
  final SmsSource source;
  final SettingsRepository settings;
  final Clock clock;

  /// How far back the first scan reads.
  static const firstScan = Duration(days: 30);

  Future<SyncReport>? _running;

  /// One sync at a time: a second call while one runs gets the same result.
  Future<SyncReport> catchUp() => _running ??= _catchUp().whenComplete(() => _running = null);

  Future<SyncReport> _catchUp() async {
    final sms = await source.access() == SmsAccess.granted;
    final notifications = await source.notificationAccess();
    if (!sms && !notifications) return const SyncReport();
    final senders = await repo.trustedSenders();
    await source.setTrustedSenders(senders);
    final results = <IngestResult>[];

    // Wallet app notifications are gone once dismissed, so the phone keeps
    // the ones that arrived while Paisa was closed until they're taken here.
    if (notifications) {
      final queued = await source.takeNotifications()
        ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
      for (final m in queued) {
        results.add(await repo.ingest(sender: m.sender, body: m.body, receivedAt: m.receivedAt, sourceKey: m.sourceKey));
      }
    }
    if (sms) await _readInbox(senders, results);
    final added = results.where((r) => r.outcome == IngestOutcome.inbox || r.outcome == IngestOutcome.autoSaved).toList();
    return SyncReport(
      added: added.length,
      autoSaved: added.where((r) => r.outcome == IngestOutcome.autoSaved).length,
      undo: added,
    );
  }

  Future<void> _readInbox(List<String> senders, List<IngestResult> results) async {
    final last = await settings.smsLastScan();
    final now = clock.now();

    // The phone inbox since the last scan (with an hour's overlap), which
    // includes anything that arrived while Paisa was closed: the receiver
    // only notifies, it never stores message text. On the first scan these
    // are old messages the user may have recorded by hand already, so
    // nothing is auto-saved.
    final since = last == null ? now.subtract(firstScan) : DateTime.fromMillisecondsSinceEpoch(last).subtract(const Duration(hours: 1));
    final inbox = await source.readInbox(since: since, senders: senders)
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    for (final m in inbox) {
      results.add(await repo.ingest(
        sender: m.sender,
        body: m.body,
        receivedAt: m.receivedAt,
        sourceKey: m.sourceKey,
        allowAutoSave: last != null,
      ));
    }
    // Senders approved since the last scan (a new account, a bank added in
    // Settings, or an update with more bank IDs) never had their first scan.
    final scanned = await settings.smsScannedSenders();
    if (last != null) {
      final fresh = [for (final s in senders) if (scanned == null || !scanned.contains(s)) s];
      if (fresh.isNotEmpty) {
        final old = await source.readInbox(since: now.subtract(firstScan), senders: fresh)
          ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
        for (final m in old) {
          results.add(await repo.ingest(
            sender: m.sender,
            body: m.body,
            receivedAt: m.receivedAt,
            sourceKey: m.sourceKey,
            allowAutoSave: false,
          ));
        }
      }
    }
    await settings.saveSmsLastScan(now.millisecondsSinceEpoch);
    await settings.saveSmsScannedSenders(senders);
  }

  /// Live SMS and wallet notifications while Paisa runs.
  Stream<IngestResult> live() => source
      .incoming()
      .asyncMap((m) => repo.ingest(sender: m.sender, body: m.body, receivedAt: m.receivedAt, sourceKey: m.sourceKey));

  /// "Paste an SMS": the fallback when reading SMS isn't possible.
  Future<IngestResult> paste({required String sender, required String body}) =>
      repo.ingest(sender: sender, body: body, receivedAt: clock.now());
}

/// The Android bridge on Android; elsewhere only paste works.
final smsSourceProvider = Provider<SmsSource>(
  (ref) => Platform.isAndroid ? AndroidSmsSource() : const UnsupportedSmsSource(),
);

final smsRepoProvider = Provider<SmsRepository>((ref) => SmsRepository(
      ref.watch(databaseProvider),
      ref.watch(auditLogProvider),
      ref.watch(transactionRepoProvider),
      clock: ref.watch(clockProvider),
      newId: ref.watch(idGenProvider),
    ));

final smsSyncProvider = Provider<SmsSync>((ref) => SmsSync(
      repo: ref.watch(smsRepoProvider),
      source: ref.watch(smsSourceProvider),
      settings: ref.watch(settingsRepoProvider),
      clock: ref.watch(clockProvider),
    ));

final smsMessagesProvider = StreamProvider<List<SmsMessage>>((ref) => ref.watch(smsRepoProvider).watchAll());

final smsAccessProvider = FutureProvider<SmsAccess>((ref) => ref.watch(smsSourceProvider).access());

final notificationAccessProvider = FutureProvider<bool>((ref) => ref.watch(smsSourceProvider).notificationAccess());

final trustedSendersProvider = FutureProvider<List<String>>((ref) {
  ref.watch(accountsProvider);
  ref.watch(configListProvider(ConfigList.banks));
  return ref.watch(smsRepoProvider).trustedSenders();
});
