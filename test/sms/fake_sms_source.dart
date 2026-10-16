import 'dart:async';

import 'package:paisa/sms/sms_source.dart';

/// A phone with an SMS inbox and a live stream.
class FakeSmsSource implements SmsSource {
  SmsAccess state = SmsAccess.granted;
  bool grantOnRequest = true;
  List<RawSms> inbox = [];
  List<String>? trusted;
  DateTime? lastSince;
  final live = StreamController<RawSms>.broadcast();

  @override
  Future<SmsAccess> access() async => state;
  @override
  Future<bool> requestAccess() async {
    if (grantOnRequest) state = SmsAccess.granted;
    return grantOnRequest;
  }

  @override
  Future<List<RawSms>> readInbox({required DateTime since, required List<String> senders}) async {
    lastSince = since;
    return inbox.where((m) => !m.receivedAt.isBefore(since)).toList();
  }

  @override
  Stream<RawSms> incoming() => live.stream;
  @override
  Future<void> setTrustedSenders(List<String> senders) async => trusted = senders;
  bool openInbox = false;
  @override
  Future<bool> takeOpenInbox() async {
    final o = openInbox;
    openInbox = false;
    return o;
  }
}

