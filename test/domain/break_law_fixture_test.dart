/// The Dart half of the shared break-law fixture.
///
/// The widget has to know this rule too — it runs in the launcher's process
/// and cannot call into Dart — so the rule exists twice. Both copies are
/// checked against the same file, which is the only thing keeping them honest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/break_engine.dart';

void main() {
  final fixture = jsonDecode(
    File('android/app/src/test/resources/break_law.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final raw in fixture['cases'] as List) {
    final testCase = raw as Map<String, dynamic>;

    test('break law: ${testCase['name']}', () {
      final gross = Duration(minutes: testCase['grossMinutes'] as int);
      final realBreaks = Duration(minutes: testCase['realBreakMinutes'] as int);

      final required = requiredBreakFor(gross);
      expect(required.inMinutes, testCase['expectedRequiredMinutes']);

      // The net formula the widget mirrors: only the shortfall comes off,
      // because time already spent between sessions was never counted as work.
      final deficit = required > realBreaks ? required - realBreaks : Duration.zero;
      expect((gross - deficit).inMinutes, testCase['expectedNetMinutes']);
    });
  }
}
