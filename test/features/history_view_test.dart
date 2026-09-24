/// Which of the nine day statuses a date gets, and why.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/features/history/history_view.dart';
import 'package:time_manager/widgets/day_row.dart';

import '../fixtures/rows.dart';

void main() {
  final today = DateTime(2026, 9, 22); // a Tuesday
  final settings = settingsRow();

  HistoryRow row(DayFacts facts, {bool expanded = false, String? selected}) =>
      historyDayRow(
        facts: facts,
        today: today,
        expanded: expanded,
        selectedBreakId: selected,
        onSelectBreak: (_) {},
        onDeleteBreak: () {},
      );

  test('a scheduled day with nothing on it is missed only once it is past', () {
    expect(
      row(DayFacts(date: DateTime(2026, 9, 21), settings: settings)).status,
      DayRowStatus.missed,
    );
    expect(
      row(DayFacts(date: DateTime(2026, 9, 23), settings: settings)).status,
      DayRowStatus.future,
    );
    expect(row(DayFacts(date: today, settings: settings)).status, DayRowStatus.today);
  });

  test('a weekend is a rest day, not a missed one', () {
    final saturday = row(DayFacts(date: DateTime(2026, 9, 19), settings: settings));
    expect(saturday.status, DayRowStatus.rest);
    expect(saturday.delta, '—');
  });

  test('a holiday outranks leave, and leave outranks the work logged on it', () {
    final date = DateTime(2026, 6, 4);
    final holiday = PublicHoliday(
      date: date,
      name: 'Fronleichnam',
      fraction: 1,
      source: HolidaySource.auto,
      createdAt: date,
    );

    expect(
      row(DayFacts(
        date: date,
        settings: settings,
        holiday: holiday,
        leave: [leaveRow(date: date, hours: 7.9)],
      )).status,
      DayRowStatus.publicHoliday,
    );

    expect(
      row(DayFacts(
        date: date,
        settings: settings,
        leave: [leaveRow(date: date, hours: 7.9, type: LeaveType.sick)],
        dayEntry: dayEntryRow(date: date, netWorkedHours: 1),
      )).status,
      DayRowStatus.sick,
    );
  });

  test('a delta past a configured bound says so instead of showing the span', () {
    final date = DateTime(2026, 9, 18);
    final facts = DayFacts(
      date: date,
      settings: settingsRow(balanceFloorHours: -20),
      dayEntry: dayEntryRow(date: date, netWorkedHours: 7.117, balanceDelta: -0.783),
      sessions: [sessionRow(start: DateTime(2026, 9, 18, 8), end: DateTime(2026, 9, 18, 15, 37))],
      closingBalance: -20.683,
    );

    final result = row(facts);
    expect(result.deltaWarning, isTrue);
    expect(result.line2, 'Balance −20:41 after this day');
  });

  test('only the day that crossed a bound explains itself', () {
    DayFacts facts(double closing, double previous) => DayFacts(
          date: DateTime(2026, 9, 18),
          settings: settingsRow(balanceFloorHours: -20),
          dayEntry: dayEntryRow(date: DateTime(2026, 9, 18), netWorkedHours: 7.1),
          sessions: [
            sessionRow(start: DateTime(2026, 9, 18, 8), end: DateTime(2026, 9, 18, 15, 37)),
          ],
          closingBalance: closing,
          previousClosingBalance: previous,
        );

    // Deep past the floor for a second day: still warns, but the row goes back
    // to saying when the day was worked.
    final stayed = row(facts(-21.5, -20.7));
    expect(stayed.deltaWarning, isTrue);
    expect(stayed.line2, '08:00–15:37');

    final crossed = row(facts(-20.7, -19.5));
    expect(crossed.line2, 'Balance −20:42 after this day');
  });

  test("today's row counts the running session, as Home does", () {
    final facts = DayFacts(
      date: today,
      settings: settings,
      dayEntry: dayEntryRow(date: today, netWorkedHours: 3.9, targetHours: 7.9),
      sessions: [
        sessionRow(id: 'a', start: DateTime(2026, 9, 22, 9), end: DateTime(2026, 9, 22, 12, 52)),
      ],
      runningSince: DateTime(2026, 9, 22, 14, 51),
      now: DateTime(2026, 9, 22, 16, 37),
    );

    final result = row(facts);
    expect(result.line1, '5:40 worked');
    expect(result.line2, 'Today · 09:00–now');
    // A day in progress has no settled delta; it is derived live.
    expect(result.delta, '−2:14');
  });

  test('selecting a synthetic break says what deleting it would do', () {
    final date = DateTime(2026, 9, 21);
    final facts = DayFacts(
      date: date,
      settings: settings,
      dayEntry: dayEntryRow(date: date, netWorkedHours: 8.1),
      sessions: [
        sessionRow(id: 'a', start: DateTime(2026, 9, 21, 8, 5), end: DateTime(2026, 9, 21, 12)),
        sessionRow(id: 'b', start: DateTime(2026, 9, 21, 12, 30), end: DateTime(2026, 9, 21, 16, 41)),
      ],
      breaks: [
        breakRow(id: 'gap', start: DateTime(2026, 9, 21, 12), end: DateTime(2026, 9, 21, 12, 30)),
      ],
    );

    expect(row(facts, expanded: true).expansion!.consequence, isNull);
    expect(
      row(facts, expanded: true, selected: 'gap').expansion!.consequence,
      'Delete to count 12:00–12:30 as work (8:06 → 8:36)',
    );
  });
}
