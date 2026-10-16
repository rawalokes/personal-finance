import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'finance/money.dart';

import 'ui/ai/ai_chat_screen.dart';
import 'ui/ai/ai_insights_screen.dart';
import 'ui/reports/reports_screen.dart';
import 'ui/screens/accounts/account_detail_screen.dart';
import 'ui/screens/accounts/accounts_screen.dart';
import 'ui/screens/activity/activity_screen.dart';
import 'ui/screens/entry/add_expense_screen.dart';
import 'ui/screens/entry/add_income_screen.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/screens/inbox/review_screen.dart';
import 'ui/screens/loans/loan_detail_screen.dart';
import 'ui/screens/loans/loan_form_screen.dart';
import 'ui/screens/loans/loan_types_screen.dart';
import 'ui/screens/loans/payoff_planner_screen.dart';
import 'ui/screens/plans/plans_screen.dart';
import 'ui/screens/settings/ai_settings_screen.dart';
import 'ui/screens/settings/catalog_screens.dart';
import 'ui/screens/settings/more_screen.dart';
import 'ui/screens/settings/nudge_settings_screen.dart';
import 'ui/screens/settings/salary_screen.dart';
import 'ui/screens/settings/security_screen.dart';
import 'ui/screens/settings/simple_settings_screens.dart';
import 'ui/screens/settings/tax_rules_screen.dart';
import 'ui/screens/search/search_screen.dart';
import 'ui/shell/app_shell.dart';
import 'ui/shell/placeholder_screen.dart';
import 'ui/shell/tabs.dart';

/// Where the app opens. Tests override it to start on a given screen.
final initialLocationProvider = Provider<String>((ref) => kTabs.first.path);

/// The screen at the root of each tab.
Widget _rootScreen(TabDef tab, GoRouterState state) => switch (tab.path) {
      '/home' => const HomeScreen(),
      '/activity' => ActivityScreen(initial: state.uri.queryParameters['seg']),
      '/reports' => const ReportsScreen(),
      '/plans' => PlansScreen(initial: state.uri.queryParameters['seg']),
      '/more' => const MoreScreen(),
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
              GoRoute(path: tab.path, builder: (context, state) => _rootScreen(tab, state)),
            ]),
        ],
      ),
      GoRoute(path: '/accounts', builder: (context, state) => const AccountsScreen()),
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) => AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/search', builder: (context, state) => SearchScreen(initialQuery: state.uri.queryParameters['q'])),
      GoRoute(path: '/inbox/:id', builder: (context, state) => ReviewScreen(smsId: state.pathParameters['id']!)),
      GoRoute(
        path: '/loans/new',
        builder: (context, state) => LoanFormScreen(typeId: state.uri.queryParameters['type']),
      ),
      GoRoute(path: '/loans/types', builder: (context, state) => const LoanTypesScreen()),
      GoRoute(path: '/settings/preferences', builder: (context, state) => const PreferencesScreen()),
      GoRoute(
        path: '/settings/config/:key',
        builder: (context, state) => ConfigListScreen(listKey: state.pathParameters['key']!),
      ),
      GoRoute(path: '/settings/income-types', builder: (context, state) => const IncomeTypesScreen()),
      GoRoute(path: '/settings/categories', builder: (context, state) => const CategoriesScreen()),
      GoRoute(path: '/settings/recurring', builder: (context, state) => const RecurringScreen()),
      GoRoute(path: '/settings/salary', builder: (context, state) => const SalaryScreen()),
      GoRoute(path: '/settings/tax', builder: (context, state) => const TaxRulesScreen()),
      GoRoute(path: '/settings/security', builder: (context, state) => const SecurityScreen()),
      GoRoute(path: '/settings/ai', builder: (context, state) => const AiSettingsScreen()),
      GoRoute(path: '/settings/nudges', builder: (context, state) => const NudgeSettingsScreen()),
      GoRoute(path: '/ai/insights', builder: (context, state) => const AiInsightsScreen()),
      GoRoute(path: '/ai/chat', builder: (context, state) => const AiChatScreen()),
      GoRoute(path: '/settings/audit', builder: (context, state) => const AuditScreen()),
      GoRoute(
        path: '/loans/planner',
        builder: (context, state) => PayoffPlannerScreen(initialExtra: parseNpr(state.uri.queryParameters['extra'] ?? '')),
      ),
      GoRoute(
        path: '/loans/:id',
        builder: (context, state) => LoanDetailScreen(loanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/loans/:id/edit',
        builder: (context, state) => LoanFormScreen(loanId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/income/new',
        builder: (context, state) => AddIncomeScreen(
          accountId: state.uri.queryParameters['account'],
          typeId: state.uri.queryParameters['type'],
          amount: parseNpr(state.uri.queryParameters['amount'] ?? ''),
        ),
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
