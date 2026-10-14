import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

enum ConfirmChoice { ok, alt }

/// Confirm dialog for destructive or ambiguous actions (`.dlg`).
/// Returns [ConfirmChoice.ok], [ConfirmChoice.alt] (only if [altLabel] is
/// given), or null for Cancel / tapping outside.
Future<ConfirmChoice?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String okLabel,
  ButtonVariant okVariant = ButtonVariant.primary,
  String? altLabel,
}) {
  final c = context.colors;
  return showDialog<ConfirmChoice>(
    context: context,
    barrierColor: c.scrim,
    builder: (ctx) => Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PaisaSize.radiusDialog)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: PaisaText.h2.copyWith(color: c.ink))),
            const SizedBox(height: 12),
            Text(body, style: PaisaText.sub.copyWith(color: c.ink3)),
            const SizedBox(height: 16),
            PaisaButton(label: okLabel, variant: okVariant, onPressed: () => Navigator.pop(ctx, ConfirmChoice.ok)),
            if (altLabel != null) ...[
              const SizedBox(height: 8),
              PaisaButton(
                label: altLabel,
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.pop(ctx, ConfirmChoice.alt),
              ),
            ],
            const SizedBox(height: 8),
            PaisaButton(label: 'Cancel', variant: ButtonVariant.ghost, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}
