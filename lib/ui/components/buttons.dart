import 'package:flutter/material.dart';

import '../icons/paisa_icon.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }

/// Pill button (`.btn`). primary = mint, secondary = surface2, outline,
/// ghost (text only) and danger (red on redBg).
class PaisaButton extends StatelessWidget {
  const PaisaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final String? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (variant) {
      ButtonVariant.primary => (c.primary, c.onPrimary),
      ButtonVariant.secondary => (c.surface2, c.ink),
      ButtonVariant.outline => (Colors.transparent, c.ink),
      ButtonVariant.ghost => (Colors.transparent, c.ink2),
      ButtonVariant.danger => (c.redBg, c.red),
    };
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: variant == ButtonVariant.outline ? BorderSide(color: c.line) : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: small ? PaisaSize.buttonSmallHeight : PaisaSize.buttonHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: small ? 14 : 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[PaisaIcon(icon!, size: 19, color: fg), const SizedBox(width: 8)],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (small ? PaisaText.buttonSmall : PaisaText.button).copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 44×44 icon button (`.ib`); `boxed` adds the round surface (`.ib.bx`).
class PaisaIconButton extends StatelessWidget {
  const PaisaIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.boxed = false,
    this.showDot = false,
    this.iconSize = 22,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool boxed;

  /// Red unread dot (`.dot`), e.g. on the alerts bell.
  final bool showDot;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: boxed ? c.surface : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: PaisaSize.touchMin,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PaisaIcon(icon, size: iconSize, color: c.ink),
                if (showDot)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: c.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mint text action (`.link`), e.g. "See all".
class PaisaLink extends StatelessWidget {
  const PaisaLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: PaisaSize.touchMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(label, style: PaisaText.buttonSmall.copyWith(color: context.colors.primary))),
            ]),
          ),
        ),
      ),
    );
  }
}
