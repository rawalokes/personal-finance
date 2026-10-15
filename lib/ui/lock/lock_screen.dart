import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_models.dart';
import '../../store/app_lock.dart';
import '../../store/data_providers.dart';
import '../components/surfaces.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../typography.dart';

/// Covers the app while locked, and locks it again after a minute in the
/// background (spec §10). Also applies "Block screenshots" (FLAG_SECURE).
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(lockControllerProvider.notifier).wentToBackground(),
      onShow: () {
        final s = ref.read(securityProvider).value ?? const SecuritySettings();
        ref.read(lockControllerProvider.notifier).cameBack(appLock: s.appLock, autoLock: s.autoLock);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(securityProvider, (prev, next) {
      final secure = next.value?.blockScreenshots ?? false;
      if (prev?.value?.blockScreenshots != secure) ref.read(screenSecurityProvider).setSecure(secure);
    }, onError: (_, _) {});
    final locked = ref.watch(lockControllerProvider);
    return Stack(children: [
      // Offstage: nothing behind the lock is painted or read aloud.
      Offstage(offstage: locked, child: widget.child),
      if (locked) const Positioned.fill(child: LockScreen()),
    ]);
  }
}

/// PIN keypad with fingerprint unlock.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final s = ref.read(securityProvider).value ?? await ref.read(settingsRepoProvider).security();
    final ok = s.biometric && await ref.read(biometricAuthProvider).available();
    if (!mounted) return;
    setState(() => _bioAvailable = ok);
    if (ok) _biometric();
  }

  Future<void> _biometric() async {
    final ok = await ref.read(biometricAuthProvider).authenticate('Unlock Paisa');
    if (ok && mounted) ref.read(lockControllerProvider.notifier).unlock();
  }

  Future<void> _digit(String d) async {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) {
      final ok = await ref.read(pinServiceProvider).verify(_pin);
      if (!mounted) return;
      if (ok) {
        ref.read(lockControllerProvider.notifier).unlock();
      } else {
        setState(() {
          _pin = '';
          _error = 'Wrong PIN — try again';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.bg,
      child: SafeArea(
        child: Column(children: [
          const Spacer(),
          const IconWell(icon: PaisaIcons.lock, size: 64),
          const SizedBox(height: 16),
          Text('Enter your PIN', style: PaisaText.h2.copyWith(color: c.ink)),
          const SizedBox(height: 16),
          Semantics(
            label: '${_pin.length} of 4 digits entered',
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? c.primary : Colors.transparent,
                    border: Border.all(color: i < _pin.length ? c.primary : c.ink3, width: 1.5),
                  ),
                ),
            ]),
          ),
          SizedBox(
            height: 32,
            child: _error == null
                ? null
                : Center(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(_error!, style: PaisaText.sub.copyWith(color: c.red)),
                    ),
                  ),
          ),
          const Spacer(),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) _key(d)]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _bioAvailable
                ? _icon(PaisaIcons.key, 'Unlock with fingerprint', _biometric)
                : const SizedBox(width: 88, height: 72),
            _key('0'),
            _icon(PaisaIcons.chevL, 'Delete digit', () {
              if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
            }),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _key(String d) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Digit $d',
      excludeSemantics: true,
      child: SizedBox(
        width: 88,
        height: 72,
        child: InkResponse(
          onTap: () => _digit(d),
          radius: 36,
          child: Center(child: Text(d, style: PaisaText.h1.copyWith(color: c.ink))),
        ),
      ),
    );
  }

  Widget _icon(String icon, String label, VoidCallback onTap) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 88,
        height: 72,
        child: InkResponse(onTap: onTap, radius: 36, child: Center(child: PaisaIcon(icon, color: c.ink2, size: 26))),
      ),
    );
  }
}
