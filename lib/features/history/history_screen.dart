import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
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
import '../../widgets/edit_session_sheet.dart';
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

  DateTime get _weekStart => shiftDays(_anchor, -(_anchor.weekday - 1));

  void _step(int direction) {
    setState(() {
      switch (_mode) {
        case HistoryMode.month:
        case HistoryMode.week:
          _anchor = DateTime(_anchor.year + direction, 1, 1);
        case HistoryMode.day:
          _anchor = shiftDays(_anchor, 7 * direction);
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
                        child: Icon(AppIcons.caretLeft, size: 16, color: colors.textMuted),
                      ),
                      Row(
                        children: [
                          Text(_headerLabel(), style: AppTextStyles.body.copyWith(color: colors.text, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          Icon(AppIcons.calendarBlank, size: 15, color: colors.accentText),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _step(1),
                        child: Icon(AppIcons.caretRight, size: 16, color: colors.textMuted),
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
        return AppFormat.weekRange(_weekStart, shiftDays(_weekStart, 6));
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
    final firstMonday = shiftDays(jan1, -(jan1.weekday - 1));
    final lastMonday = year == now.year ? shiftDays(now, -(now.weekday - 1)) : DateTime(year, 12, 31 - 6);

    final weeks = <DateTime>[];
    for (var d = firstMonday; !d.isAfter(lastMonday); d = shiftDays(d, 7)) {
      if (d.year == year || shiftDays(d, 6).year == year) weeks.add(d);
    }
    final ordered = weeks.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 0, AppSpace.screenPadding, 16),
      itemCount: ordered.length,
      itemBuilder: (context, i) {
        final start = ordered[i];
        final end = shiftDays(start, 7);
        final entries = ref.watch(dayEntriesInRangeProvider(start, end)).valueOrNull ?? const [];
        final hours = entries.fold<double>(0, (a, e) => a + e.netWorkedHours);
        final delta = entries.fold<double>(0, (a, e) => a + e.balanceDelta);
        return _RangeRow(
          label: AppFormat.weekRange(start, shiftDays(start, 6)),
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
                Icon(AppIcons.caretRight, size: 14, color: colors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _DayStatus { normal, missed, rest, scheduled, today, holiday }

/// A day's category for History's background-tint color-coding — holiday
/// takes priority over leave (Requirements § 4: a holiday landing on a
/// leave day still shows as a holiday), and among leave types the more
/// "unplanned" ones surface first when a day somehow has more than one.
enum _DayCategory { holiday, sick, vacation, flexDay, missed, normal }

class _CategoryStyle {
  final Color? background;
  final Color text;
  final Color subtitle;
  const _CategoryStyle({this.background, required this.text, required this.subtitle});
}

_CategoryStyle _styleFor(AppColors colors, _DayCategory category) {
  switch (category) {
    case _DayCategory.holiday:
      return _CategoryStyle(background: colors.holidayTint, text: colors.holidayText, subtitle: colors.holidayText);
    case _DayCategory.sick:
      return _CategoryStyle(background: colors.sickTint, text: colors.sickText, subtitle: colors.sickText);
    case _DayCategory.vacation:
      return _CategoryStyle(background: colors.vacationTint, text: colors.vacationText, subtitle: colors.vacationText);
    case _DayCategory.flexDay:
      return _CategoryStyle(background: colors.surface2, text: colors.text, subtitle: colors.textMuted);
    case _DayCategory.missed:
      return _CategoryStyle(background: colors.warningTint, text: colors.warningText, subtitle: colors.warningText);
    case _DayCategory.normal:
      return _CategoryStyle(background: null, text: colors.text, subtitle: colors.textMuted);
  }
}

_DayCategory _categoryForLeaveAndHoliday(List<LeaveEntry> leave, PublicHoliday? holiday) {
  if (holiday != null) return _DayCategory.holiday;
  if (leave.any((l) => l.type == LeaveType.sick)) return _DayCategory.sick;
  if (leave.any((l) => l.type == LeaveType.vacation)) return _DayCategory.vacation;
  if (leave.any((l) => l.type == LeaveType.flexDay)) return _DayCategory.flexDay;
  return _DayCategory.normal;
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

class _DayList extends ConsumerWidget {
  final DateTime weekStart;
  final DateTime? expandedDay;
  final ValueChanged<DateTime> onToggle;

  const _DayList({required this.weekStart, required this.expandedDay, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    final days = [for (var i = 0; i < 7; i++) shiftDays(weekStart, i)];

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
    final holiday = ref.watch(publicHolidayForDateProvider(date)).valueOrNull;

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
    if (holiday != null) {
      status = _DayStatus.holiday;
    } else if (!isWorkDay) {
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
        : computeTargetHours(
            date: date,
            workDays: settings.workDays,
            weeklyHours: settings.weeklyHours,
            holidayFraction: holiday?.fraction,
          );

    switch (status) {
      case _DayStatus.holiday:
        return _SimpleDayRow(date: date, subtitle: holiday!.name, delta: -target, colors: colors, category: _DayCategory.holiday);
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
          category: _DayCategory.missed,
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
  final _DayCategory category;

  const _SimpleDayRow({required this.date, required this.subtitle, required this.delta, required this.colors, this.category = _DayCategory.normal});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(colors, category);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: style.background != null ? BorderRadius.circular(AppRadius.md) : null,
        border: style.background == null ? Border(bottom: BorderSide(color: colors.divider)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppFormat.dayRow(date), style: AppTextStyles.body.copyWith(color: style.text)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.meta.copyWith(color: style.subtitle, fontSize: 11)),
            ],
          ),
          Text(
            delta == null ? '—' : AppFormat.hm(delta!, signed: true),
            style: AppTextStyles.heroNumber(13).copyWith(color: style.subtitle),
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
    final leave = ref.watch(leaveForDateProvider(date)).valueOrNull ?? const [];
    final holiday = ref.watch(publicHolidayForDateProvider(date)).valueOrNull;
    final category = _categoryForLeaveAndHoliday(leave, holiday);
    final style = _styleFor(colors, category);

    if (!expanded) {
      return InkWell(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: style.background != null ? BorderRadius.circular(AppRadius.md) : null,
            border: style.background == null ? Border(bottom: BorderSide(color: colors.divider)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppFormat.dayRow(date), style: AppTextStyles.body.copyWith(color: style.text)),
                      if (dayEntry.autoBreakOverridden) ...[
                        const SizedBox(width: 5),
                        _RetroactiveEditBadge(colors: colors),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${AppFormat.hm(dayEntry.netWorkedHours)} worked', style: AppTextStyles.meta.copyWith(color: style.subtitle, fontSize: 11)),
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

    final completedIntervals = [
      for (final s in sessions)
        if (s.status == SessionStatus.completed && s.endTime != null)
          TimelineInterval(start: s.startTime, end: s.endTime!, id: s.id),
    ];
    final syntheticBreaks = [
      for (final b in breaks)
        if (b.type == BreakType.synthetic) TimelineSyntheticBreak(id: b.id, start: b.startTime, end: b.endTime),
    ];
    final blocks = buildDayTimeline(sessions: completedIntervals, syntheticBreaks: syntheticBreaks);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: style.background ?? colors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
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
                    Row(
                      children: [
                        Text(AppFormat.dayRow(date), style: AppTextStyles.heroNumber(14).copyWith(color: colors.text)),
                        if (dayEntry.autoBreakOverridden) ...[
                          const SizedBox(width: 6),
                          _RetroactiveEditBadge(colors: colors),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${AppFormat.hm(dayEntry.netWorkedHours)} worked', style: AppTextStyles.meta.copyWith(color: colors.textMuted, fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    Text(AppFormat.hm(dayEntry.balanceDelta, signed: true), style: AppTextStyles.heroNumber(13).copyWith(color: colors.accentText)),
                    const SizedBox(width: 8),
                    Icon(AppIcons.caretUp, size: 14, color: colors.textMuted),
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
              if (holiday != null) TimelineChip(role: ChipRole.holiday, label: holiday.name),
              for (final b in blocks) _chipFor(context, ref, b, sessions),
              for (final l in leave)
                TimelineChip(role: _chipRoleForLeave(l.type), label: '${_leaveLabel(l.type)} · ${AppFormat.hm(l.hours)}'),
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

  Widget _chipFor(BuildContext context, WidgetRef ref, TimelineBlock b, List<WorkSession> sessions) {
    switch (b.type) {
      case TimelineBlockType.work:
        final chip = TimelineChip(role: ChipRole.work, label: 'Work · ${AppFormat.time(b.start)} – ${AppFormat.time(b.end)}');
        final matches = sessions.where((s) => s.id == b.id);
        if (matches.isEmpty) return chip;
        return GestureDetector(onTap: () => EditSessionSheet.show(context, matches.first), child: chip);
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

/// Marks a day whose auto-break deduction was manually overridden (the
/// "delete a synthetic break" action — Requirements § 6, the one
/// retroactive-edit path currently exposed in the UI). Ambient and
/// tooltip-free per the UX doc's error/warning philosophy ("no
/// confirmation dialogs, ever"): `DayEntry.autoBreakOverridden` was already
/// tracked in the DB since Milestone 6 but never surfaced, so a day's
/// recalculated balance could silently differ from what the auto-break
/// logic alone would have produced with no visible explanation why.
class _RetroactiveEditBadge extends StatelessWidget {
  final AppColors colors;

  const _RetroactiveEditBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Icon(AppIcons.pencilSimpleLine, size: 12, color: colors.textMuted);
  }
}
