import 'models.dart';
import 'money.dart';

const Duration kDuplicateWindow = Duration(minutes: 10);

/// What duplicate detection needs to know about an SMS.
class SmsFingerprint {
  const SmsFingerprint({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.direction,
    required this.receivedAt,
    required this.bodyHash,
  });
  final String id;
  final String? accountId;
  final Paisa amount;
  final Direction direction;
  final DateTime receivedAt;
  final String bodyHash;
}

/// Id of the earlier message [incoming] probably repeats, or null.
/// Callers pass only messages that were not rejected.
String? findDuplicate(
  SmsFingerprint incoming,
  Iterable<SmsFingerprint> earlier, {
  Duration window = kDuplicateWindow,
}) {
  for (final e in earlier) {
    if (e.id == incoming.id) continue;
    if (e.bodyHash == incoming.bodyHash) return e.id;
    final sameMovement = e.accountId != null &&
        e.accountId == incoming.accountId &&
        e.amount == incoming.amount &&
        e.direction == incoming.direction;
    if (sameMovement && incoming.receivedAt.difference(e.receivedAt).abs() <= window) return e.id;
  }
  return null;
}
