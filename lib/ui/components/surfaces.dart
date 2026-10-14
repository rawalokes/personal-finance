import 'package:flutter/material.dart';

import '../icons/paisa_icon.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'tone.dart';

/// Rounded surface (`.card`): radius 22, no border, no shadow.
class PaisaCard extends StatelessWidget {
  const PaisaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Defaults to surface; pass surface2 inside sheets.
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PaisaSize.radiusCard),
        side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// A card whose rows are separated by hairlines (`.card.lst`).
class PaisaListCard extends StatelessWidget {
  const PaisaListCard({super.key, required this.children, this.color});

  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final line = context.colors.line;
    return PaisaCard(
      padding: EdgeInsets.zero,
      color: color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Round icon well (`.ic`).
class IconWell extends StatelessWidget {
  const IconWell({super.key, required this.icon, this.tone = Tone.neutral, this.size = 42});

  final String icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (tone) {
      Tone.neutral => (c.surface2, c.ink),
      Tone.positive => (c.positiveBg, c.positive),
      Tone.red => (c.redBg, c.red),
      Tone.amber => (c.amberBg, c.amber),
      Tone.blue => (c.blueBg, c.blue),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: PaisaIcon(icon, size: 19, color: fg),
    );
  }
}

/// List row (`.row`): leading well, title/subtitle, trailing; min height 64.
class ListRow extends StatelessWidget {
  const ListRow({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: PaisaSize.rowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.h3.copyWith(color: c.ink)),
                if (subtitle != null)
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.sub.copyWith(color: c.ink3)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ]),
      ),
    );
    return onTap == null ? body : InkWell(onTap: onTap, child: body);
  }
}
