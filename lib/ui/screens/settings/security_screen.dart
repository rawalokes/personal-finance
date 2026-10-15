import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings_models.dart';
import '../../../store/app_lock.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

/// Settings → Security & privacy (spec §10).
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return DetailPage(
      title: 'Security & privacy',
      body: AsyncView(
        value: ref.watch(securityProvider),
        data: (s) {
          Future<void> save(SecuritySettings next) => ref.read(settingsRepoProvider).saveSecurity(next);
          Widget row(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: child);
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            PaisaListCard(children: [
              row(ToggleRow(
                title: 'App lock',
                subtitle: 'PIN or fingerprint when opening Paisa',
                value: s.appLock,
                onChanged: (on) => on ? showSetPinSheet(context, s) : showTurnOffLockSheet(context, s),
              )),
              if (s.appLock) ...[
                row(ToggleRow(
                  title: 'Unlock with fingerprint',
                  subtitle: 'Or face unlock, where your phone supports it',
                  value: s.biometric,
                  onChanged: (on) => save(s.copyWith(biometric: on)),
                )),
                row(ToggleRow(
                  title: 'Auto-lock after 1 minute',
                  subtitle: 'When Paisa has been in the background',
                  value: s.autoLock,
                  onChanged: (on) => save(s.copyWith(autoLock: on)),
                )),
                ListRow(title: 'Change PIN', subtitle: '4 digits', onTap: () => showSetPinSheet(context, s, change: true)),
              ],
              row(ToggleRow(
                title: 'Block screenshots',
                subtitle: 'Also hides Paisa in the recent-apps view',
                value: s.blockScreenshots,
                onChanged: (on) => save(s.copyWith(blockScreenshots: on)),
              )),
              row(ToggleRow(
                title: 'Hide balances',
                subtitle: 'Mask every amount until you tap the eye on Home',
                value: ref.watch(hideBalancesProvider),
                onChanged: (on) => ref.read(hideBalancesProvider.notifier).set(on),
              )),
            ]),
            const SizedBox(height: 14),
            Text(
              'Your data is stored only on this phone. Your PIN is kept as a salted hash and your AI key in the '
              'phone’s secure storage; neither is ever exported.',
              style: PaisaText.hint.copyWith(color: c.ink3),
            ),
          ]);
        },
      ),
    );
  }
}

class _PinForm extends ChangeNotifier {
  final pin = TextEditingController();
  final repeat = TextEditingController();
  String? error;
  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    pin.dispose();
    repeat.dispose();
    super.dispose();
  }
}

/// Set (or change) the PIN; turning the lock on saves it with the setting.
Future<void> showSetPinSheet(BuildContext context, SecuritySettings s, {bool change = false}) =>
    showPaisaFormSheet<void, _PinForm>(
      context,
      title: change ? 'Change PIN' : 'Turn on app lock',
      create: _PinForm.new,
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PaisaTextField(label: 'New PIN (4 digits)', controller: f.pin, obscure: true, keyboardType: TextInputType.number, autofocus: true),
        const SizedBox(height: 14),
        PaisaTextField(label: 'Repeat the PIN', controller: f.repeat, obscure: true, keyboardType: TextInputType.number, errorText: f.error),
        const SizedBox(height: 14),
        const Note('If you forget your PIN, you will need to clear Paisa’s app data to get back in.', tone: Tone.amber),
      ]),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => SizedBox(
          width: double.infinity,
          child: PaisaButton(
            label: change ? 'Save PIN' : 'Turn on app lock',
            onPressed: () async {
              final pin = f.pin.text.trim();
              if (!isValidPin(pin)) {
                f.setError('Use exactly 4 digits');
                return;
              }
              if (pin != f.repeat.text.trim()) {
                f.setError('The PINs don’t match');
                return;
              }
              await ref.read(pinServiceProvider).setPin(pin);
              await ref.read(settingsRepoProvider).saveSecurity(s.copyWith(appLock: true));
              if (ctx.mounted) Navigator.of(ctx).pop();
              ref.read(toastProvider.notifier).show(change ? 'PIN changed' : 'App lock is on');
            },
          ),
        ),
      ),
    );

/// Turning the lock off needs the current PIN, so a borrowed phone can't.
Future<void> showTurnOffLockSheet(BuildContext context, SecuritySettings s) => showPaisaFormSheet<void, _PinForm>(
      context,
      title: 'Turn off app lock',
      create: _PinForm.new,
      body: (ctx, f) => PaisaTextField(
        label: 'Current PIN',
        controller: f.pin,
        obscure: true,
        keyboardType: TextInputType.number,
        autofocus: true,
        errorText: f.error,
      ),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => SizedBox(
          width: double.infinity,
          child: PaisaButton(
            label: 'Turn off',
            variant: ButtonVariant.danger,
            onPressed: () async {
              if (!await ref.read(pinServiceProvider).verify(f.pin.text.trim())) {
                f.setError('Wrong PIN');
                return;
              }
              await ref.read(pinServiceProvider).clear();
              await ref.read(settingsRepoProvider).saveSecurity(s.copyWith(appLock: false));
              if (ctx.mounted) Navigator.of(ctx).pop();
              ref.read(toastProvider.notifier).show('App lock is off');
            },
          ),
        ),
      ),
    );
