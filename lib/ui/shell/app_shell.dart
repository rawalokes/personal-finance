import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../store/ui_state.dart';
import 'nav_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(bottom: false, child: shell),
      bottomNavigationBar: PaisaNavBar(
        currentIndex: shell.currentIndex,
        badgeCount: ref.watch(inboxPendingCountProvider),
        onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
