/// The Dart half of the shared day-settlement fixture.
///
/// The widget has to know this rule too — it reads the balance straight out of
/// SQLite in the launcher's process and cannot call into Dart — so the rule
/// exists twice. Both copies are checked against the same file, which is what
/// stops a launcher tile and the screen behind it disagreeing about the
/// balance.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/day_settlement.dart';
import 'package:time_manager/domain/midnight_cutoff.dart';

void main() {
  final fixture = jsonDecode(
    File('android/app/src/test/resources/day_settlement.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final window = TimeOfDayWindow(
    startMinutes: fixture['windowStartMinutes'] as int,
    endMinutes: fixture['windowEndMinutes'] as int,
  );

  // The fixture is expressed in minutes-of-day and idle seconds, which is all
  // the widget can see. Both are turned back into wall-clock instants on one
  // arbitrary day here — the Dart function takes DateTimes.
  final day = DateTime(2026, 9, 22);

  for (final raw in fixture['cases'] as List) {
    final testCase = raw as Map<String, dynamic>;

    test('day settlement: ${testCase['name']}', () {
      final now = day.add(Duration(minutes: testCase['nowMinutesOfDay'] as int));
      final idle = testCase['secondsSinceLastCheckOut'] as int?;

      expect(
        dayIsFinished(
          now: now,
          day: day,
          hasActiveSession: testCase['hasActiveSession'] as bool,
          lastCheckOut: idle == null ? null : now.subtract(Duration(seconds: idle)),
          workWindow: window,
        ),
        testCase['expectedFinished'],
      );
    });
  }

  for (final raw in fixture['contributionCases'] as List) {
    final testCase = raw as Map<String, dynamic>;

    test('day contribution: ${testCase['name']}', () {
      expect(
        todayContribution(
          delta: (testCase['delta'] as num).toDouble(),
          finished: testCase['finished'] as bool,
        ),
        closeTo((testCase['expected'] as num).toDouble(), 1e-9),
      );
    });
  }
}
