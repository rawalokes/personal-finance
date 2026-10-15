import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _forbidden = [
  'package:flutter/',
  'package:flutter_riverpod',
  'dart:ui',
  'package:drift',
  'package:sqlite3',
  'package:http',
  'package:go_router',
];

void main() {
  test('lib/finance is pure Dart: no Flutter, database, network or UI imports', () {
    final dir = Directory('lib/finance');
    expect(dir.existsSync(), isTrue, reason: 'lib/finance must exist');
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);
    for (final f in files) {
      for (final line in f.readAsLinesSync()) {
        final t = line.trim();
        if (!t.startsWith('import ') && !t.startsWith('export ')) continue;
        for (final bad in _forbidden) {
          expect(t.contains(bad), isFalse, reason: '${f.path} imports $bad');
        }
      }
    }
  });
}
