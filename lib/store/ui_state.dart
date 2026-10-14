import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/money.dart';

/// "Hide balances" (eye icon on Home).
class HideBalances extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final hideBalancesProvider = NotifierProvider<HideBalances, bool>(HideBalances.new);

/// Lakh (1,00,000) or international (100,000) grouping.
class NumberGrouping extends Notifier<Grouping> {
  @override
  Grouping build() => Grouping.lakh;
  void set(Grouping g) => state = g;
}

final groupingProvider = NotifierProvider<NumberGrouping, Grouping>(NumberGrouping.new);

final moneyFormatProvider = Provider<MoneyFormat>(
  (ref) => MoneyFormat(grouping: ref.watch(groupingProvider), masked: ref.watch(hideBalancesProvider)),
);
/// Night (dark) is the default (spec §8).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;
  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Messages waiting in the Transaction Inbox (Needs review + Later).
/// Plan 3 replaces this body with a query on the SMS repository.
final inboxPendingCountProvider = Provider<int>((ref) => 0);
