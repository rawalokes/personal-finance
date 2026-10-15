import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/top_bar.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';

/// Leaves a pushed page: back to where it was opened from, or Home when it
/// was opened directly (a deep link or a test) and there is nothing to pop.
void leavePage(BuildContext context) => context.canPop() ? context.pop() : context.go('/home');

/// A screen pushed above the tabs (no bottom nav): top bar with Back (or ×
/// Cancel for forms), a body, and an optional pinned footer (`Save …`).
class DetailPage extends StatelessWidget {
  const DetailPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.footer,
    this.isForm = false,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? footer;

  /// Forms show × "Cancel" instead of "Back".
  final bool isForm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PaisaTopBar(
            title: title,
            onBack: () => leavePage(context),
            actions: actions,
            backIcon: isForm ? PaisaIcons.close : PaisaIcons.chevL,
            backLabel: isForm ? 'Cancel' : 'Back',
          ),
          Expanded(child: body),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 14), child: footer),
            ),
        ]),
      ),
    );
  }
}
