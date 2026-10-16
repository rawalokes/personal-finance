import 'package:flutter/material.dart';

import '../icons/paisa_icon.dart';
import '../theme.dart';
import '../typography.dart';
import 'tone.dart';

/// Small pill label (`.tag`), e.g. confidence or status.
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.tone = Tone.neutral});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (tone) {
      Tone.neutral => (c.surface2, c.ink2),
      Tone.positive => (c.positiveBg, c.positiveInk),
      Tone.red => (c.redBg, c.red),
      Tone.amber => (c.amberBg, c.amber),
      Tone.blue => (c.blueBg, c.blue),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.tag.copyWith(color: fg)),
    );
  }
}

/// Callout (`.note`). [lead] is shown bold before [text].
class Note extends StatelessWidget {
  const Note(this.text, {super.key, this.lead, this.tone = Tone.blue, this.icon});

  final String text;
  final String? lead;
  final Tone tone;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (tone) {
      Tone.amber => (c.amberBg, c.amber),
      Tone.positive => (c.positiveBg, c.positiveInk),
      Tone.blue => (c.surface, c.ink2), // Night direction: `.note.b` is a quiet surface
      Tone.red => (c.redBg, c.red),
      Tone.neutral => (c.surface2, c.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[PaisaIcon(icon!, size: 19, color: fg), const SizedBox(width: 10)],
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              if (lead != null)
                TextSpan(
                  text: '$lead ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontVariations: [FontVariation('wght', 600)]),
                ),
              TextSpan(text: text),
            ]),
            style: PaisaText.sub.copyWith(color: fg, height: 1.45),
          ),
        ),
      ]),
    );
  }
}

/// Thin rounded progress bar (`.bar`). Values are clamped to 0–1.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 6, this.semanticLabel});

  final double value;
  final Color? color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: semanticLabel,
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ColoredBox(
            color: c.line,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color ?? c.primary, borderRadius: BorderRadius.circular(99)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
