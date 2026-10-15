import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/store/app_lock.dart';

void main() {
  group('PIN', () {
    test('only a salted hash is stored; the right PIN verifies, a wrong one does not', () async {
      final store = MemorySecretStore();
      final pins = PinService(store);
      expect(await pins.hasPin(), isFalse);
      await pins.setPin('4821');
      expect(await pins.hasPin(), isTrue);
      expect(store.values.values.any((v) => v.contains('4821')), isFalse, reason: 'never stored in plain text');
      expect(await pins.verify('4821'), isTrue);
      expect(await pins.verify('1111'), isFalse);
      await pins.clear();
      expect(await pins.hasPin(), isFalse);
    });

    test('two installs with the same PIN get different hashes (random salt)', () async {
      final a = MemorySecretStore();
      final b = MemorySecretStore();
      await PinService(a).setPin('0000');
      await PinService(b).setPin('0000');
      expect(a.values[PinService.hashKey], isNot(b.values[PinService.hashKey]));
    });

    test('a PIN must be exactly 4 digits', () {
      expect(isValidPin('4821'), isTrue);
      expect(isValidPin('482'), isFalse);
      expect(isValidPin('48a1'), isFalse);
    });
  });

  group('lock controller', () {
    late DateTime now;
    late ProviderContainer c;

    setUp(() {
      now = DateTime(2026, 10, 14, 10);
      c = ProviderContainer.test(overrides: [lockNowProvider.overrideWithValue(() => now)]);
    });

    test('starts unlocked unless the app lock is on', () {
      expect(c.read(lockControllerProvider), isFalse);
      c.read(lockControllerProvider.notifier).lock();
      expect(c.read(lockControllerProvider), isTrue);
      c.read(lockControllerProvider.notifier).unlock();
      expect(c.read(lockControllerProvider), isFalse);
    });

    test('auto-lock: locks after a minute in the background, not before', () {
      final lock = c.read(lockControllerProvider.notifier);
      lock.wentToBackground();
      now = now.add(const Duration(seconds: 59));
      lock.cameBack(appLock: true, autoLock: true);
      expect(c.read(lockControllerProvider), isFalse);

      lock.wentToBackground();
      now = now.add(const Duration(seconds: 60));
      lock.cameBack(appLock: true, autoLock: true);
      expect(c.read(lockControllerProvider), isTrue);
    });

    test('auto-lock off, or app lock off, never locks on return', () {
      final lock = c.read(lockControllerProvider.notifier);
      lock.wentToBackground();
      now = now.add(const Duration(minutes: 5));
      lock.cameBack(appLock: true, autoLock: false);
      expect(c.read(lockControllerProvider), isFalse);
      lock.wentToBackground();
      now = now.add(const Duration(minutes: 5));
      lock.cameBack(appLock: false, autoLock: true);
      expect(c.read(lockControllerProvider), isFalse);
    });
  });
}
