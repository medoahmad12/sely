import 'package:flutter_test/flutter_test.dart';
import 'package:sely_kids/core/l10n/app_strings.dart';

void main() {
  test('Arabic and English tables have the same keys', () {
    expect(AppStrings.arabicKeys.difference(AppStrings.englishKeys), isEmpty);
    expect(AppStrings.englishKeys.difference(AppStrings.arabicKeys), isEmpty);
  });

  test('placeholders are replaced and unknown keys do not crash', () {
    const ar = AppStrings('ar');
    expect(ar.get('find_letter', {'x': 'باء'}), 'أين حرف باء؟');
    expect(const AppStrings('en').get('home_greet', {'name': 'Sam'}), contains('Sam'));
    expect(ar.get('does_not_exist'), 'does_not_exist');
  });
}
