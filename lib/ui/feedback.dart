import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/undo.dart';
import '../finance/money.dart';
import '../store/ui_state.dart';
import 'components/toast.dart';

/// Shows [text] with an Undo action for 5 seconds. Undo runs [undo] once,
/// then confirms with "Change undone" (or says it could not undo).
void showUndoToast(ToastController toast, String text, UndoAction undo) {
  toast.show(text, onUndo: () async {
    try {
      await undo();
      toast.show('Change undone');
    } catch (_) {
      toast.show('Couldn’t undo that change');
    }
  });
}

/// Amounts in toasts confirm what was just typed, so they are not masked
/// (as in the mockup), but they follow the grouping preference.
String toastNpr(WidgetRef ref, Paisa p) => MoneyFormat(grouping: ref.read(groupingProvider)).npr(p);
