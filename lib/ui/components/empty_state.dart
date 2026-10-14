import 'package:flutter/material.dart';

import '../theme.dart';
import '../typography.dart';
import 'buttons.dart';
import 'surfaces.dart';
import 'tone.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.tone = Tone.neutral,
  });

  final String icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IconWell(icon: icon, tone: tone, size: 56),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: PaisaText.h2.copyWith(color: c.ink)),
        const SizedBox(height: 10),
        Text(body, textAlign: TextAlign.center, style: PaisaText.sub.copyWith(color: c.ink3)),
        if (actionLabel != null) ...[
          const SizedBox(height: 10),
          PaisaButton(label: actionLabel!, onPressed: onAction, variant: ButtonVariant.secondary, small: true),
        ],
      ]),
    );
  }
}
