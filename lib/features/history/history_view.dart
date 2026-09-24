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
import '../../domain/recalculation_engine.dart';
import '../../domain/timeline_builder.dart';
import '../../domain/tracking_state.dart';
import '../../widgets/day_row.dart';
import '../../widgets/event_timeline.dart';

enum HistoryMode { month, week, day }

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
  });

  final List<TimelineItem> timeline;
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

  final worked = entry?.netWorkedHours ?? 0;
  final hasWork = facts.sessions.isNotEmpty || worked > 0;
  final warning = facts.closingBalance != null &&
      balanceBeyondBounds(
        facts.closingBalance!,
        floorHours: settings?.balanceFloorHours,
        capHours: settings?.balanceCapHours,
      );

  String? deltaText(double? value) =>
      value == null ? null : AppFormat.hm(value, signed: true);

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
    return HistoryRow(
      date: date,
      status: switch (leave.type) {
        LeaveType.vacation => DayRowStatus.vacation,
        LeaveType.sick => DayRowStatus.sick,
        LeaveType.flexDay => DayRowStatus.flex,
      },
      blockTop: blockTop,
      blockBottom: blockBottom,
      line1: '${_leaveLabel(leave.type)} · ${AppFormat.hm(leave.hours)}',
      line2: leave.notes?.isNotEmpty == true ? leave.notes : 'Leave',
      trailingIcon: switch (leave.type) {
        LeaveType.vacation => AppIcons.airplaneTilt,
        LeaveType.sick => AppIcons.thermometerSimple,
        LeaveType.flexDay => AppIcons.arrowsLeftRight,
      },
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
  final span = blocks.isEmpty
      ? null
      : '${AppFormat.time(blocks.first.start)}–${AppFormat.time(blocks.last.end)}';

  return HistoryRow(
    date: date,
    status: isToday ? DayRowStatus.today : DayRowStatus.normal,
    blockTop: blockTop,
    blockBottom: blockBottom,
    line1: '${AppFormat.hm(worked)} worked',
    // The warning replaces the time span rather than sitting beside it: when
    // the balance has crossed a bound, that is the more important sentence.
    line2: warning
        ? 'Balance ${AppFormat.hm(facts.closingBalance!, signed: true)} after this day'
        : [if (isToday) 'Today', if (span != null) span].join(' · '),
    delta: deltaText(entry?.balanceDelta),
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
  final hours = entries.fold<double>(0, (sum, e) => sum + e.netWorkedHours);
  final delta = entries.fold<double>(0, (sum, e) => sum + e.balanceDelta);
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
