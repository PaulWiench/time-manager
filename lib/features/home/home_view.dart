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
import '../../domain/day_settlement.dart';
import '../../domain/midnight_cutoff.dart';
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
    required this.balanceProvisional,
    required this.balanceWarning,
    required this.netHours,
    required this.targetHours,
    required this.ringProgress,
    required this.timerText,
    required this.sinceText,
    required this.rail,
    required this.leaveHours,
    required this.timeline,
    required this.hasActivity,
    this.leaveConflict,
  });

  /// `Tue 22 Sep`.
  final String dateLabel;

  final TrackingState state;

  /// Everything settled before today, plus whatever today has *earned* —
  /// see `lib/domain/day_settlement.dart`. It does not tick second by second,
  /// and it never counts down while the day is still being worked.
  final double balanceHours;

  /// True while today is still open and behind its target, i.e. while
  /// [balanceHours] is deliberately holding back a shortfall that will land
  /// once the day is over. The caption under the balance says so, because a
  /// number that quietly declines to move is worse than one that explains why.
  final bool balanceProvisional;

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

  /// Leave credited to the day. Kept apart from [netHours], which the ring and
  /// the centre figure use, because those two say how much was *worked*.
  final double leaveHours;

  final List<TimelineItem> timeline;

  /// False only on a day with nothing logged at all, which gets the empty
  /// state instead of a timeline.
  final bool hasActivity;

  /// Set only when leave and work together overshoot the day's target.
  ///
  /// Half a day off plus half a day worked is an ordinary day and says nothing.
  /// But the balance is `netHours + leaveHours - targetHours`, so once the two
  /// add up to more than the target the overshoot is credited twice — which is
  /// exactly what a leave entry left over from a plan that changed does, and it
  /// does it silently. The arithmetic is not second-guessed here; the
  /// contradiction is put on screen next to the number it moved.
  final LeaveConflict? leaveConflict;

  /// Remaining, or surplus when over — the design wants the honest number, not
  /// a remaining clamped to zero.
  ///
  /// Leave counts towards the day being done, exactly as the balance counts it.
  /// A full vacation day used to read "0:00 of 7:54 · 7:54 left" on a day the
  /// engine had already settled at zero.
  double get remainingHours => targetHours - netHours - leaveHours;
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

  final leaveHours = leave.fold<double>(0, (sum, l) => sum + l.hours);

  // `balance` is the last *settled* snapshot — everything up to yesterday.
  // Today is added live, and only if it helps: a day still being worked is
  // assumed to be heading for its target, so it cannot pull the number down
  // until it is genuinely over.
  final settled = balance?.balance ?? 0.0;
  final todayDelta = netHours + leaveHours - targetHours;
  final finished = dayIsFinished(
    now: now,
    day: today,
    hasActiveSession: active != null,
    lastCheckOut: lastCheckOut,
    workWindow: TimeOfDayWindow(
      startMinutes: settings.workWindowStartMinutes,
      endMinutes: settings.workWindowEndMinutes,
    ),
  );
  final balanceHours = settled + todayContribution(delta: todayDelta, finished: finished);

  return HomeView(
    dateLabel: AppFormat.headerDate(now),
    state: state,
    balanceHours: balanceHours,
    balanceProvisional: !finished && todayDelta < 0,
    balanceWarning: balanceBeyondBounds(
      balanceHours,
      floorHours: settings.balanceFloorHours,
      capHours: settings.balanceCapHours,
    ),
    netHours: netHours,
    targetHours: targetHours,
    ringProgress: targetHours > 0 ? netHours / targetHours : 0,
    // One clock for the day, not one per session.
    //
    // This used to switch between three unrelated origins — elapsed since the
    // current session's start while tracking, elapsed since the last check-out
    // while on break, the day's net when idle. Since a break is modelled as
    // check-out then check-in, both anchors moved to "now" at each boundary,
    // so the big figure reset to zero twice per break. Taking lunch made the
    // morning disappear.
    //
    // It is today's worked total in every state now: it ticks while a session
    // is running, holds while one is not, and never goes backwards. The break
    // clock is not lost, only demoted to the caption below.
    timerText: state == TrackingState.tracking
        ? AppFormat.hms(_asDuration(netHours))
        : AppFormat.hm(netHours),
    sinceText: switch (state) {
      // The *first* check-in, to match the figure above it. Naming the current
      // session's start next to a whole-day total would be two answers to the
      // same question.
      TrackingState.tracking =>
        'since ${AppFormat.time(blocks.isEmpty ? active!.startTime : blocks.first.start)}',
      TrackingState.onBreak =>
        'on break ${AppFormat.hm(_nonNegative(now.difference(lastCheckOut!)).inSeconds / 3600)}',
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
    leaveHours: leaveHours,
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
    leaveConflict: _leaveConflict(
      leave: leave,
      netHours: netHours,
      targetHours: targetHours,
    ),
  );
}

class LeaveConflict {
  const LeaveConflict({required this.headline, required this.detail});

  /// `Worked 5:49 on a vacation day`.
  final String headline;

  /// `5:49 of today's balance is counted twice`.
  final String detail;
}

LeaveConflict? _leaveConflict({
  required List<LeaveEntry> leave,
  required double netHours,
  required double targetHours,
}) {
  if (leave.isEmpty || netHours <= 0) return null;
  final leaveHours = leave.fold<double>(0, (sum, l) => sum + l.hours);
  final overlap = netHours + leaveHours - targetHours;
  // A minute of slop: a half day off plus a half day worked lands on the
  // target and is not a contradiction.
  if (overlap <= 1 / 60) return null;

  return LeaveConflict(
    headline: 'Worked ${AppFormat.hm(netHours)} on a '
        '${_leaveNoun(_dominantLeave(leave).type)} day',
    detail: '${AppFormat.hm(overlap)} of it is counted twice in the balance',
  );
}

/// The entry that best describes the day, when more than one was recorded for
/// it — the longest one.
LeaveEntry _dominantLeave(List<LeaveEntry> leave) =>
    leave.reduce((a, b) => b.hours > a.hours ? b : a);

String _leaveNoun(LeaveType type) => switch (type) {
      LeaveType.vacation => 'vacation',
      LeaveType.sick => 'sick',
      LeaveType.flexDay => 'flex',
    };

Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

/// Hours back into a Duration, so the day's total can be rendered by the same
/// `h:mm:ss` formatter a stopwatch uses.
Duration _asDuration(double hours) =>
    Duration(milliseconds: (hours * 3600 * 1000).round());

double _hoursOf(DateTime start, DateTime end) =>
    end.difference(start).inSeconds / 3600.0;

/// The day in order, as lengths rather than clock times.
///
/// Leave goes on the end, because it is stored as a number of hours with no
/// clock times of its own and an invented 09:00–13:00 would be a lie. It used
/// to be given a stretch of wall-clock axis for the same reason, which is what
/// made the axis grow by a whole extra target on a day that carried both.
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
        hours: _hoursOf(block.start, block.end),
      ),
  ];

  if (active != null) {
    // The gap between the last block and a session that resumed later is a
    // break, even though no break row exists for it yet.
    if (blocks.isNotEmpty && active.startTime.isAfter(blocks.last.end)) {
      segments.add(RailSegment(
        type: RailSegmentType.realBreak,
        hours: _hoursOf(blocks.last.end, active.startTime),
      ));
    }
    segments.add(RailSegment(
      type: RailSegmentType.work,
      hours: _hoursOf(active.startTime, now),
    ));
  } else if (state == TrackingState.onBreak && lastCheckOut != null) {
    // The break in progress has no row of its own — a break is only ever the
    // gap between two sessions — but it is the thing currently happening, so
    // the rail has to show it.
    segments.add(RailSegment(
      type: RailSegmentType.realBreak,
      hours: _hoursOf(lastCheckOut, now),
    ));
  }

  for (final entry in leave) {
    segments.add(
      RailSegment(type: _railTypeForLeave(entry.type), hours: entry.hours),
    );
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
