import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../data/secret_store.dart';

/// Secrets live in the device keystore; tests override with a memory store.
final secretStoreProvider = Provider<SecretStore>((ref) => DeviceSecretStore());

bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

/// The app-lock PIN, kept only as a salted SHA-256 hash in secure storage.
class PinService {
  PinService(this._store, {Random? random}) : _random = random ?? Random.secure();

  static const hashKey = 'pin_hash';
  static const saltKey = 'pin_salt';

  final SecretStore _store;
  final Random _random;

  static String _hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<bool> hasPin() async => (await _store.read(hashKey)) != null;

  Future<void> setPin(String pin) async {
    final salt = base64Url.encode(List<int>.generate(16, (_) => _random.nextInt(256)));
    await _store.write(saltKey, salt);
    await _store.write(hashKey, _hash(pin, salt));
  }

  Future<bool> verify(String pin) async {
    final salt = await _store.read(saltKey);
    final hash = await _store.read(hashKey);
    return salt != null && hash != null && _hash(pin, salt) == hash;
  }

  Future<void> clear() async {
    await _store.delete(hashKey);
    await _store.delete(saltKey);
  }
}

final pinServiceProvider = Provider<PinService>((ref) => PinService(ref.watch(secretStoreProvider)));

/// Fingerprint / face unlock. Tests override with a fake.
abstract class BiometricAuth {
  Future<bool> available();
  Future<bool> authenticate(String reason);
}

class DeviceBiometricAuth implements BiometricAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on Object {
      // Cancelled, locked out, or no hardware: fall back to the PIN.
      return false;
    }
  }
}

final biometricAuthProvider = Provider<BiometricAuth>((ref) => DeviceBiometricAuth());

/// Android FLAG_SECURE through the 'paisa/screen_security' channel
/// (MainActivity.kt). A no-op where the channel does not exist.
class ScreenSecurity {
  static const _channel = MethodChannel('paisa/screen_security');

  Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on MissingPluginException {
      // Desktop and tests: nothing to do.
    }
  }
}

final screenSecurityProvider = Provider<ScreenSecurity>((ref) => ScreenSecurity());

/// Whether the app starts locked (main.dart: app lock on and a PIN set).
final initialLockedProvider = Provider<bool>((ref) => false);

/// "Now" for auto-lock timing; tests move it.
final lockNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Locks again after this long in the background (spec §10).
const Duration kAutoLockAfter = Duration(minutes: 1);

/// true = the lock screen covers the app.
class LockController extends Notifier<bool> {
  DateTime? _leftAt;

  @override
  bool build() => ref.read(initialLockedProvider);

  void lock() => state = true;
  void unlock() => state = false;

  void wentToBackground() => _leftAt = ref.read(lockNowProvider)();

  /// Locks when the app lock and auto-lock are on and the app was away for
  /// at least [kAutoLockAfter].
  void cameBack({required bool appLock, required bool autoLock}) {
    final left = _leftAt;
    _leftAt = null;
    if (!appLock || !autoLock || left == null) return;
    if (ref.read(lockNowProvider)().difference(left) >= kAutoLockAfter) state = true;
  }
}

final lockControllerProvider = NotifierProvider<LockController, bool>(LockController.new);
