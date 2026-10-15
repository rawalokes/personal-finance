import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/app.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/router.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/ui/components/inputs.dart';

import '../data/data_fixtures.dart';
import '../data/test_db.dart';

/// Opens the real app on a seeded in-memory database, with the clock fixed
/// at 14 Oct 2026 10:30 and a 390 × 844 screen (spec §8 base size).
Future<AppDatabase> pumpPaisa(
  WidgetTester tester, {
  String location = '/home',
  Size size = const Size(390, 844),
  bool seed = true,
  List<Override> overrides = const [],
}) async {
  final db = openTestDb();
  if (seed) await seedIfNeeded(db);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(testClock),
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

/// Scrolls the page (the first, outermost scrollable) until [finder] shows.
Future<void> scrollPageTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

/// Scrolls the first scrollable until [finder] is visible, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
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
