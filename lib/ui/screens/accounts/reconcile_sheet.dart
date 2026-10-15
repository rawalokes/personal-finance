import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/sheet.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../feedback.dart';
import '../../theme.dart';
import '../../typography.dart';

class _ReconcileForm extends ChangeNotifier {
  _ReconcileForm() {
    actual.addListener(notifyListeners);
  }

  final actual = TextEditingController();
  String? error;
  bool saving = false;

  Paisa? get value => parseNpr(actual.text);

  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  void setSaving(bool v) {
    saving = v;
    notifyListeners();
  }

  @override
  void dispose() {
    actual.dispose();
    super.dispose();
  }
}

/// '+NPR 500' / '−NPR 420'.
String _signed(WidgetRef ref, Paisa diff) => '${diff > 0 ? '+' : diff < 0 ? kMinus : ''}${toastNpr(ref, diff.abs())}';

/// Compare Paisa's balance with the bank's; a difference becomes an
/// adjustment entry (never income or expense).
Future<void> showReconcileSheet(BuildContext context, Account account) {
  final owed = account.group == AccountGroup.liability;
  return showPaisaFormSheet<void, _ReconcileForm>(
    context,
    title: 'Reconcile ${account.shortName}',
    create: _ReconcileForm.new,
    body: (ctx, form) => Consumer(builder: (ctx, ref, _) {
      final c = ctx.colors;
      final v = form.value;
      final diff = v == null ? null : v - account.balance;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'Paisa shows ${toastNpr(ref, account.balance)}. Enter the ${owed ? 'amount owed' : 'balance'} '
          'from your bank app or statement.',
          style: PaisaText.sub.copyWith(color: c.ink3),
        ),
        const SizedBox(height: 14),
        PaisaTextField(
          label: owed ? 'Actual amount owed (NPR)' : 'Actual balance (NPR)',
          controller: form.actual,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: form.error,
          autofocus: true,
        ),
        if (diff != null) ...[
          const SizedBox(height: 14),
          diff == 0
              ? const Note('Balances match — nothing to adjust.', tone: Tone.positive)
              : Note(
                  'Difference ${_signed(ref, diff)}. An adjustment entry will be added — not counted as income or expense.',
                  tone: Tone.amber,
                ),
        ],
      ]);
    }),
    footer: (ctx, form) => Consumer(
      builder: (ctx, ref, _) => Row(children: [
        Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: PaisaButton(label: 'Reconcile', onPressed: form.saving ? null : () => _save(ctx, ref, form, account)),
        ),
      ]),
    ),
  );
}

Future<void> _save(BuildContext context, WidgetRef ref, _ReconcileForm form, Account account) async {
  final actual = form.value;
  if (actual == null) {
    form.setError('Enter the actual ${account.group == AccountGroup.liability ? 'amount owed' : 'balance'}');
    return;
  }
  form.setSaving(true);
  final toast = ref.read(toastProvider.notifier);
  try {
    final result = await ref.read(accountRepoProvider).reconcile(account.id, actual);
    if (context.mounted) Navigator.of(context).pop();
    final undo = result.undo;
    if (undo == null) {
      toast.show('${account.shortName} reconciled — balances match');
    } else {
      showUndoToast(toast, '${account.shortName} reconciled · adjustment ${_signed(ref, result.difference)}', undo);
    }
  } catch (_) {
    form.setSaving(false);
    toast.show('Couldn’t reconcile — nothing was changed');
  }
}
