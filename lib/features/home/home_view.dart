/// Everything Home draws, as one value.
///
/// The screen reads providers and builds this; the body takes it and draws it.
/// That split is what makes the eight designed states reproducible without a
/// device or a database: a render test constructs a [HomeView] directly and
/// pumps the body. It also means every "what should it say when…" decision
/// lives here, in one testable function, instead of being spread across the
/// widget tree as conditionals.
library;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/recalculation_engine.dart';
import '../../domain/timeline_builder.dart';
import '../../domain/tracking_state.dart';
import '../../widgets/day_rail.dart';
import '../../widgets/event_timeline.dart';

class HomeView {
  const HomeView({
    required this.dateLabel,
    required this.state,
    required this.balanceHours,
    required this.balanceWarning,
    required this.netHours,
    required this.targetHours,
    required this.ringProgress,
    required this.timerText,
    required this.sinceText,
    required this.rail,
    required this.railStart,
    required this.railEnd,
    required this.timeline,
    required this.hasActivity,
  });

  /// `Tue 22 Sep`.
  final String dateLabel;

  final TrackingState state;

  /// The latest snapshot, which is a closed figure — it does not tick with the
  /// running session, and the design says it never counts up.
  final double balanceHours;

  /// Past a floor or cap the user actually configured.
  final bool balanceWarning;

  /// Today's net so far, including the running session.
  final double netHours;
  final double targetHours;

  /// Worked over target. Above 1 the ring laps rather than stopping.
  final double ringProgress;

  /// The ring's centre figure: the running session, the break so far, or
  /// today's total.
  final String timerText;

  /// `since 14:51`, or `today`.
  final String sinceText;

  final List<RailSegment> rail;
  final DateTime railStart;
  final DateTime railEnd;

  final List<TimelineItem> timeline;

  /// False only on a day with nothing logged at all, which gets the empty
  /// state instead of a timeline.
  final bool hasActivity;

  /// Remaining, or surplus when over — the design wants the honest number, not
  /// a remaining clamped to zero.
  double get remainingHours => targetHours - netHours;
  bool get isOverTarget => remainingHours < 0;
}

HomeView buildHomeView({
  required DateTime now,
  required AppSetting settings,
  required DayEntry? dayEntry,
  required List<WorkSession> sessions,
  required List<BreakEntry> breaks,
  required List<LeaveEntry> leave,
  required BalanceSnapshot? balance,
  void Function(WorkSession session)? onEditSession,
  VoidCallback? onDeleteSyntheticBreak,
}) {
  final today = DateTime(now.year, now.month, now.day);

  WorkSession? active;
  final completed = <WorkSession>[];
  for (final session in sessions) {
    if (session.status == SessionStatus.active) {
      active = session;
    } else if (session.status == SessionStatus.completed && session.endTime != null) {
      completed.add(session);
    }
  }
  completed.sort((a, b) => a.startTime.compareTo(b.startTime));

  final lastCheckOut = completed.isEmpty ? null : completed.last.endTime;

  final targetHours = dayEntry?.targetHours ??
      computeTargetHours(
        date: today,
        workDays: settings.workDays,
        weeklyHours: settings.weeklyHours,
      );

  // The committed net is whatever the recalculation engine last wrote; the
  // running session is added on top so the ring and the today bar move without
  // waiting for a check-out.
  final runningFor = active == null ? Duration.zero : now.difference(active.startTime);
  final netHours = (dayEntry?.netWorkedHours ?? 0) + runningFor.inSeconds / 3600.0;

  final state = trackingStateFor(
    now: now,
    hasActiveSession: active != null,
    lastCheckOut: lastCheckOut,
    completedSessionsToday: completed.length,
    targetMet: targetHours > 0 && netHours >= targetHours,
  );

  final blocks = buildDayTimeline(
    sessions: [
      for (final s in completed) TimelineInterval(start: s.startTime, end: s.endTime!, id: s.id),
    ],
    syntheticBreaks: [
      for (final b in breaks)
        if (b.type == BreakType.synthetic)
          TimelineSyntheticBreak(id: b.id, start: b.startTime, end: b.endTime),
    ],
  );

  final balanceHours = balance?.balance ?? 0.0;

  return HomeView(
    dateLabel: AppFormat.headerDate(now),
    state: state,
    balanceHours: balanceHours,
    balanceWarning: balanceBeyondBounds(
      balanceHours,
      floorHours: settings.balanceFloorHours,
      capHours: settings.balanceCapHours,
    ),
    netHours: netHours,
    targetHours: targetHours,
    ringProgress: targetHours > 0 ? netHours / targetHours : 0,
    timerText: switch (state) {
      TrackingState.tracking => AppFormat.hms(runningFor),
      // On a break the relevant clock is the break, not the session that
      // ended — the ring shows one timer and this is the one that is running.
      TrackingState.onBreak => AppFormat.hms(_nonNegative(now.difference(lastCheckOut!))),
      _ => AppFormat.hm(netHours),
    },
    sinceText: switch (state) {
      TrackingState.tracking => 'since ${AppFormat.time(active!.startTime)}',
      TrackingState.onBreak => 'since ${AppFormat.time(lastCheckOut!)}',
      _ => 'today',
    },
    rail: _railSegments(
      blocks: blocks,
      active: active,
      now: now,
      leave: leave,
      state: state,
      lastCheckOut: lastCheckOut,
    ),
    railStart: _railStart(blocks: blocks, active: active, today: today),
    railEnd: _railEnd(
      blocks: blocks,
      active: active,
      now: now,
      today: today,
      state: state,
      leave: leave,
    ),
    timeline: _timeline(
      blocks: blocks,
      completed: completed,
      active: active,
      leave: leave,
      state: state,
      lastCheckOut: lastCheckOut,
      now: now,
      onEditSession: onEditSession,
      onDeleteSyntheticBreak: onDeleteSyntheticBreak,
    ),
    hasActivity: sessions.isNotEmpty || leave.isNotEmpty,
  );
}

Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

/// Leave is stored as a number of hours with no clock times, so it cannot be
/// placed truthfully anywhere on the day's axis. It is drawn as a block of its
/// own length at the end instead, and the axis is extended to hold it — an
/// honest "this much of today was leave" rather than an invented 09:00–13:00.
Duration _leaveDuration(List<LeaveEntry> leave) => Duration(
      seconds: (leave.fold<double>(0, (sum, l) => sum + l.hours) * 3600).round(),
    );

DateTime _railStart({
  required List<TimelineBlock> blocks,
  required WorkSession? active,
  required DateTime today,
}) {
  if (blocks.isNotEmpty) return blocks.first.start;
  if (active != null) return active.startTime;
  return today;
}

DateTime _railEnd({
  required List<TimelineBlock> blocks,
  required WorkSession? active,
  required DateTime now,
  required DateTime today,
  required TrackingState state,
  required List<LeaveEntry> leave,
}) {
  final leaveFor = _leaveDuration(leave);
  // While anything is running the axis ends at now, so the rail keeps
  // stretching; once the day is closed it ends at the last check-out.
  final end = switch (state) {
    TrackingState.tracking || TrackingState.onBreak => now,
    _ => blocks.isEmpty ? today : blocks.last.end,
  };
  return end.add(leaveFor);
}

List<RailSegment> _railSegments({
  required List<TimelineBlock> blocks,
  required WorkSession? active,
  required DateTime now,
  required List<LeaveEntry> leave,
  required TrackingState state,
  required DateTime? lastCheckOut,
}) {
  final segments = [
    for (final block in blocks)
      RailSegment(
        type: switch (block.type) {
          TimelineBlockType.work => RailSegmentType.work,
          TimelineBlockType.realBreak => RailSegmentType.realBreak,
          TimelineBlockType.syntheticBreak => RailSegmentType.syntheticBreak,
        },
        start: block.start,
        end: block.end,
      ),
  ];

  if (active != null) {
    // The gap between the last block and a session that resumed later is a
    // break, even though no break row exists for it yet.
    if (blocks.isNotEmpty && active.startTime.isAfter(blocks.last.end)) {
      segments.add(RailSegment(
        type: RailSegmentType.realBreak,
        start: blocks.last.end,
        end: active.startTime,
      ));
    }
    segments.add(RailSegment(type: RailSegmentType.work, start: active.startTime, end: now));
  } else if (state == TrackingState.onBreak && lastCheckOut != null) {
    // The break in progress has no row of its own — a break is only ever the
    // gap between two sessions — but it is the thing currently happening, so
    // the rail has to show it growing.
    segments.add(RailSegment(type: RailSegmentType.realBreak, start: lastCheckOut, end: now));
  }

  var cursor = segments.isEmpty ? now : segments.last.end;
  for (final entry in leave) {
    final end = cursor.add(Duration(seconds: (entry.hours * 3600).round()));
    segments.add(RailSegment(type: _railTypeForLeave(entry.type), start: cursor, end: end));
    cursor = end;
  }

  return segments;
}

RailSegmentType _railTypeForLeave(LeaveType type) => switch (type) {
      LeaveType.vacation => RailSegmentType.vacation,
      LeaveType.sick => RailSegmentType.sick,
      LeaveType.flexDay => RailSegmentType.flex,
    };

EventChipRole _chipRoleForLeave(LeaveType type) => switch (type) {
      LeaveType.vacation => EventChipRole.vacation,
      LeaveType.sick => EventChipRole.sick,
      LeaveType.flexDay => EventChipRole.flex,
    };

String _leaveLabel(LeaveType type) => switch (type) {
      LeaveType.vacation => 'Vacation',
      LeaveType.sick => 'Sick',
      LeaveType.flexDay => 'Flex day',
    };

/// The day in order: a check-in dot, then a chip per block with a dot at every
/// boundary, then the live tail if anything is still running.
List<TimelineItem> _timeline({
  required List<TimelineBlock> blocks,
  required List<WorkSession> completed,
  required WorkSession? active,
  required List<LeaveEntry> leave,
  required TrackingState state,
  required DateTime? lastCheckOut,
  required DateTime now,
  void Function(WorkSession session)? onEditSession,
  VoidCallback? onDeleteSyntheticBreak,
}) {
  final items = <TimelineItem>[];

  if (blocks.isNotEmpty) {
    items.add(TimelineEvent(
      label: 'Check in',
      time: AppFormat.time(blocks.first.start),
      isCheckIn: true,
    ));

    for (final (i, block) in blocks.indexed) {
      final hours = block.duration.inSeconds / 3600.0;

      // A real break is a gap between two sessions, so it is bracketed by a
      // check-out and a check-in. A synthetic one was never left for, and gets
      // no dots — it sits inside the working stretch.
      if (block.type == TimelineBlockType.realBreak) {
        items.add(TimelineEvent(
          label: 'Check out',
          time: AppFormat.time(block.start),
          isCheckIn: false,
        ));
      }

      items.add(switch (block.type) {
        TimelineBlockType.work => TimelineChipItem(
            role: EventChipRole.work,
            label: 'Work session · ${AppFormat.hm(hours)}',
            onLongPress: onEditSession == null
                ? null
                : () {
                    for (final session in completed) {
                      if (session.id == block.id) {
                        onEditSession(session);
                        return;
                      }
                    }
                  },
          ),
        TimelineBlockType.realBreak => TimelineChipItem(
            role: EventChipRole.realBreak,
            label: 'Break · ${AppFormat.hm(hours)}',
          ),
        TimelineBlockType.syntheticBreak => TimelineChipItem(
            role: EventChipRole.syntheticBreak,
            label: 'Synthetic break · ${AppFormat.hm(hours)}',
            onDelete: onDeleteSyntheticBreak,
          ),
      });

      if (block.type == TimelineBlockType.realBreak && i + 1 < blocks.length) {
        items.add(TimelineEvent(
          label: 'Check in',
          time: AppFormat.time(block.end),
          isCheckIn: true,
        ));
      }
    }

    // A session that is running now, resumed after a gap: the gap is a break
    // that no row records, and the active row below stands in for its
    // check-in.
    if (active != null && active.startTime.isAfter(blocks.last.end)) {
      items.add(TimelineEvent(
        label: 'Check out',
        time: AppFormat.time(blocks.last.end),
        isCheckIn: false,
      ));
      items.add(TimelineChipItem(
        role: EventChipRole.realBreak,
        label:
            'Break · ${AppFormat.hm(active.startTime.difference(blocks.last.end).inSeconds / 3600.0)}',
      ));
    }
  }

  for (final entry in leave) {
    items.add(TimelineChipItem(
      role: _chipRoleForLeave(entry.type),
      label: '${_leaveLabel(entry.type)} · ${AppFormat.hm(entry.hours)}',
    ));
  }

  switch (state) {
    case TrackingState.tracking:
      items.add(TimelineActiveItem(
        state: state,
        label: 'Tracking since ${AppFormat.time(active!.startTime)}',
        chipLabel:
            'Work session · ${AppFormat.hm(now.difference(active.startTime).inSeconds / 3600.0)} so far',
      ));
    case TrackingState.onBreak:
      final elapsed = _nonNegative(now.difference(lastCheckOut!));
      items.add(TimelineActiveItem(
        state: state,
        label: 'On break since ${AppFormat.time(lastCheckOut)}',
        chipLabel: 'Break · ${AppFormat.hm(elapsed.inSeconds / 3600.0)} so far',
      ));
    case TrackingState.checkedOut:
      if (lastCheckOut != null) {
        items.add(TimelineEvent(
          label: 'Check out',
          time: AppFormat.time(lastCheckOut),
          isCheckIn: false,
        ));
      }
    case TrackingState.notStarted:
      break;
  }

  return items;
}
