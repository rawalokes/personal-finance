import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';

/// Undo stays available this long after each action (spec §6).
const Duration kUndoWindow = Duration(seconds: 5);

class ToastMessage {
  const ToastMessage(this.text, {this.onUndo});
  final String text;
  final VoidCallback? onUndo;
}

class ToastController extends Notifier<ToastMessage?> {
  Timer? _timer;

  @override
  ToastMessage? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(String text, {VoidCallback? onUndo, Duration duration = kUndoWindow}) {
    _timer?.cancel();
    state = ToastMessage(text, onUndo: onUndo);
    _timer = Timer(duration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  /// Runs the undo callback once and hides the toast.
  void undo() {
    final callback = state?.onUndo;
    dismiss();
    callback?.call();
  }
}

final toastProvider = NotifierProvider<ToastController, ToastMessage?>(ToastController.new);

/// Put once around the app (MaterialApp.builder). Shows the current toast
/// above the bottom navigation.
class PaisaToastHost extends ConsumerWidget {
  const PaisaToastHost({super.key, required this.child, this.bottom = 86});

  final Widget child;
  final double bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msg = ref.watch(toastProvider);
    final c = context.colors;
    final controller = ref.read(toastProvider.notifier);
    return Stack(children: [
      child,
      if (msg != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: bottom + MediaQuery.paddingOf(context).bottom,
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: c.ink,
              borderRadius: BorderRadius.circular(PaisaSize.radiusToast),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                  child: Row(children: [
                    PaisaIcon(PaisaIcons.check, size: 19, color: c.bg),
                    const SizedBox(width: 10),
                    Expanded(child: Text(msg.text, style: PaisaText.buttonSmall.copyWith(color: c.bg))),
                    if (msg.onUndo != null) _ToastAction(label: 'Undo', color: c.toastAction, onTap: controller.undo),
                    _ToastAction(icon: PaisaIcons.close, label: 'Dismiss', color: c.bg, onTap: controller.dismiss),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _ToastAction extends StatelessWidget {
  const _ToastAction({required this.label, required this.color, required this.onTap, this.icon});

  final String label;
  final String? icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: icon == null ? null : label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: PaisaSize.touchMin,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: icon == null
                  ? Text(label, style: PaisaText.buttonSmall.copyWith(color: color))
                  : PaisaIcon(icon!, size: 19, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
