import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/shell/app_shell.dart';
import 'ui/shell/placeholder_screen.dart';
import 'ui/shell/tabs.dart';

/// Root tabs live in the shell (bottom nav visible). Detail screens added by
/// later plans go in the top-level `routes` list, outside the shell, so the
/// nav hides on them.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: kTabs.first.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          for (final tab in kTabs)
            StatefulShellBranch(routes: [
              GoRoute(path: tab.path, builder: (context, state) => PlaceholderScreen(title: tab.screenTitle)),
            ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
