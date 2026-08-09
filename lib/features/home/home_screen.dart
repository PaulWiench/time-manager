import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/recalculation_engine.dart';
import '../../domain/timeline_builder.dart';
import '../../providers/balance_providers.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';
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
        builder: (context, snapshot) => _HomeBody(now: DateTime.now(), activeSession: activeSession, onOpenSettings: onOpenSettings),
      );
    }
    return _HomeBody(now: DateTime.now(), activeSession: null, onOpenSettings: onOpenSettings);
  }
}

class _HomeBody extends ConsumerWidget {
  final DateTime now;
  final dynamic activeSession; // WorkSession?, kept dynamic to avoid importing the row type twice
  final VoidCallback onOpenSettings;

  const _HomeBody({required this.now, required this.activeSession, required this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final today = dateOnly(now);

    final settings = ref.watch(effectiveSettingsForProvider(today)).valueOrNull;
    final dayEntry = ref.watch(dayEntryForDateProvider(today)).valueOrNull;
    final sessions = ref.watch(sessionsForDateProvider(today)).valueOrNull ?? const [];
    final breaks = ref.watch(breaksForDateProvider(today)).valueOrNull ?? const [];
    final leave = ref.watch(leaveForDateProvider(today)).valueOrNull ?? const [];
    final balance = ref.watch(latestBalanceProvider).valueOrNull;

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targetHours = dayEntry?.targetHours ??
        computeTargetHours(date: today, workDays: settings.workDays, weeklyHours: settings.weeklyHours);

    final isTracking = activeSession != null;
    final liveElapsed = isTracking ? now.difference(activeSession.startTime as DateTime) : null;
    final liveNetWorkedHours = (dayEntry?.netWorkedHours ?? 0) + (liveElapsed?.inSeconds ?? 0) / 3600.0;
    final ringProgress = targetHours > 0 ? (liveNetWorkedHours / targetHours).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetHours - liveNetWorkedHours).clamp(0.0, double.infinity);
    final balanceHours = balance?.balance ?? 0.0;

    final ringColor = isTracking ? colors.accentFill : colors.idle;

    final completedIntervals = [
      for (final s in sessions)
        if (s.status == SessionStatus.completed && s.endTime != null)
          TimelineInterval(start: s.startTime, end: s.endTime!),
    ];
    final syntheticBreaks = [
      for (final b in breaks)
        if (b.type == BreakType.synthetic) TimelineSyntheticBreak(id: b.id, start: b.startTime, end: b.endTime),
    ];
    final blocks = buildDayTimeline(sessions: completedIntervals, syntheticBreaks: syntheticBreaks);
    final hasAnyActivity = sessions.isNotEmpty || leave.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TimeManager', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
                      const SizedBox(height: 2),
                      Text(AppFormat.headerDate(now), style: AppTextStyles.meta.copyWith(color: colors.textMuted)),
                    ],
                  ),
                  GestureDetector(
                    onTap: onOpenSettings,
                    child: PhosphorIcon(PhosphorIconsRegular.gearSix, size: 20, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleCheckInOut(context, ref, isTracking: isTracking),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ProgressRing(
                  size: 176,
                  strokeWidth: 10,
                  progress: ringProgress,
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
                              color: isTracking ? colors.accentText : colors.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isTracking ? AppFormat.hms(liveElapsed!) : AppFormat.hm(liveNetWorkedHours),
                        style: AppTextStyles.heroNumber(30).copyWith(color: colors.text),
                      ),
                      Text(
                        isTracking ? 'since ${AppFormat.time(activeSession.startTime as DateTime)}' : 'today',
                        style: AppTextStyles.meta.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 6, AppSpace.screenPadding, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daily target', style: AppTextStyles.metaMedium.copyWith(color: colors.textMuted, fontSize: 12)),
                      Text(
                        '${AppFormat.hm(liveNetWorkedHours)} / ${AppFormat.hm(targetHours)}',
                        style: AppTextStyles.metaMedium.copyWith(color: colors.text, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ringProgress,
                      minHeight: 6,
                      backgroundColor: colors.divider,
                      valueColor: AlwaysStoppedAnimation(colors.accentFill),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 16, AppSpace.screenPadding, 0),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Remaining today',
                      value: Text(AppFormat.hm(remaining), style: AppTextStyles.heroNumber(20).copyWith(color: colors.text)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Balance',
                      value: Text(
                        AppFormat.hm(balanceHours, signed: true),
                        style: AppTextStyles.heroNumber(20).copyWith(color: colors.accentText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 20, AppSpace.screenPadding, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('TODAY', style: AppTextStyles.kickerSm.copyWith(color: colors.textMuted)),
              ),
            ),
            Expanded(
              child: hasAnyActivity
                  ? _TodayTimeline(
                      blocks: blocks,
                      leave: leave,
                      activeSession: isTracking ? activeSession : null,
                    )
                  : _EmptyState(onCheckIn: () => _toggleCheckInOut(context, ref, isTracking: false)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCheckInOut(BuildContext context, WidgetRef ref, {required bool isTracking}) async {
    final repo = ref.read(workSessionRepositoryProvider);
    if (isTracking) {
      await repo.checkOut(sessionId: activeSession.id as String, at: DateTime.now());
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
            PhosphorIcon(PhosphorIconsRegular.playCircle, size: 34, color: colors.textMuted),
            const SizedBox(height: 12),
            Text('Nothing logged yet today', style: AppTextStyles.bodyLarge.copyWith(color: colors.text)),
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
  final dynamic activeSession; // WorkSession?

  const _TodayTimeline({required this.blocks, required this.leave, required this.activeSession});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = <Widget>[];

    if (blocks.isNotEmpty) {
      items.add(_DotRow(
        time: AppFormat.time(blocks.first.start),
        label: 'Check in',
        colors: colors,
        pulsing: false,
        isLast: false,
      ));
      for (final block in blocks) {
        items.add(_ChipRow(colors: colors, child: _chipForBlock(context, block)));
      }
    }

    if (activeSession != null) {
      items.add(_DotRow(
        time: null,
        label: 'Tracking since ${AppFormat.time(activeSession.startTime as DateTime)}',
        colors: colors,
        pulsing: true,
        isLast: true,
      ));
    }

    for (final l in leave) {
      final label = '${_leaveLabel(l.type as LeaveType)} · ${AppFormat.hm(l.hours as double)}';
      items.add(_ChipRow(colors: colors, child: TimelineChip(role: ChipRole.leave, label: label)));
    }

    return ListView(padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 0, AppSpace.screenPadding, 16), children: items);
  }

  Widget _chipForBlock(BuildContext context, TimelineBlock block) {
    switch (block.type) {
      case TimelineBlockType.work:
        return TimelineChip(role: ChipRole.work, label: 'Work session · ${AppFormat.hm(block.duration.inMinutes / 60.0)}');
      case TimelineBlockType.realBreak:
        return TimelineChip(role: ChipRole.realBreak, label: 'Break · ${AppFormat.hm(block.duration.inMinutes / 60.0)}');
      case TimelineBlockType.syntheticBreak:
        return TimelineChip(
          role: ChipRole.syntheticBreak,
          label: 'Synthetic break · ${AppFormat.hm(block.duration.inMinutes / 60.0)}',
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

  void _deleteSynthetic(BuildContext context, DateTime date) {
    final container = ProviderScope.containerOf(context);
    container.read(workSessionRepositoryProvider).deleteSyntheticBreak(date);
  }
}

class _DotRow extends StatelessWidget {
  final String? time;
  final String label;
  final AppColors colors;
  final bool pulsing;
  final bool isLast;

  const _DotRow({required this.time, required this.label, required this.colors, required this.pulsing, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Column(
            children: [
              if (pulsing)
                _PulsingDot(color: colors.accentFill, size: 9)
              else
                Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: colors.accentFill, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: colors.divider, margin: const EdgeInsets.only(top: 2))),
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
                Text(time == null ? label : 'Check in', style: AppTextStyles.body.copyWith(color: colors.text)),
                if (time != null) Text(time!, style: AppTextStyles.body.copyWith(color: colors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  final Widget child;
  final AppColors colors;
  const _ChipRow({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Column(
            children: [Expanded(child: Container(width: 2, color: colors.divider))],
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

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.25).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.size,
        height: widget.size,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
