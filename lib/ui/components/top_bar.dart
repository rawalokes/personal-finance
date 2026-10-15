import 'package:flutter/material.dart';

import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// Screen header (`.top`). Root screens: big title. Detail screens
/// ([onBack] given): Back button and a smaller title.
class PaisaTopBar extends StatelessWidget {
  const PaisaTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.backIcon = PaisaIcons.chevL,
    this.backLabel = 'Back',
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Forms use a close (×) "Cancel" button instead of Back.
  final String backIcon;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final root = onBack == null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: PaisaSize.topBarHeight),
      child: Padding(
        padding: root ? const EdgeInsets.fromLTRB(16, 10, 10, 8) : const EdgeInsets.fromLTRB(8, 10, 10, 8),
        child: Row(children: [
          if (!root) ...[
            PaisaIconButton(icon: backIcon, label: backLabel, onPressed: onBack),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (root ? PaisaText.h1 : PaisaText.h2).copyWith(color: context.colors.ink),
              ),
            ),
          ),
          ...actions,
        ]),
      ),
    );
  }
}
