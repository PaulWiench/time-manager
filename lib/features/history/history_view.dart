/// What History shows, at all three zoom levels.
///
/// A month, a week and a day are the same shape — a stamp, what happened, and
/// what it did to the balance — so they become the same row, and drilling in
/// reads as zooming rather than as visiting three different screens. Deciding
/// which of the nine day statuses applies is the bulk of the work here, and it
/// happens once, in plain Dart, where it can be tested.
library;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/day_settlement.dart';
import '../../domain/midnight_cutoff.dart';
import '../../domain/recalculation_engine.dart';
import '../../domain/timeline_builder.dart';
import '../../domain/tracking_state.dart';
import '../../widgets/day_row.dart';
import '../../widgets/event_timeline.dart';

enum HistoryMode { month, week, day }

/// Where ◀/▶ lands, given where you were.
///
/// The anchor is a whole date at every level; a level is just a different
/// window onto it. Stepping moves the unit that level shows and leaves the rest
/// of the date alone, which is what lets a level change need no logic at all.
/// It used to snap to 1 January in Month mode and to the 1st in Week mode, so
/// changing the year and then tapping Week put you in January no matter where
/// you had been looking.
DateTime stepAnchor({
  required HistoryMode mode,
  required DateTime anchor,
  required int direction,
}) =>
    switch (mode) {
      HistoryMode.month => shiftMonths(anchor, 12 * direction),
      HistoryMode.week => shiftMonths(anchor, direction),
      HistoryMode.day => shiftDays(anchor, 7 * direction),
    };

/// False once the anchor is in the current period. There is nothing ahead to
/// show — `_monthRows` returns an empty list for a future year — and stepping
/// into it left a blank screen with a date in the header.
bool canStepForward({
  required HistoryMode mode,
  required DateTime anchor,
  required DateTime today,
}) =>
    switch (mode) {
      HistoryMode.month => anchor.year < today.year,
      HistoryMode.week => anchor.year < today.year ||
          (anchor.year == today.year && anchor.month < today.month),
      HistoryMode.day => startOfWeek(anchor).isBefore(startOfWeek(today)),
    };

/// One row, ready to hand to [DayRow].
class HistoryRow {
  const HistoryRow({
    required this.date,
    required this.status,
    required this.blockTop,
    required this.blockBottom,
    required this.line1,
    this.line2,
    this.delta,
    this.deltaWarning = false,
    this.trailingIcon,
    this.chevron = false,
    this.expandable = false,
    this.expansion,
  });

  /// The start of the period this row covers — the day, the week's Monday, or
  /// the month's first. Doubles as the row's identity when stepping.
  final DateTime date;

  final DayRowStatus status;
  final String blockTop;
  final String blockBottom;
  final String line1;
  final String? line2;
  final String? delta;
  final bool deltaWarning;
  final IconData? trailingIcon;
  final bool chevron;

  /// Day rows with something in them can be opened; empty ones cannot.
  final bool expandable;

  final HistoryExpansion? expansion;
}

/// The inside of an opened day row.
class HistoryExpansion {
  const HistoryExpansion({
    required this.timeline,
    this.dayNote,
    this.sessionNotes = const [],
    this.consequence,
    this.onEditVacation,
  });

  final List<TimelineItem> timeline;

  /// A vacation day opens to an "Edit vacation" pill for its booking.
  final VoidCallback? onEditVacation;
  final String? dayNote;

  /// `08:05 session: pairing on the export bug`, one per session that has one.
  final List<String> sessionNotes;

  /// Shown under the timeline while a synthetic break is selected: what
  /// deleting it would do to the day's total.
  final String? consequence;
}

/// Everything a day row needs, gathered by the screen from the per-date
/// providers. Passing it as one value keeps [historyDayRow] a pure function.
class DayFacts {
  const DayFacts({
    required this.date,
    required this.settings,
    this.dayEntry,
    this.holiday,
    this.leave = const [],
    this.sessions = const [],
    this.breaks = const [],
    this.closingBalance,
    this.previousClosingBalance,
    this.runningSince,
    this.now,
    this.vacationName,
    this.vacationDay,
    this.vacationLength,
  });

  final DateTime date;
  final AppSetting? settings;
  final DayEntry? dayEntry;
  final PublicHoliday? holiday;
  final List<LeaveEntry> leave;
  final List<WorkSession> sessions;
  final List<BreakEntry> breaks;

  /// The running balance after this day, used only to decide whether the delta
  /// wears the warning treatment.
  final double? closingBalance;

  /// The day before's closing balance, which is what tells a day that *crossed*
  /// a bound apart from the run of days that merely stayed past it.
  final double? previousClosingBalance;

  /// Set on today when a session is open. `day_entries` only ever holds
  /// committed work, so without this History would report a smaller number for
  /// today than Home does — the same day, two answers.
  final DateTime? runningSince;

  final DateTime? now;

  /// The booking this vacation day belongs to: its name, if it has one, and
  /// the day's place in it — "day 6 of 11" (additions handoff §4.3).
  final String? vacationName;
  final int? vacationDay;
  final int? vacationLength;
}

/// A day row, with its expansion already built when [expanded].
HistoryRow historyDayRow({
  required DayFacts facts,
  required DateTime today,
  bool expanded = false,
  String? selectedBreakId,
  void Function(WorkSession session)? onEditSession,
  void Function(String breakId)? onSelectBreak,
  VoidCallback? onDeleteBreak,
  VoidCallback? onEditVacation,
}) {
  final date = facts.date;
  final settings = facts.settings;
  final entry = facts.dayEntry;
  final isToday = date == today;

  final target = settings == null
      ? 0.0
      : computeTargetHours(
          date: date,
          workDays: settings.workDays,
          weeklyHours: settings.weeklyHours,
          holidayFraction: facts.holiday?.fraction,
        );

  final blockTop = _weekdayAbbrev(date);
  final blockBottom = '${date.day}';

  final running = facts.runningSince != null && facts.now != null
      ? facts.now!.difference(facts.runningSince!)
      : Duration.zero;
  final worked = (entry?.netWorkedHours ?? 0) + running.inSeconds / 3600.0;
  final hasWork = facts.sessions.isNotEmpty || worked > 0;

  bool beyond(double? balance) =>
      balance != null &&
      balanceBeyondBounds(
        balance,
        floorHours: settings?.balanceFloorHours,
        capHours: settings?.balanceCapHours,
      );

  final warning = beyond(facts.closingBalance);

  // Only the day that *crossed* the bound explains itself. Once the balance
  // has been past a floor for three weeks, saying so on all fifteen rows
  // replaces fifteen useful time spans with the same sentence.
  final crossed = warning && !beyond(facts.previousClosingBalance);

  // Today is only allowed to show a shortfall once it is actually over — the
  // same rule Home applies to the running balance. Without it this row reads
  // "0:00 worked · −7:54" at nine in the morning, which is a verdict on a day
  // that has barely started.
  final todayOpen = isToday &&
      facts.now != null &&
      settings != null &&
      !dayIsFinished(
        now: facts.now!,
        day: date,
        hasActiveSession: facts.runningSince != null,
        lastCheckOut: _lastCheckOut(facts.sessions),
        workWindow: TimeOfDayWindow(
          startMinutes: settings.workWindowStartMinutes,
          endMinutes: settings.workWindowEndMinutes,
        ),
      );

  String? deltaText(double? value) {
    if (value == null) return null;
    // Nothing rather than a zero: "±0:00" would claim the day came out even,
    // when in fact it has not been judged yet.
    if (todayOpen && value < 0) return null;
    return AppFormat.hm(value, signed: true);
  }

  // A holiday outranks leave, which outranks work: a day off is what the day
  // was, even if an hour got logged on it.
  if (facts.holiday != null) {
    return HistoryRow(
      date: date,
      status: DayRowStatus.publicHoliday,
      blockTop: blockTop,
      blockBottom: blockBottom,
      line1: facts.holiday!.name,
      line2: 'Public holiday',
      trailingIcon: AppIcons.confetti,
    );
  }

  if (facts.leave.isNotEmpty) {
    final leave = _dominantLeave(facts.leave);
    // Leave used to hide the work entirely: a day marked as vacation that was
    // also worked showed "Vacation · 7:54" and nothing else, while the balance
    // quietly credited both and moved by a whole extra day. The status stays —
    // the day *is* marked as leave — but the work comes back into view, and
    // the row opens so the sessions can be checked.
    final leaveBlocks = hasWork ? _blocksFor(facts) : const <TimelineBlock>[];
    final booked = leave.type == LeaveType.vacation && facts.vacationDay != null;
    final named = booked && facts.vacationName != null;
    final canEditVacation = booked && onEditVacation != null;
    final hours = AppFormat.hm(leave.hours);

    return HistoryRow(
      date: date,
      status: switch (leave.type) {
        LeaveType.vacation => DayRowStatus.vacation,
        LeaveType.sick => DayRowStatus.sick,
        LeaveType.flexDay => DayRowStatus.flex,
      },
      blockTop: blockTop,
      blockBottom: blockBottom,
      line1: named ? facts.vacationName! : '${_leaveLabel(leave.type)} · $hours',
      line2: hasWork
          ? 'Also worked ${AppFormat.hm(worked)}'
          : named
              ? 'Vacation · day ${facts.vacationDay} of ${facts.vacationLength} · $hours'
              : (leave.notes?.isNotEmpty == true ? leave.notes : 'Leave'),
      delta: hasWork ? deltaText(entry?.balanceDelta) : null,
      trailingIcon: switch (leave.type) {
        LeaveType.vacation => AppIcons.airplaneTilt,
        LeaveType.sick => AppIcons.thermometerSimple,
        LeaveType.flexDay => AppIcons.arrowsLeftRight,
      },
      expandable: hasWork || canEditVacation,
      expansion: (hasWork || canEditVacation) && expanded
          ? _expansionFor(
              facts: facts,
              blocks: leaveBlocks,
              selectedBreakId: selectedBreakId,
              onEditSession: onEditSession,
              onSelectBreak: onSelectBreak,
              onDeleteBreak: onDeleteBreak,
              onEditVacation: canEditVacation ? onEditVacation : null,
            )
          : null,
    );
  }

  if (!hasWork) {
    final isWorkDay = settings?.workDays.contains(date.weekday) ?? false;
    if (!isWorkDay) {
      return HistoryRow(
        date: date,
        status: DayRowStatus.rest,
        blockTop: blockTop,
        blockBottom: blockBottom,
        line1: 'Rest day',
        delta: '—',
      );
    }
    if (date.isAfter(today) || isToday) {
      return HistoryRow(
        date: date,
        status: isToday ? DayRowStatus.today : DayRowStatus.future,
        blockTop: blockTop,
        blockBottom: blockBottom,
        line1: isToday ? '0:00 worked' : 'Scheduled',
        line2: '${AppFormat.hm(target)} target',
        delta: isToday ? deltaText(entry?.balanceDelta ?? 0) : null,
      );
    }
    return HistoryRow(
      date: date,
      status: DayRowStatus.missed,
      blockTop: blockTop,
      blockBottom: blockBottom,
      line1: 'No entry',
      line2: 'Scheduled workday · missed',
      delta: deltaText(entry?.balanceDelta ?? -target),
    );
  }

  final blocks = _blocksFor(facts);
  final firstIn = blocks.isEmpty ? facts.runningSince : blocks.first.start;
  final span = firstIn == null
      ? null
      : running > Duration.zero
          ? '${AppFormat.time(firstIn)}–now'
          : '${AppFormat.time(firstIn)}–${AppFormat.time(blocks.last.end)}';

  // A day still in progress has no settled delta — `balanceDelta` counts only
  // committed work — so it is derived live, the same way Home derives it.
  final delta = running > Duration.zero
      ? worked - (entry?.targetHours ?? target)
      : entry?.balanceDelta;

  return HistoryRow(
    date: date,
    status: isToday ? DayRowStatus.today : DayRowStatus.normal,
    blockTop: blockTop,
    blockBottom: blockBottom,
    line1: '${AppFormat.hm(worked)} worked',
    line2: crossed
        ? 'Balance ${AppFormat.hm(facts.closingBalance!, signed: true)} after this day'
        : [if (isToday) 'Today', if (span != null) span].join(' · '),
    delta: deltaText(delta),
    deltaWarning: warning,
    expandable: true,
    expansion: expanded
        ? _expansionFor(
            facts: facts,
            blocks: blocks,
            selectedBreakId: selectedBreakId,
            onEditSession: onEditSession,
            onSelectBreak: onSelectBreak,
            onDeleteBreak: onDeleteBreak,
          )
        : null,
  );
}

/// The end of the last completed session, which is what "how long have you
/// been idle" is measured from.
DateTime? _lastCheckOut(List<WorkSession> sessions) {
  DateTime? latest;
  for (final session in sessions) {
    final end = session.endTime;
    if (session.status != SessionStatus.completed || end == null) continue;
    if (latest == null || end.isAfter(latest)) latest = end;
  }
  return latest;
}

List<TimelineBlock> _blocksFor(DayFacts facts) => buildDayTimeline(
      sessions: [
        for (final s in facts.sessions)
          if (s.status == SessionStatus.completed && s.endTime != null)
            TimelineInterval(start: s.startTime, end: s.endTime!, id: s.id),
      ],
      syntheticBreaks: [
        for (final b in facts.breaks)
          if (b.type == BreakType.synthetic)
            TimelineSyntheticBreak(id: b.id, start: b.startTime, end: b.endTime),
      ],
    );

HistoryExpansion _expansionFor({
  required DayFacts facts,
  required List<TimelineBlock> blocks,
  String? selectedBreakId,
  void Function(WorkSession session)? onEditSession,
  void Function(String breakId)? onSelectBreak,
  VoidCallback? onDeleteBreak,
  VoidCallback? onEditVacation,
}) {
  final items = <TimelineItem>[];
  String? consequence;

  if (blocks.isNotEmpty) {
    items.add(TimelineEvent(
      label: 'Check in',
      time: AppFormat.time(blocks.first.start),
      isCheckIn: true,
    ));
  }

  for (final block in blocks) {
    final range = '${AppFormat.time(block.start)}–${AppFormat.time(block.end)}';
    switch (block.type) {
      case TimelineBlockType.work:
        items.add(TimelineChipItem(
          role: EventChipRole.work,
          label: 'Work · $range',
          onLongPress: onEditSession == null
              ? null
              : () {
                  for (final session in facts.sessions) {
                    if (session.id == block.id) {
                      onEditSession(session);
                      return;
                    }
                  }
                },
        ));
      case TimelineBlockType.realBreak:
        items.add(TimelineChipItem(
          role: EventChipRole.realBreak,
          label: 'Break · $range',
        ));
      case TimelineBlockType.syntheticBreak:
        final selected = block.id != null && block.id == selectedBreakId;
        items.add(TimelineChipItem(
          role: EventChipRole.syntheticBreak,
          label: 'Synthetic break · $range',
          selected: selected,
          onTap: onSelectBreak == null || block.id == null
              ? null
              : () => onSelectBreak(block.id!),
          onDelete: onDeleteBreak,
        ));
        if (selected) {
          // Deleting the break gives its minutes back to the day, and the row
          // says so before the tap rather than after it.
          final gained = block.duration.inSeconds / 3600.0;
          final net = facts.dayEntry?.netWorkedHours ?? 0;
          consequence = 'Delete to count $range as work '
              '(${AppFormat.hm(net)} → ${AppFormat.hm(net + gained)})';
        }
    }
  }

  if (blocks.isNotEmpty) {
    items.add(TimelineEvent(
      label: 'Check out',
      time: AppFormat.time(blocks.last.end),
      isCheckIn: false,
    ));
  }

  return HistoryExpansion(
    onEditVacation: onEditVacation,
    timeline: items,
    dayNote: facts.dayEntry?.notes?.isNotEmpty == true ? facts.dayEntry!.notes : null,
    sessionNotes: [
      for (final s in facts.sessions)
        if (s.notes != null && s.notes!.isNotEmpty)
          '${AppFormat.time(s.startTime)} session: ${s.notes}',
    ],
    consequence: consequence,
  );
}

/// A month or week summary row: the same shape, with a chevron instead of an
/// expansion.
HistoryRow historySummaryRow({
  required HistoryMode mode,
  required DateTime start,
  required DateTime endExclusive,
  required List<DayEntry> entries,
  required DateTime today,
}) {
  // A `day_entries` row exists for any date carrying leave or a holiday,
  // including dates in the future — vacation booked for next month has a row
  // the day it is booked. Those rows are excluded from the balance cascade,
  // but folded in here they would credit a month with hours nobody has taken.
  final settled = [for (final e in entries) if (!e.date.isAfter(today)) e];

  final hours = settled.fold<double>(0, (sum, e) => sum + e.netWorkedHours);
  // Today's stored delta is a full-day shortfall until the day is worked, so a
  // summary containing today would read several hours worse every morning and
  // recover by evening. It is held back here exactly as the day row holds it.
  final delta = settled.fold<double>(
    0,
    (sum, e) => sum + (e.date == today && e.balanceDelta < 0 ? 0 : e.balanceDelta),
  );
  final inProgress = !today.isBefore(start) && today.isBefore(endExclusive);

  return HistoryRow(
    date: start,
    status: inProgress ? DayRowStatus.today : DayRowStatus.normal,
    blockTop: mode == HistoryMode.month ? '${start.year}' : 'WK',
    blockBottom: mode == HistoryMode.month
        ? AppFormat.monthAbbrev(start)
        : '${isoWeekNumber(start)}',
    line1: mode == HistoryMode.month
        ? AppFormat.monthName(start)
        : AppFormat.weekRangeShort(start, shiftDays(start, 6)),
    line2: '${AppFormat.hm(hours)} worked${inProgress ? ' · in progress' : ''}',
    delta: AppFormat.hm(delta, signed: true),
    chevron: true,
  );
}

LeaveEntry _dominantLeave(List<LeaveEntry> leave) {
  // Sick outranks vacation outranks a flex day: the less planned the reason,
  // the more it defines the day.
  for (final type in [LeaveType.sick, LeaveType.vacation, LeaveType.flexDay]) {
    for (final entry in leave) {
      if (entry.type == type) return entry;
    }
  }
  return leave.first;
}

String _leaveLabel(LeaveType type) => switch (type) {
      LeaveType.vacation => 'Vacation',
      LeaveType.sick => 'Sick',
      LeaveType.flexDay => 'Flex day',
    };

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

String _weekdayAbbrev(DateTime date) => _weekdays[date.weekday - 1];
