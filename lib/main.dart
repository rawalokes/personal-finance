import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'data/audit_log.dart';
import 'data/clock.dart';
import 'data/db/database.dart';
import 'data/repos/settings_repo.dart';
import 'data/seed.dart';
import 'data/settings_models.dart';
import 'store/data_providers.dart';
import 'store/ui_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App-private support directory: the drift_flutter default is the
  // documents folder, which on desktop is the user's own ~/Documents.
  final db = AppDatabase(driftDatabase(
    name: 'paisa',
    native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
  ));
  await seedIfNeeded(db);

  // Saved preferences are read before the first frame, so the app opens in
  // the right theme and grouping; changes are written back in order.
  final settings = SettingsRepository(db, AuditLog(db, clock: systemClock, newId: const Uuid().v4));
  var prefs = await settings.prefs();
  final initial = prefs;
  var pending = Future<void>.value();
  void savePrefs(AppPrefs Function(AppPrefs) update) {
    prefs = update(prefs);
    final snapshot = prefs;
    pending = pending.then((_) => settings.savePrefs(snapshot));
  }

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialPrefsProvider.overrideWithValue(initial),
      prefsSaverProvider.overrideWithValue(savePrefs),
    ],
    child: const PaisaApp(),
  ));
}
