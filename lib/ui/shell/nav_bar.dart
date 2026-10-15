import 'package:flutter/material.dart';

import '../icons/paisa_icon.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'tabs.dart';

/// Bottom navigation (`.nav`): Home · Activity · Accounts · Plans · More.
class PaisaNavBar extends StatelessWidget {
  const PaisaNavBar({super.key, required this.currentIndex, required this.onSelect, this.badgeCount = 0});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Pending inbox messages, shown on Activity.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.line))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Row(children: [
            for (var i = 0; i < kTabs.length; i++)
              Expanded(
                child: _NavItem(
                  tab: kTabs[i],
                  selected: i == currentIndex,
                  badge: i == kActivityTab ? badgeCount : 0,
                  onTap: () => onSelect(i),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.selected, required this.badge, required this.onTap});

  final TabDef tab;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.primary : c.ink3;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${tab.label}, $badge to review' : tab.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: PaisaSize.navItemMinHeight),
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 56,
              height: 30,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                PaisaIcon(tab.icon, color: fg),
                if (badge > 0) Positioned(top: -2, left: 34, child: _Badge(count: badge)),
              ]),
            ),
            const SizedBox(height: 3),
            Text(tab.label, style: PaisaText.navLabel.copyWith(color: fg)),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.red,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.bg, width: 2),
      ),
      child: Text('$count', style: PaisaText.tag.copyWith(fontSize: 11, color: Colors.white)),
    );
  }
}
