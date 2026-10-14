import 'package:flutter/material.dart';

import '../icons/paisa_icon.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';

/// Filter / choice chip (`.chip`): 40 px pill inside a 44 px tap target.
class PaisaChip extends StatelessWidget {
  const PaisaChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.bg : c.ink2;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: PaisaSize.touchMin,
          child: Center(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: ShapeDecoration(
                color: selected ? c.ink : Colors.transparent,
                shape: StadiumBorder(side: BorderSide(color: selected ? c.ink : c.line)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[PaisaIcon(icon!, size: 16, color: fg), const SizedBox(width: 6)],
                Text(label, style: PaisaText.chip.copyWith(color: fg)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill segmented control (`.seg`). Each segment's tap area is 48 px tall.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.onCard = false,
    this.badges = const {},
  });

  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Inside a card the track uses surface2 instead of surface.
  final bool onCard;

  /// Optional trailing widget per segment, e.g. a pending-count tag.
  final Map<T, Widget> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: onCard ? c.surface2 : c.surface, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(children: [
          for (final (value, label) in segments)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: value == selected ? c.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PaisaText.segment.copyWith(color: value == selected ? c.bg : c.ink2),
                          ),
                        ),
                        if (badges[value] != null) ...[const SizedBox(width: 6), badges[value]!],
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// On/off switch (`.tgl`): 52×32 track inside a 44 px tap target.
class PaisaToggle extends StatelessWidget {
  const PaisaToggle({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const duration = Duration(milliseconds: 150);
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 52,
          height: PaisaSize.touchMin,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: value ? c.primary : c.line, borderRadius: BorderRadius.circular(99)),
              child: AnimatedAlign(
                duration: duration,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
