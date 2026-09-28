/// The History states the design drew (handoff §4.3), as real data.
///
/// Every row goes through `historyDayRow` / `historySummaryRow`, so the nine
/// statuses are decided by the same code the app runs rather than by the
/// fixture asserting which one it wants.
library;

import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/domain/date_only.dart';
import 'package:time_manager/features/history/history_view.dart';

import '../../fixtures/rows.dart';

final today = DateTime(2026, 9, 22);

const _target = 7.9; // 7:54

/// Month mode over 2026, with the figures from the design's own table.
List<HistoryRow> monthRows() {
  const data = <int, (double, double)>{
    9: (129.533, 3.133), // 129:32, +3:08
    8: (157.4, -8.5),
    7: (175.9, -5.8),
    6: (166.933, 1.033),
    5: (137.95, -4.25),
    4: (151.667, -6.333),
    3: (177.467, 3.667),
    2: (156.917, -1.083),
    1: (160.167, 2.167),
  };

  return [
    for (final month in data.keys)
      historySummaryRow(
        mode: HistoryMode.month,
        start: DateTime(2026, month),
        endExclusive: DateTime(2026, month + 1),
        entries: [
          dayEntryRow(
            date: DateTime(2026, month),
            netWorkedHours: data[month]!.$1,
            balanceDelta: data[month]!.$2,
          ),
        ],
        today: today,
      ),
  ];
}

/// Week mode over September 2026.
List<HistoryRow> weekRows() {
  const worked = [16.0, 38.6, 39.2, 35.8];

  return [
    for (final (i, start) in [
      DateTime(2026, 9, 21),
      DateTime(2026, 9, 14),
      DateTime(2026, 9, 7),
      DateTime(2026, 8, 31),
    ].indexed)
      historySummaryRow(
        mode: HistoryMode.week,
        start: start,
        endExclusive: shiftDays(start, 7),
        entries: [
          dayEntryRow(
            date: start,
            netWorkedHours: worked[i],
            balanceDelta: worked[i] - 39.5,
          ),
        ],
        today: today,
      ),
  ];
}

/// Day mode over the week of 21 September: worked, today, three future days
/// and a weekend.
List<HistoryRow> septemberDays({DateTime? expanded, String? selectedBreakId}) {
  final settings = settingsRow();

  return [
    for (var i = 0; i < 7; i++)
      _day(
        date: shiftDays(DateTime(2026, 9, 21), i),
        settings: settings,
        expanded: expanded,
        selectedBreakId: selectedBreakId,
      ),
  ];
}

HistoryRow _day({
  required DateTime date,
  required AppSetting settings,
  DateTime? expanded,
  String? selectedBreakId,
}) {
  final facts = switch (date.day) {
    // Monday: a normal worked day, with a synthetic break in the middle and
    // notes on both the day and the session.
    21 => DayFacts(
        date: date,
        settings: settings,
        dayEntry: dayEntryRow(
          date: date,
          netWorkedHours: 8.1,
          targetHours: _target,
          balanceDelta: 0.2,
          notes: 'Release prep for v1.2, left at 16:41 for the train.',
        ),
        sessions: [
          sessionRow(
            id: 'mon-1',
            start: DateTime(2026, 9, 21, 8, 5),
            end: DateTime(2026, 9, 21, 12),
            notes: 'pairing on the export bug',
          ),
          sessionRow(
            id: 'mon-2',
            start: DateTime(2026, 9, 21, 12, 30),
            end: DateTime(2026, 9, 21, 16, 41),
          ),
        ],
        breaks: [
          breakRow(
            id: 'mon-break',
            start: DateTime(2026, 9, 21, 12),
            end: DateTime(2026, 9, 21, 12, 30),
          ),
        ],
      ),
    // Tuesday is today, and finished.
    22 => DayFacts(
        date: date,
        settings: settings,
        dayEntry: dayEntryRow(
          date: date,
          netWorkedHours: _target,
          targetHours: _target,
        ),
        sessions: [
          sessionRow(
            id: 'tue',
            start: DateTime(2026, 9, 22, 8, 42),
            end: DateTime(2026, 9, 22, 18, 51),
          ),
        ],
      ),
    // Wednesday to Friday have not happened yet; the weekend never will.
    _ => DayFacts(date: date, settings: settings),
  };

  return historyDayRow(
    facts: facts,
    today: today,
    expanded: expanded == date,
    selectedBreakId: selectedBreakId,
    onSelectBreak: (_) {},
    onDeleteBreak: () {},
  );
}

/// The first week of June: a missed workday, a public holiday and a
/// Brückentag taken as vacation.
List<HistoryRow> juneDays() {
  final settings = settingsRow();
  final june = DateTime(2026, 6);

  DayFacts factsFor(DateTime date) => switch (date.day) {
        1 => DayFacts(
            date: date,
            settings: settings,
            dayEntry: dayEntryRow(
                date: date, netWorkedHours: 8.333, targetHours: _target, balanceDelta: 0.433),
            sessions: [
              sessionRow(id: 'jun1', start: DateTime(2026, 6, 1, 8, 12), end: DateTime(2026, 6, 1, 16, 52)),
            ],
          ),
        2 => DayFacts(
            date: date,
            settings: settings,
            dayEntry: dayEntryRow(
                date: date, netWorkedHours: 7.517, targetHours: _target, balanceDelta: -0.383),
            sessions: [
              sessionRow(id: 'jun2', start: DateTime(2026, 6, 2, 8, 30), end: DateTime(2026, 6, 2, 16, 31)),
            ],
          ),
        // Nothing logged on a scheduled workday in the past.
        3 => DayFacts(date: date, settings: settings),
        4 => DayFacts(
            date: date,
            settings: settings,
            holiday: PublicHoliday(
              date: date,
              name: 'Fronleichnam',
              fraction: 1,
              source: HolidaySource.auto,
              createdAt: date,
            ),
          ),
        5 => DayFacts(
            date: date,
            settings: settings,
            leave: [leaveRow(date: date, hours: _target, notes: 'Brückentag')],
          ),
        _ => DayFacts(date: date, settings: settings),
      };

  return [
    for (var i = 0; i < 7; i++)
      historyDayRow(facts: factsFor(shiftDays(june, i)), today: today),
  ];
}

/// The week of 28 September 2026, where a vacation block booked in August was
/// worked through anyway. The leave row used to show only `Vacation · 7:54` and
/// swallow the day's work and its delta whole; here it carries both, and opens.
List<HistoryRow> leaveWorkedDays() {
  final settings = settingsRow();
  final week = DateTime(2026, 9, 28);

  DayFacts factsFor(DateTime date) => switch (date.day) {
        28 => DayFacts(
            date: date,
            settings: settings,
            dayEntry: dayEntryRow(
              date: date,
              netWorkedHours: 5.8167,
              leaveHours: _target,
              targetHours: _target,
              balanceDelta: 5.8167,
            ),
            leave: [leaveRow(date: date, hours: _target)],
            sessions: [
              sessionRow(
                  id: 's1',
                  start: DateTime(2026, 9, 28, 9, 22),
                  end: DateTime(2026, 9, 28, 12, 15)),
              sessionRow(
                  id: 's2',
                  start: DateTime(2026, 9, 28, 13, 3),
                  end: DateTime(2026, 9, 28, 16, 0)),
            ],
          ),
        29 || 30 => DayFacts(
            date: date,
            settings: settings,
            dayEntry: dayEntryRow(date: date, leaveHours: _target, targetHours: _target),
            leave: [leaveRow(date: date, hours: _target)],
          ),
        _ => DayFacts(date: date, settings: settings),
      };

  return [
    for (var i = 0; i < 7; i++)
      historyDayRow(
        facts: factsFor(shiftDays(week, i)),
        today: DateTime(2026, 9, 28),
        expanded: shiftDays(week, i) == week,
      ),
  ];
}
