/// History at all three zoom levels, plus the expanded and selected states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/features/history/history_body.dart';
import 'package:time_manager/features/history/history_view.dart';
import 'package:time_manager/widgets/app_date_picker.dart';

import 'fixtures/history_fixtures.dart' as fixtures;
import 'harness.dart';

void main() {
  setUpAll(loadAppFonts);

  final monday = DateTime(2026, 9, 21);

  final screens = <String, Widget>{
    'history-month': HistoryBody(
      mode: HistoryMode.month,
      stepperLabel: '2026',
      rows: fixtures.monthRows(),
    ),
    'history-week': HistoryBody(
      mode: HistoryMode.week,
      stepperLabel: 'September 2026',
      rows: fixtures.weekRows(),
    ),
    'history-day-sep': HistoryBody(
      mode: HistoryMode.day,
      stepperLabel: '21–27 Sep 2026',
      rows: fixtures.septemberDays(),
    ),
    'history-day-jun': HistoryBody(
      mode: HistoryMode.day,
      stepperLabel: '1–7 Jun 2026',
      rows: fixtures.juneDays(),
    ),
    'history-day-expanded': HistoryBody(
      mode: HistoryMode.day,
      stepperLabel: '21–27 Sep 2026',
      rows: fixtures.septemberDays(expanded: monday),
      expandedDay: monday,
    ),
    'history-day-synthetic': HistoryBody(
      mode: HistoryMode.day,
      stepperLabel: '21–27 Sep 2026',
      rows: fixtures.septemberDays(expanded: monday, selectedBreakId: 'mon-break'),
      expandedDay: monday,
    ),
    'history-day-leave-worked': HistoryBody(
      mode: HistoryMode.day,
      stepperLabel: '28 Sep – 4 Oct 2026',
      rows: fixtures.leaveWorkedDays(),
      expandedDay: DateTime(2026, 9, 28),
    ),
    // `now` is pinned, not defaulted: the "today" outline used to come from
    // the wall clock, so this render drifted by one cell every day and the
    // golden failed a little more each morning.
    'history-date-picker': AppDatePicker(
      initial: DateTime(2026, 9, 14),
      last: DateTime(2026, 9, 22),
      now: DateTime(2026, 9, 22),
    ),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} (${brightness.name})', (tester) async {
        await renderGolden(
          tester,
          name: entry.key,
          brightness: brightness,
          child: entry.value,
        );
      });
    }
  }
}
