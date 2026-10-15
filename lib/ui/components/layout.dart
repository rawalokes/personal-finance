import 'package:flutter/material.dart';

import '../theme.dart';
import '../typography.dart';
import 'inputs.dart';
import 'surfaces.dart';

/// Section heading row (`.sect`): an 18/600 title, or an upper-case caption
/// when [caps] is true, with an optional trailing widget (link, total).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.caps = false,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 10),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool caps;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final heading = caps
        ? Text(title.toUpperCase(), style: PaisaText.cap.copyWith(color: c.ink3))
        : Text(title, style: PaisaText.h2.copyWith(color: c.ink));
    return Padding(
      padding: padding,
      child: Row(children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              heading,
              if (subtitle != null) Text(subtitle!, style: PaisaText.sub.copyWith(color: c.ink3)),
            ]),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}

/// Horizontally scrolling chip row (`.chips`) with 16 px side padding.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
      ]),
    );
  }
}

/// One label/value line (`.kv`). Pass [valueWidget] for styled values.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, {super.key, this.value, this.valueWidget})
      : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Row(children: [
        Expanded(child: Text(label, style: PaisaText.body.copyWith(fontSize: 14, color: c.ink2))),
        const SizedBox(width: 12),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget ??
                Text(
                  value!,
                  textAlign: TextAlign.right,
                  style: PaisaText.body.copyWith(
                    fontSize: 14,
                    color: c.ink,
                    fontVariations: const [FontVariation('wght', 650)],
                  ),
                ),
          ),
        ),
      ]),
    );
  }
}

/// A card of [KeyValueRow]s separated by hairlines.
class KeyValueCard extends StatelessWidget {
  const KeyValueCard({super.key, required this.rows, this.color});

  final List<Widget> rows;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final line = context.colors.line;
    return PaisaCard(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: line),
          rows[i],
        ],
      ]),
    );
  }
}

/// A form label above any input (chips, segments): the `.fld > span` style.
class FieldGroup extends StatelessWidget {
  const FieldGroup({super.key, required this.label, required this.child, this.footer});

  final String label;
  final Widget child;

  /// Optional line under the input, e.g. a budget hint.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Semantics(header: true, child: Text(label, style: PaisaText.label.copyWith(color: context.colors.ink2))),
      const SizedBox(height: 6),
      child,
      if (footer != null) ...[const SizedBox(height: 6), footer!],
    ]);
  }
}

/// Wrapping chip group (`.chipw`).
class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 0, children: children);
}

/// Title + hint on the left, a [PaisaToggle] on the right.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(children: [
      if (leading != null) ...[leading!, const SizedBox(width: 12)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // The toggle announces the title; don't read it twice.
          ExcludeSemantics(child: Text(title, style: PaisaText.h3.copyWith(fontSize: 14, color: c.ink))),
          if (subtitle != null) Text(subtitle!, style: PaisaText.hint.copyWith(color: c.ink3)),
        ]),
      ),
      const SizedBox(width: 12),
      PaisaToggle(value: value, onChanged: onChanged, label: title),
    ]);
  }
}
