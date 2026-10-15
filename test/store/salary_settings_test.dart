import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/store/salary_settings.dart';

void main() {
  test('a clean install has no employer and no gross salary, only the labelled sample tax rules', () {
    final s = ProviderContainer.test().read(salarySettingsProvider);
    expect(s.employer, isEmpty);
    expect(s.grossMonthly, 0);
    expect(s.rules.isSampleDefault, isTrue);
  });
}
