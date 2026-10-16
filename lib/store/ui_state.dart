import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_models.dart';
import '../finance/money.dart';
import 'sms_sync.dart';

/// Preferences saved last time, loaded in main.dart before the first frame
/// (so the app opens in the right theme). Defaults in tests.
final initialPrefsProvider = Provider<AppPrefs>((ref) => const AppPrefs());

/// Persists a preference change. main.dart overrides it with a database
/// writer; by default (tests) changes live in memory only.
typedef PrefsSaver = void Function(AppPrefs Function(AppPrefs) update);
final prefsSaverProvider = Provider<PrefsSaver>((ref) => (_) {});

/// "Hide balances" (eye icon on Home; Settings → Security).
class HideBalances extends Notifier<bool> {
  @override
  bool build() => ref.read(initialPrefsProvider).hideBalances;
  void toggle() => set(!state);
  void set(bool hidden) {
    state = hidden;
    ref.read(prefsSaverProvider)((p) => p.copyWith(hideBalances: hidden));
  }
}

final hideBalancesProvider = NotifierProvider<HideBalances, bool>(HideBalances.new);

/// Lakh (1,00,000) or international (100,000) grouping.
class NumberGrouping extends Notifier<Grouping> {
  @override
  Grouping build() => ref.read(initialPrefsProvider).grouping;
  void set(Grouping g) {
    state = g;
    ref.read(prefsSaverProvider)((p) => p.copyWith(grouping: g));
  }
}

final groupingProvider = NotifierProvider<NumberGrouping, Grouping>(NumberGrouping.new);

final moneyFormatProvider = Provider<MoneyFormat>(
  (ref) => MoneyFormat(grouping: ref.watch(groupingProvider), masked: ref.watch(hideBalancesProvider)),
);

/// Night (dark) is the default (spec §8).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(initialPrefsProvider).theme == ThemePref.light ? ThemeMode.light : ThemeMode.dark;
  void set(ThemeMode mode) {
    state = mode;
    ref.read(prefsSaverProvider)((p) => p.copyWith(theme: mode == ThemeMode.light ? ThemePref.light : ThemePref.dark));
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Bikram Sambat or Gregorian for the Home header date line.
class CalendarController extends Notifier<CalendarPref> {
  @override
  CalendarPref build() => ref.read(initialPrefsProvider).calendar;
  void set(CalendarPref c) {
    state = c;
    ref.read(prefsSaverProvider)((p) => p.copyWith(calendar: c));
  }
}

final calendarProvider = NotifierProvider<CalendarController, CalendarPref>(CalendarController.new);

final _pendingSmsProvider = StreamProvider<int>((ref) => ref.watch(smsRepoProvider).watchPendingCount());

/// Messages waiting in the Transaction Inbox (Needs review + Later).
final inboxPendingCountProvider = Provider<int>((ref) => ref.watch(_pendingSmsProvider).value ?? 0);
