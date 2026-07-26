import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Onest for UI copy and Unbounded for accent typography', () {
    final textTheme = AppTheme.light.textTheme;

    expect(textTheme.bodyLarge?.fontFamily, AppTheme.bodyFontFamily);
    expect(textTheme.titleLarge?.fontFamily, AppTheme.bodyFontFamily);
    expect(textTheme.labelLarge?.fontFamily, AppTheme.bodyFontFamily);

    expect(textTheme.displayMedium?.fontFamily, AppTheme.accentFontFamily);
    expect(textTheme.headlineLarge?.fontFamily, AppTheme.accentFontFamily);
    expect(textTheme.headlineSmall?.fontFamily, AppTheme.accentFontFamily);
  });
}
