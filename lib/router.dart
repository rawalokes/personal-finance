import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/screens/accounts/account_detail_screen.dart';
import 'ui/screens/accounts/accounts_screen.dart';
import 'ui/screens/activity/activity_screen.dart';
import 'ui/screens/entry/add_expense_screen.dart';
import 'ui/screens/entry/add_income_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/shell/app_shell.dart';
import 'ui/shell/placeholder_screen.dart';
import 'ui/shell/tabs.dart';

/// Where the app opens. Tests override it to start on a given screen.
final initialLocationProvider = Provider<String>((ref) => kTabs.first.path);

/// The screen at the root of each tab. Plans and More are built in later plans.
Widget _rootScreen(TabDef tab) => switch (tab.path) {
      '/home' => const HomeScreen(),
      '/activity' => const ActivityScreen(),
      '/accounts' => const AccountsScreen(),
      _ => PlaceholderScreen(title: tab.screenTitle),
    };

/// Root tabs live in the shell (bottom nav visible). Detail screens go in the
/// top-level `routes` list, outside the shell, so the nav hides on them.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          for (final tab in kTabs)
            StatefulShellBranch(routes: [
              GoRoute(path: tab.path, builder: (context, state) => _rootScreen(tab)),
            ]),
        ],
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) => AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/income/new',
        builder: (context, state) => AddIncomeScreen(accountId: state.uri.queryParameters['account']),
      ),
      GoRoute(
        path: '/expense/new',
        builder: (context, state) => AddExpenseScreen(accountId: state.uri.queryParameters['account']),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
