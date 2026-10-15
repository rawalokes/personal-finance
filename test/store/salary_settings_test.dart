import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/store/data_providers.dart';
import 'package:paisa/store/salary_settings.dart';

import '../data/test_db.dart';

void main() {
  test('a clean install has no employer and no gross salary, only the labelled sample tax rules', () async {
    final db = openTestDb();
    await seedIfNeeded(db);
    final c = ProviderContainer.test(overrides: [databaseProvider.overrideWithValue(db)]);
    final sub = c.listen(salarySettingsProvider, (_, _) {});
    addTearDown(sub.close);
    final s = await c.read(salarySettingsProvider.future);
    expect(s.employer, isEmpty);
    expect(s.grossMonthly, 0);
    expect(s.rules.isSampleDefault, isTrue);
  });
}
