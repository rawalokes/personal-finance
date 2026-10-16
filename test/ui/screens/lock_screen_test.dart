import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/store/app_lock.dart';

import '../app_harness.dart';

class FakeBiometric implements BiometricAuth {
  FakeBiometric({this.ok = true});
  final bool ok;
  int prompts = 0;
  @override
  Future<bool> available() async => true;
  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return ok;
  }
}

Future<MemorySecretStore> storeWithPin(String pin) async {
  final store = MemorySecretStore();
  await PinService(store).setPin(pin);
  return store;
}

Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.bySemanticsLabel('Digit $d'));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a locked app shows only the lock screen; the right PIN opens it', (tester) async {
    final store = await storeWithPin('4821');
    await pumpPaisa(tester, overrides: [
      initialLockedProvider.overrideWithValue(true),
      secretStoreProvider.overrideWithValue(store),
      biometricAuthProvider.overrideWithValue(FakeBiometric(ok: false)),
    ]);
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('FREE TO SPEND'), findsNothing, reason: 'nothing behind the lock is visible');
    await typePin(tester, '4821');
    expect(find.text('Enter your PIN'), findsNothing);
    expect(find.text('FREE TO SPEND'), findsOneWidget);
  });

  testWidgets('a wrong PIN is refused and cleared', (tester) async {
    final store = await storeWithPin('4821');
    await pumpPaisa(tester, overrides: [
      initialLockedProvider.overrideWithValue(true),
      secretStoreProvider.overrideWithValue(store),
      biometricAuthProvider.overrideWithValue(FakeBiometric(ok: false)),
    ]);
    await typePin(tester, '1111');
    expect(find.text('Wrong PIN — try again'), findsOneWidget);
    expect(find.text('Enter your PIN'), findsOneWidget);
  });

  testWidgets('the fingerprint prompt opens by itself and unlocks when it succeeds', (tester) async {
    final store = await storeWithPin('4821');
    final bio = FakeBiometric();
    await pumpPaisa(tester, overrides: [
      initialLockedProvider.overrideWithValue(true),
      secretStoreProvider.overrideWithValue(store),
      biometricAuthProvider.overrideWithValue(bio),
    ]);
    expect(bio.prompts, 1);
    expect(find.text('FREE TO SPEND'), findsOneWidget);
  });

  testWidgets('a failed fingerprint leaves the PIN pad and a button to try again', (tester) async {
    final store = await storeWithPin('4821');
    final bio = FakeBiometric(ok: false);
    await pumpPaisa(tester, overrides: [
      initialLockedProvider.overrideWithValue(true),
      secretStoreProvider.overrideWithValue(store),
      biometricAuthProvider.overrideWithValue(bio),
    ]);
    expect(find.text('Enter your PIN'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    await tester.pumpAndSettle();
    expect(bio.prompts, 2);
    expect(find.text('Enter your PIN'), findsOneWidget);
  });
}
