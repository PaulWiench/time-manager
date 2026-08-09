import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/recalculation_engine.dart';
import '../../domain/timeline_builder.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/timeline_chip.dart';

enum HistoryMode { month, week, day }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryMode _mode = HistoryMode.day;
  DateTime _anchor = dateOnly(DateTime.now());
  DateTime? _expandedDay;

  DateTime get _weekStart => _anchor.subtract(Duration(days: _anchor.weekday - 1));

  void _step(int direction) {
    setState(() {
      switch (_mode) {
        case HistoryMode.month:
        case HistoryMode.week:
          _anchor = DateTime(_anchor.year + direction, 1, 1);
        case HistoryMode.day:
          _anchor = _anchor.add(Duration(days: 7 * direction));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _step(-1),
                        child: PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 16, color: colors.textMuted),
                      ),
                      Row(
                        children: [
                          Text(_headerLabel(), style: AppTextStyles.body.copyWith(color: colors.text, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          PhosphorIcon(PhosphorIconsRegular.calendarBlank, size: 15, color: colors.accentText),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _step(1),
                        child: PhosphorIcon(PhosphorIconsRegular.caretRight, size: 16, color: colors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SegmentedControl(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                    colors: colors,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildList(colors)),
          ],
        ),
      ),
    );
  }

  String _headerLabel() {
    switch (_mode) {
      case HistoryMode.month:
      case HistoryMode.week:
        return _anchor.year.toString();
      case HistoryMode.day:
        return AppFormat.weekRange(_weekStart, _weekStart.add(const Duration(days: 6)));
    }
  }

  Widget _buildList(AppColors colors) {
    switch (_mode) {
      case HistoryMode.month:
        return _MonthList(year: _anchor.year, onTapMonth: _drillToWeek);
      case HistoryMode.week:
        return _WeekList(year: _anchor.year, onTapWeek: _drillToDay);
      case HistoryMode.day:
        return _DayList(
          weekStart: _weekStart,
          expandedDay: _expandedDay,
          onToggle: (d) => setState(() => _expandedDay = _expandedDay == d ? null : d),
        );
    }
  }

  void _drillToWeek(DateTime monthStart) {
    setState(() {
      _mode = HistoryMode.week;
      _anchor = monthStart;
    });
  }

  void _drillToDay(DateTime weekStart) {
    setState(() {
      _mode = HistoryMode.day;
      _anchor = weekStart;
    });
  }
}

class _SegmentedControl extends StatelessWidget {
  final HistoryMode mode;
  final ValueChanged<HistoryMode> onChanged;
  final AppColors colors;

  const _SegmentedControl({required this.mode, required this.onChanged, required this.colors});

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, HistoryMode value, {bool first = false}) {
      final on = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: on ? colors.accentTint : null,
              border: first ? null : Border(left: BorderSide(color: colors.divider)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.metaMedium.copyWith(
                color: on ? colors.accentText : colors.textMuted,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          segment('Month', HistoryMode.month, first: true),
          segment('Week', HistoryMode.week),
          segment('Day', HistoryMode.day),
        ],
      ),
    );
  }
}

class _MonthList extends ConsumerWidget {
  final int year;
  final ValueChanged<DateTime> onTapMonth;
  const _MonthList({required this.year, required this.onTapMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final lastMonth = year == now.year ? now.month : 12;
    if (year > now.year) return const SizedBox.shrink();
    final months = [for (var m = lastMonth; m >= 1; m--) DateTime(year, m, 1)];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 0, AppSpace.screenPadding, 16),
      itemCount: months.length,
      itemBuilder: (context, i) {
        final start = months[i];
        final end = DateTime(start.year, start.month + 1, 1);
        final entries = ref.watch(dayEntriesInRangeProvider(start, end)).valueOrNull ?? const [];
        final hours = entries.fold<double>(0, (a, e) => a + e.netWorkedHours);
        final delta = entries.fold<double>(0, (a, e) => a + e.balanceDelta);
        return _RangeRow(
          label: AppFormat.monthYear(start),
          hours: hours,
          delta: delta,
          onTap: () => onTapMonth(start),
        );
      },
    );
  }
}

class _WeekList extends ConsumerWidget {
  final int year;
  final ValueChanged<DateTime> onTapWeek;
  const _WeekList({required this.year, required this.onTapWeek});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = dateOnly(DateTime.now());
    final jan1 = DateTime(year, 1, 1);
    final firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));
    final lastMonday = year == now.year ? now.subtract(Duration(days: now.weekday - 1)) : DateTime(year, 12, 31 - 6);

    final weeks = <DateTime>[];
    for (var d = firstMonday; !d.isAfter(lastMonday); d = d.add(const Duration(days: 7))) {
      if (d.year == year || d.add(const Duration(days: 6)).year == year) weeks.add(d);
    }
    final ordered = weeks.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 0, AppSpace.screenPadding, 16),
      itemCount: ordered.length,
      itemBuilder: (context, i) {
        final start = ordered[i];
        final end = start.add(const Duration(days: 7));
        final entries = ref.watch(dayEntriesInRangeProvider(start, end)).valueOrNull ?? const [];
        final hours = entries.fold<double>(0, (a, e) => a + e.netWorkedHours);
        final delta = entries.fold<double>(0, (a, e) => a + e.balanceDelta);
        return _RangeRow(
          label: AppFormat.weekRange(start, start.add(const Duration(days: 6))),
          hours: hours,
          delta: delta,
          onTap: () => onTapWeek(start),
        );
      },
    );
  }
}

class _RangeRow extends StatelessWidget {
  final String label;
  final double hours;
  final double delta;
  final VoidCallback onTap;

  const _RangeRow({required this.label, required this.hours, required this.delta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge.copyWith(color: colors.text)),
                const SizedBox(height: 2),
                Text('${AppFormat.hm(hours)} worked', style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
              ],
            ),
            Row(
              children: [
                Text(AppFormat.hm(delta, signed: true), style: AppTextStyles.heroNumber(13).copyWith(color: colors.accentText)),
                const SizedBox(width: 10),
                PhosphorIcon(PhosphorIconsRegular.caretRight, size: 14, color: colors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _DayStatus { normal, missed, rest, scheduled, today }

class _DayList extends ConsumerWidget {
  final DateTime weekStart;
  final DateTime? expandedDay;
  final ValueChanged<DateTime> onToggle;

  const _DayList({required this.weekStart, required this.expandedDay, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    final days = [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 0, AppSpace.screenPadding, 16),
      children: [
        for (final d in days) _DayRowConsumer(date: d, today: today, expanded: expandedDay == d, onToggle: () => onToggle(d)),
      ],
    );
  }
}

class _DayRowConsumer extends ConsumerWidget {
  final DateTime date;
  final DateTime today;
  final bool expanded;
  final VoidCallback onToggle;

  const _DayRowConsumer({required this.date, required this.today, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final dayEntry = ref.watch(dayEntryForDateProvider(date)).valueOrNull;
    final settings = ref.watch(effectiveSettingsForProvider(date)).valueOrNull;

    if (dayEntry != null) {
      return _ExpandableDayRow(
        date: date,
        dayEntry: dayEntry,
        expanded: expanded,
        onToggle: onToggle,
      );
    }

    final isWorkDay = settings?.workDays.contains(date.weekday) ?? false;
    late final _DayStatus status;
    if (!isWorkDay) {
      status = _DayStatus.rest;
    } else if (date.isAfter(today)) {
      status = _DayStatus.scheduled;
    } else if (date.isAtSameMomentAs(today)) {
      status = _DayStatus.today;
    } else {
      status = _DayStatus.missed;
    }

    final target = settings == null
        ? 0.0
        : computeTargetHours(date: date, workDays: settings.workDays, weeklyHours: settings.weeklyHours);

    switch (status) {
      case _DayStatus.rest:
        return Opacity(
          opacity: 0.5,
          child: _SimpleDayRow(date: date, subtitle: 'Rest day', delta: null, colors: colors),
        );
      case _DayStatus.scheduled:
        return _SimpleDayRow(date: date, subtitle: 'Scheduled', delta: null, colors: colors);
      case _DayStatus.today:
        return _SimpleDayRow(date: date, subtitle: '0:00 worked', delta: null, colors: colors);
      case _DayStatus.missed:
        return _SimpleDayRow(
          date: date,
          subtitle: 'No entry',
          delta: -target,
          colors: colors,
          warning: true,
        );
      case _DayStatus.normal:
        return const SizedBox.shrink();
    }
  }
}

class _SimpleDayRow extends StatelessWidget {
  final DateTime date;
  final String subtitle;
  final double? delta;
  final AppColors colors;
  final bool warning;

  const _SimpleDayRow({required this.date, required this.subtitle, required this.delta, required this.colors, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final textColor = warning ? colors.warningText : colors.text;
    final subColor = warning ? colors.warningText : colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (warning) ...[
                Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.warningFill, shape: BoxShape.circle)),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppFormat.dayRow(date), style: AppTextStyles.body.copyWith(color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.meta.copyWith(color: subColor, fontSize: 11)),
                ],
              ),
            ],
          ),
          Text(
            delta == null ? '—' : AppFormat.hm(delta!, signed: true),
            style: AppTextStyles.heroNumber(13).copyWith(color: warning ? colors.warningText : colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDayRow extends ConsumerWidget {
  final DateTime date;
  final DayEntry dayEntry;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableDayRow({required this.date, required this.dayEntry, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (!expanded) {
      return InkWell(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppFormat.dayRow(date), style: AppTextStyles.body.copyWith(color: colors.text)),
                  const SizedBox(height: 2),
                  Text('${AppFormat.hm(dayEntry.netWorkedHours)} worked', style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
                ],
              ),
              Text(AppFormat.hm(dayEntry.balanceDelta, signed: true), style: AppTextStyles.heroNumber(13).copyWith(color: colors.accentText)),
            ],
          ),
        ),
      );
    }

    final sessions = ref.watch(sessionsForDateProvider(date)).valueOrNull ?? const [];
    final breaks = ref.watch(breaksForDateProvider(date)).valueOrNull ?? const [];
    final leave = ref.watch(leaveForDateProvider(date)).valueOrNull ?? const [];

    final completedIntervals = [
      for (final s in sessions)
        if (s.status == SessionStatus.completed && s.endTime != null) TimelineInterval(start: s.startTime, end: s.endTime!),
    ];
    final syntheticBreaks = [
      for (final b in breaks)
        if (b.type == BreakType.synthetic) TimelineSyntheticBreak(id: b.id, start: b.startTime, end: b.endTime),
    ];
    final blocks = buildDayTimeline(sessions: completedIntervals, syntheticBreaks: syntheticBreaks);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppFormat.dayRow(date), style: AppTextStyles.heroNumber(14).copyWith(color: colors.text)),
                    const SizedBox(height: 2),
                    Text('${AppFormat.hm(dayEntry.netWorkedHours)} worked', style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    Text(AppFormat.hm(dayEntry.balanceDelta, signed: true), style: AppTextStyles.heroNumber(13).copyWith(color: colors.accentText)),
                    const SizedBox(width: 8),
                    PhosphorIcon(PhosphorIconsRegular.caretUp, size: 14, color: colors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in blocks) _chipFor(context, ref, b),
              for (final l in leave)
                TimelineChip(role: ChipRole.leave, label: '${_leaveLabel(l.type)} · ${AppFormat.hm(l.hours)}'),
            ],
          ),
          if (dayEntry.notes != null && dayEntry.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"${dayEntry.notes}"', style: AppTextStyles.bodyRegular.copyWith(color: colors.textMuted, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _chipFor(BuildContext context, WidgetRef ref, TimelineBlock b) {
    switch (b.type) {
      case TimelineBlockType.work:
        return TimelineChip(role: ChipRole.work, label: 'Work · ${AppFormat.time(b.start)} – ${AppFormat.time(b.end)}');
      case TimelineBlockType.realBreak:
        return TimelineChip(role: ChipRole.realBreak, label: 'Break · ${AppFormat.time(b.start)} – ${AppFormat.time(b.end)}');
      case TimelineBlockType.syntheticBreak:
        return TimelineChip(
          role: ChipRole.syntheticBreak,
          label: 'Synthetic break · ${AppFormat.time(b.start)} – ${AppFormat.time(b.end)}',
          onDelete: () => ref.read(workSessionRepositoryProvider).deleteSyntheticBreak(date),
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
}
