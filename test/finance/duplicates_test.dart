import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/duplicates.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';

SmsFingerprint fp(String id, int minute,
        {String account = 'nabil', num rupees = 2450, Direction dir = Direction.debit, String? hash}) =>
    SmsFingerprint(
      id: id,
      accountId: account,
      amount: fromRupees(rupees),
      direction: dir,
      receivedAt: DateTime.utc(2026, 10, 14, 8, minute),
      bodyHash: hash ?? 'hash-$id',
    );

void main() {
  final s2 = fp('s2', 41);

  test('same account, amount and direction within 10 minutes is a duplicate', () {
    expect(findDuplicate(fp('s3', 43), [s2]), 's2');
    expect(findDuplicate(fp('s3', 51), [s2]), 's2');
  });

  test('identical body hash is a duplicate whatever the time', () {
    expect(findDuplicate(fp('s3', 59, rupees: 1, hash: 'hash-s2'), [s2]), 's2');
  });

  test('not a duplicate when outside the window or anything differs', () {
    expect(findDuplicate(fp('s3', 52), [s2]), isNull);
    expect(findDuplicate(fp('s3', 43, dir: Direction.credit), [s2]), isNull);
    expect(findDuplicate(fp('s3', 43, account: 'gibl'), [s2]), isNull);
    expect(findDuplicate(fp('s3', 43, rupees: 2451), [s2]), isNull);
  });

  test('a message is never a duplicate of itself', () {
    expect(findDuplicate(s2, [s2]), isNull);
  });
}
