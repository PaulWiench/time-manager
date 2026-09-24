/// The widget's colour resources must be what the generator would produce.
///
/// This is the whole guard against the two palettes drifting apart again. It
/// fails loudly when only one side is edited, and regenerates when asked:
///
///     UPDATE_WIDGET_TOKENS=1 flutter test test/core/theme/widget_tokens_test.dart
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/widget_tokens.dart';

void main() {
  const files = {
    'android/app/src/main/res/values/tm_tokens.xml': false,
    'android/app/src/main/res/values-night/tm_tokens.xml': true,
  };

  final update = Platform.environment['UPDATE_WIDGET_TOKENS'] == '1';

  for (final entry in files.entries) {
    test('${entry.key} matches the palette', () {
      final expected = widgetTokensXml(
        entry.value ? AppColors.dark : AppColors.light,
        night: entry.value,
      );
      final file = File(entry.key);

      if (update) {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(expected);
        return;
      }

      expect(
        file.existsSync(),
        isTrue,
        reason: 'run with UPDATE_WIDGET_TOKENS=1 to generate it',
      );
      expect(
        file.readAsStringSync(),
        expected,
        reason: 'the widget palette has drifted from app_colors.dart; '
            'run with UPDATE_WIDGET_TOKENS=1',
      );
    });
  }
}
