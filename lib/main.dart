import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/db/database.dart';
import 'data/seed.dart';
import 'store/data_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App-private support directory: the drift_flutter default is the
  // documents folder, which on desktop is the user's own ~/Documents.
  final db = AppDatabase(driftDatabase(
    name: 'paisa',
    native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
  ));
  await seedIfNeeded(db);
  runApp(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const PaisaApp(),
  ));
}
