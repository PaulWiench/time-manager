import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/color_space.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/lap_progress.dart';
import '../../domain/recalculation_engine.dart';
import '../../domain/timeline_builder.dart';
import '../../providers/balance_providers.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/edit_session_sheet.dart';
import '../../widgets/outlined_primary_button.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/timeline_chip.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onOpenSettings;

  const HomeScreen({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeSessionProvider).valueOrNull;

    // Ticks once a second only while a session is running, so the hero
    // timer, target bar, and stat cards stay live without polling when
    // idle.
    if (activeSession != null) {
      return StreamBuilder<int>(
        stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
        builder: (context, snapshot) => _HomeBody(
          now: DateTime.now(),
          activeSession: activeSession,
          onOpenSettings: onOpenSettings,
        ),
      );
    }
    return _HomeBody(
      now: DateTime.now(),
      activeSession: null,
      onOpenSettings: onOpenSettings,
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final DateTime now;
  final dynamic
  activeSession; // WorkSession?, kept dynamic to avoid importing the row type twice
  final VoidCallback onOpenSettings;

  const _HomeBody({
    required this.now,
    required this.activeSession,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final today = dateOnly(now);

    final settings = ref.watch(effectiveSettingsForProvider(today)).valueOrNull;
    final dayEntry = ref.watch(dayEntryForDateProvider(today)).valueOrNull;
    final sessions =
        ref.watch(sessionsForDateProvider(today)).valueOrNull ?? const [];
    final breaks =
        ref.watch(breaksForDateProvider(today)).valueOrNull ?? const [];
    final leave =
        ref.watch(leaveForDateProvider(today)).valueOrNull ?? const [];
    final balance = ref.watch(latestBalanceProvider).valueOrNull;

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targetHours =
        dayEntry?.targetHours ??
        computeTargetHours(
          date: today,
          workDays: settings.workDays,
          weeklyHours: settings.weeklyHours,
        );

    final isTracking = activeSession != null;
    final liveElapsed = isTracking
        ? now.difference(activeSession.startTime as DateTime)
        : null;
    final liveNetWorkedHours =
        (dayEntry?.netWorkedHours ?? 0) +
        (liveElapsed?.inSeconds ?? 0) / 3600.0;
    final targetRatio = targetHours > 0
        ? liveNetWorkedHours / targetHours
        : 0.0;
    final lap = lapProgressFor(targetRatio);
    final remaining = (targetHours - liveNetWorkedHours).clamp(
      0.0,
      double.infinity,
    );
    final balanceHours = balance?.balance ?? 0.0;

    // The ring is the sole fill indicator (no separate linear bar below it)
    // and ticks continuously with liveNetWorkedHours while tracking, rather
    // than only jumping on check-in/out. Past the daily target it keeps
    // lapping instead of stopping at 100%, darkening one step per extra lap
    // so overtime reads as "still filling," not "stuck full."
    final ringColor = darkenForLap(
      isTracking ? colors.accentFill : colors.idle,
      lap.lapIndex,
    );

    final completedIntervals = [
      for (final s in sessions)
        if (s.status == SessionStatus.completed && s.endTime != null)
          TimelineInterval(start: s.startTime, end: s.endTime!, id: s.id),
    ];
    final syntheticBreaks = [
      for (final b in breaks)
        if (b.type == BreakType.synthetic)
          TimelineSyntheticBreak(id: b.id, start: b.startTime, end: b.endTime),
    ];
    final blocks = buildDayTimeline(
      sessions: completedIntervals,
      syntheticBreaks: syntheticBreaks,
    );
    final hasAnyActivity = sessions.isNotEmpty || leave.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenPadding,
                14,
                AppSpace.screenPadding,
                4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TimeManager',
                        style: AppTextStyles.screenTitle.copyWith(
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormat.headerDate(now),
                        style: AppTextStyles.meta.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onOpenSettings,
                    child: PhosphorIcon(
                      PhosphorIconsRegular.gearSix,
                      size: 20,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  _toggleCheckInOut(context, ref, isTracking: isTracking),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ProgressRing(
                  size: 176,
                  strokeWidth: 10,
                  progress: lap.fraction,
                  color: ringColor,
                  trackColor: colors.divider,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTracking) ...[
                            _PulsingDot(color: colors.accentFill),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isTracking ? 'TRACKING' : 'CHECKED OUT',
                            style: AppTextStyles.metaMedium.copyWith(
                              color: isTracking
                                  ? colors.accentText
                                  : colors.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isTracking
                            ? AppFormat.hms(liveElapsed!)
                            : AppFormat.hm(liveNetWorkedHours),
                        style: AppTextStyles.heroNumber(
                          30,
                        ).copyWith(color: colors.text),
                      ),
                      Text(
                        isTracking
                            ? 'since ${AppFormat.time(activeSession.startTime as DateTime)}'
                            : 'today',
                        style: AppTextStyles.meta.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenPadding,
                6,
                AppSpace.screenPadding,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily target',
                    style: AppTextStyles.metaMedium.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${AppFormat.hm(liveNetWorkedHours)} / ${AppFormat.hm(targetHours)}',
                    style: AppTextStyles.metaMedium.copyWith(
                      color: colors.text,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenPadding,
                16,
                AppSpace.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Remaining today',
                      value: Text(
                        AppFormat.hm(remaining),
                        style: AppTextStyles.heroNumber(
                          20,
                        ).copyWith(color: colors.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Balance',
                      value: Text(
                        AppFormat.hm(balanceHours, signed: true),
                        style: AppTextStyles.heroNumber(
                          20,
                        ).copyWith(color: colors.accentText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screenPadding,
                20,
                AppSpace.screenPadding,
                6,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TODAY',
                  style: AppTextStyles.kickerSm.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: hasAnyActivity
                  ? _TodayTimeline(
                      blocks: blocks,
                      leave: leave,
                      sessions: sessions,
                      activeSession: isTracking ? activeSession : null,
                    )
                  : _EmptyState(
                      onCheckIn: () =>
                          _toggleCheckInOut(context, ref, isTracking: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCheckInOut(
    BuildContext context,
    WidgetRef ref, {
    required bool isTracking,
  }) async {
    final repo = ref.read(workSessionRepositoryProvider);
    if (isTracking) {
      await repo.checkOut(
        sessionId: activeSession.id as String,
        at: DateTime.now(),
      );
    } else {
      await repo.checkIn(DateTime.now());
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCheckIn;
  const _EmptyState({required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.playCircle,
              size: 34,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Nothing logged yet today',
              style: AppTextStyles.bodyLarge.copyWith(color: colors.text),
            ),
            const SizedBox(height: 18),
            OutlinedPrimaryButton(label: 'Check In', onPressed: onCheckIn),
          ],
        ),
      ),
    );
  }
}

class _TodayTimeline extends StatelessWidget {
  final List<TimelineBlock> blocks;
  final List<dynamic> leave; // List<LeaveEntry>
  final List<dynamic> sessions; // List<WorkSession>
  final dynamic activeSession; // WorkSession?

  const _TodayTimeline({
    required this.blocks,
    required this.leave,
    required this.sessions,
    required this.activeSession,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = <Widget>[];

    if (blocks.isNotEmpty) {
      // A dot for every check-in/out boundary, not just the first one — the
      // line connecting two dots is styled after the block that spans
      // them (solid accent for work, dashed break-color for a real break,
      // fine-dotted for a synthetic one), so the rail itself tells the
      // story before you even read a chip.
      items.add(
        _RailDot(
          time: AppFormat.time(blocks.first.start),
          label: 'Check in',
          dotColor: _segmentColor(colors, blocks.first.type),
          lineBelow: _lineStyleFor(colors, blocks.first.type),
        ),
      );

      for (var i = 0; i < blocks.length; i++) {
        final block = blocks[i];
        items.add(
          _RailContent(
            lineBelow: _lineStyleFor(colors, block.type),
            child: _chipForBlock(context, block),
          ),
        );

        final next = i + 1 < blocks.length ? blocks[i + 1] : null;
        if (next != null) {
          items.add(
            _RailDot(
              time: AppFormat.time(block.end),
              label: next.type == TimelineBlockType.work
                  ? 'Check in'
                  : 'Check out',
              dotColor: _segmentColor(colors, next.type),
              lineBelow: _lineStyleFor(colors, next.type),
            ),
          );
        } else if (activeSession == null) {
          items.add(
            _RailDot(
              time: AppFormat.time(block.end),
              label: 'Check out',
              dotColor: colors.idle,
              lineBelow: null,
              isLast: true,
            ),
          );
        } else if ((activeSession.startTime as DateTime).isAfter(block.end)) {
          // Still tracking, but not right where the last block left off —
          // the gap before resuming reads as its own break segment.
          final breakStyle = _RailLineStyle(
            color: colors.breakFill,
            dashed: true,
            dashLength: 6,
            gapLength: 4,
          );
          items.add(
            _RailDot(
              time: AppFormat.time(block.end),
              label: 'Check out',
              dotColor: colors.breakFill,
              lineBelow: breakStyle,
            ),
          );
          final breakHours =
              (activeSession.startTime as DateTime)
                  .difference(block.end)
                  .inMinutes /
              60.0;
          items.add(
            _RailContent(
              lineBelow: breakStyle,
              child: TimelineChip(
                role: ChipRole.realBreak,
                label: 'Break · ${AppFormat.hm(breakHours)}',
              ),
            ),
          );
        }
      }
    }

    if (activeSession != null) {
      items.add(
        _RailDot(
          time: null,
          label:
              'Tracking since ${AppFormat.time(activeSession.startTime as DateTime)}',
          dotColor: colors.accentFill,
          lineBelow: null,
          isLast: true,
          pulsing: true,
        ),
      );
    }

    for (final l in leave) {
      final type = l.type as LeaveType;
      final label = '${_leaveLabel(type)} · ${AppFormat.hm(l.hours as double)}';
      items.add(
        _RailContent(
          lineBelow: _RailLineStyle(color: colors.divider),
          child: TimelineChip(role: _chipRoleForLeave(type), label: label),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screenPadding,
        0,
        AppSpace.screenPadding,
        16,
      ),
      children: items,
    );
  }

  Widget _chipForBlock(BuildContext context, TimelineBlock block) {
    switch (block.type) {
      case TimelineBlockType.work:
        final chip = TimelineChip(
          role: ChipRole.work,
          label:
              'Work session · ${AppFormat.hm(block.duration.inMinutes / 60.0)}',
        );
        final matches = sessions.where((s) => s.id == block.id);
        if (matches.isEmpty) return chip;
        return GestureDetector(
          onTap: () => EditSessionSheet.show(context, matches.first),
          child: chip,
        );
      case TimelineBlockType.realBreak:
        return TimelineChip(
          role: ChipRole.realBreak,
          label: 'Break · ${AppFormat.hm(block.duration.inMinutes / 60.0)}',
        );
      case TimelineBlockType.syntheticBreak:
        return TimelineChip(
          role: ChipRole.syntheticBreak,
          label:
              'Synthetic break · ${AppFormat.hm(block.duration.inMinutes / 60.0)}',
          onDelete: () => _deleteSynthetic(context, block.start),
        );
    }
  }

  String _leaveLabel(LeaveType type) {
    switch (type) {
      case LeaveType.vacation:
        return 'Vacation';
      case LeaveType.sick:
        return 'Sick';
      case LeaveType.flexDay:
        return 'Flex day';
    }
  }

  ChipRole _chipRoleForLeave(LeaveType type) {
    switch (type) {
      case LeaveType.vacation:
        return ChipRole.vacation;
      case LeaveType.sick:
        return ChipRole.sick;
      case LeaveType.flexDay:
        return ChipRole.leave;
    }
  }

  void _deleteSynthetic(BuildContext context, DateTime date) {
    final container = ProviderScope.containerOf(context);
    container.read(workSessionRepositoryProvider).deleteSyntheticBreak(date);
  }
}

/// How the rail segment leading into the next dot/chip should render — a
/// solid line for a work block, a dashed one (color + rhythm both carrying
/// meaning) for a break. `null` means no line at all, i.e. this is the
/// bottom of the rail.
class _RailLineStyle {
  final Color color;
  final bool dashed;
  final double dashLength;
  final double gapLength;

  const _RailLineStyle({
    required this.color,
    this.dashed = false,
    this.dashLength = 5,
    this.gapLength = 4,
  });
}

_RailLineStyle _lineStyleFor(AppColors colors, TimelineBlockType type) {
  switch (type) {
    case TimelineBlockType.work:
      return _RailLineStyle(color: colors.accentFill);
    case TimelineBlockType.realBreak:
      return _RailLineStyle(
        color: colors.breakFill,
        dashed: true,
        dashLength: 6,
        gapLength: 4,
      );
    case TimelineBlockType.syntheticBreak:
      return _RailLineStyle(
        color: colors.textMuted,
        dashed: true,
        dashLength: 2,
        gapLength: 3,
      );
  }
}

/// The dot that opens a block's segment is colored the same as the line
/// below it, so the dot itself previews what kind of time is coming next.
Color _segmentColor(AppColors colors, TimelineBlockType type) {
  switch (type) {
    case TimelineBlockType.work:
      return colors.accentFill;
    case TimelineBlockType.realBreak:
      return colors.breakFill;
    case TimelineBlockType.syntheticBreak:
      return colors.textMuted;
  }
}

class _RailLine extends StatelessWidget {
  final _RailLineStyle? style;
  const _RailLine({required this.style});

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    if (style == null) return const SizedBox.shrink();
    if (!style.dashed) {
      return Container(
        width: 2.5,
        margin: const EdgeInsets.only(top: 2),
        color: style.color,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: CustomPaint(
        size: const Size(2.5, 10),
        painter: _DashedVerticalLinePainter(
          color: style.color,
          dashLength: style.dashLength,
          gapLength: style.gapLength,
        ),
      ),
    );
  }
}

class _DashedVerticalLinePainter extends CustomPainter {
  final Color color;
  final double dashLength;
  final double gapLength;

  _DashedVerticalLinePainter({
    required this.color,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      final yEnd = math.min(y + dashLength, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, yEnd), paint);
      y += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVerticalLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}

/// A single check-in/out event on the rail — a colored dot plus its clock
/// time, with the connecting line to whatever comes next living in the
/// same row so the two always move together.
class _RailDot extends StatelessWidget {
  final String? time;
  final String label;
  final Color dotColor;
  final _RailLineStyle? lineBelow;
  final bool isLast;
  final bool pulsing;

  const _RailDot({
    required this.time,
    required this.label,
    required this.dotColor,
    required this.lineBelow,
    this.isLast = false,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // IntrinsicHeight is load-bearing here, not decorative: a plain Row
    // inside a ListView gets an unbounded height from the scroll axis, so
    // the Expanded rail line below the dot has nothing to fill and
    // collapses to a sliver instead of reaching the next dot. Forcing an
    // intrinsic pass first gives the Row a real, bounded height (matching
    // the label/time text) that the line can actually stretch to fill.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                if (pulsing)
                  _PulsingDot(color: dotColor, size: 9)
                else
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (!isLast) Expanded(child: _RailLine(style: lineBelow)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(color: colors.text),
                  ),
                  if (time != null)
                    Text(
                      time!,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A block's content (chip) sitting between its two boundary dots, with
/// the rail continuing past it in the same style as the segment it's part
/// of — so the color/dash pattern reads as one continuous line, not a
/// dot-only affordance with plain gray in between.
class _RailContent extends StatelessWidget {
  final Widget child;
  final _RailLineStyle? lineBelow;
  const _RailContent({required this.child, required this.lineBelow});

  @override
  Widget build(BuildContext context) {
    // Same IntrinsicHeight requirement as _RailDot — see its comment.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [Expanded(child: _RailLine(style: lineBelow))],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, this.size = 7});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(
        begin: 1.0,
        end: 0.25,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.size,
        height: widget.size,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
