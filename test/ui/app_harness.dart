import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/app.dart';
import 'package:paisa/data/clock.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/router.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/ui/components/inputs.dart';

import '../data/data_fixtures.dart';
import '../data/sample_data.dart';
import '../data/test_db.dart';

/// Opens the real app on an in-memory database with the clock fixed at
/// 14 Oct 2026 10:30 and a 390 × 844 screen (spec §8 base size).
/// [seed] (default) loads the spec §12 sample data and sample salary;
/// [cleanInstall] loads only what a fresh install has; neither = empty db.
Future<AppDatabase> pumpPaisa(
  WidgetTester tester, {
  String location = '/home',
  Size size = const Size(390, 844),
  bool seed = true,
  bool cleanInstall = false,
  List<Override> overrides = const [],
  Clock? clock,
}) async {
  final db = openTestDb();
  if (cleanInstall) {
    await seedIfNeeded(db);
  } else if (seed) {
    await seedWithSampleData(db);
  }
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock ?? testClock),
      idGenProvider.overrideWithValue(counterIds('new')),
      initialLocationProvider.overrideWithValue(location),
      ...overrides,
    ],
    child: const PaisaApp(),
  ));
  await tester.pumpAndSettle();
  return db;
}

/// The editable text inside the [PaisaTextField] labelled [label].
Finder fieldLabelled(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(EditableText),
    );

/// The page's vertical scrollable. (Text fields contain horizontal
/// scrollables of their own, so "the first Scrollable" is not reliable.)
Finder get pageScrollable => find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

/// Scrolls the page down until [finder] shows, then fully into view.
Future<void> scrollPageTo(WidgetTester tester, Finder finder) async {
  // Like a user closing the keyboard first: a focused text field otherwise
  // scrolls itself back on screen.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 200, scrollable: pageScrollable);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollPageTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps a chip in a horizontal chip row, scrolling it into view first.
Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(PaisaChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}
