import 'dart:async';

import 'package:flutter/services.dart';

/// One SMS as the phone gave it, before masking.
class RawSms {
  const RawSms({required this.sender, required this.body, required this.receivedAt, this.sourceKey});
  final String sender;
  final String body;
  final DateTime receivedAt;

  /// The phone's id for the message (inbox scans), so it's imported once.
  final String? sourceKey;

  static RawSms? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final sender = raw['sender'];
    final body = raw['body'];
    final at = raw['timestamp'];
    if (sender is! String || body is! String || at is! int) return null;
    return RawSms(
      sender: sender,
      body: body,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(at),
      sourceKey: raw['id']?.toString(),
    );
  }
}

enum SmsAccess {
  /// The phone can't read SMS here (not Android); paste still works.
  unsupported,
  denied,
  granted,
}

/// Where SMS come from: the Android bridge in the app, a fake in tests.
abstract class SmsSource {
  Future<SmsAccess> access();

  /// Asks for READ_SMS / RECEIVE_SMS (and notifications). True if granted.
  Future<bool> requestAccess();

  /// Messages already on the phone from [senders], received since [since].
  Future<List<RawSms>> readInbox({required DateTime since, required List<String> senders});

  /// Messages the background receiver kept while Paisa was closed.
  Future<List<RawSms>> drainQueued();

  /// Live messages while Paisa is running.
  Stream<RawSms> incoming();

  /// Which senders the background receiver keeps and notifies about.
  Future<void> setTrustedSenders(List<String> senders);

  /// True once after Paisa was opened from the "needs review" notification.
  Future<bool> takeOpenInbox();
}

class UnsupportedSmsSource implements SmsSource {
  const UnsupportedSmsSource();
  @override
  Future<SmsAccess> access() async => SmsAccess.unsupported;
  @override
  Future<bool> requestAccess() async => false;
  @override
  Future<List<RawSms>> readInbox({required DateTime since, required List<String> senders}) async => const [];
  @override
  Future<List<RawSms>> drainQueued() async => const [];
  @override
  Stream<RawSms> incoming() => const Stream.empty();
  @override
  Future<void> setTrustedSenders(List<String> senders) async {}
  @override
  Future<bool> takeOpenInbox() async => false;
}

/// The Kotlin side lives in android/app/src/main/kotlin/…/SmsBridge.kt.
class AndroidSmsSource implements SmsSource {
  static const _methods = MethodChannel('paisa/sms');
  static const _events = EventChannel('paisa/sms_events');

  @override
  Future<SmsAccess> access() async =>
      (await _methods.invokeMethod<bool>('hasPermission') ?? false) ? SmsAccess.granted : SmsAccess.denied;

  @override
  Future<bool> requestAccess() async => await _methods.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Future<List<RawSms>> readInbox({required DateTime since, required List<String> senders}) async {
    final list = await _methods.invokeListMethod<Object?>(
      'readInbox',
      {'since': since.millisecondsSinceEpoch, 'senders': senders},
    );
    return [for (final m in list ?? const []) ?RawSms.fromMap(m)];
  }

  @override
  Future<List<RawSms>> drainQueued() async {
    final list = await _methods.invokeListMethod<Object?>('drainQueue');
    return [for (final m in list ?? const []) ?RawSms.fromMap(m)];
  }

  @override
  Stream<RawSms> incoming() => _events.receiveBroadcastStream().map(RawSms.fromMap).where((m) => m != null).cast<RawSms>();

  @override
  Future<void> setTrustedSenders(List<String> senders) => _methods.invokeMethod<void>('setTrustedSenders', senders);

  @override
  Future<bool> takeOpenInbox() async => await _methods.invokeMethod<bool>('takeOpenInbox') ?? false;
}
