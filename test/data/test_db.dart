import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/db/database.dart';

/// A fresh in-memory database, closed automatically when the test ends.
/// `closeStreamsSynchronously` stops drift leaving timers behind in
/// widget tests.
AppDatabase openTestDb() {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  addTearDown(db.close);
  return db;
}
