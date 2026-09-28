/// The year's leave: vacation, sick and flex days, addable and removable.
///
/// Until this screen existed, `LeaveRepository.addLeave` and `deleteLeave` had
/// no caller in `lib/` at all — leave could arrive from the import and then
/// nothing could ever change it, while Settings still offered a vacation quota
/// for it to count against.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/leave_days.dart';
import '../../domain/recalculation_engine.dart';
import '../../providers/day_providers.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/vacation_quota_providers.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/leave_sheet.dart';
import 'leave_list_body.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  late int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final entries = ref.watch(leaveForYearProvider(_year)).valueOrNull ?? const [];
    final quota = ref.watch(vacationQuotaForYearProvider(_year)).valueOrNull;
    final targets = _targetResolver(_year);

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    var used = 0.0;
    var planned = 0.0;
    for (final entry in sorted) {
      if (entry.type != LeaveType.vacation) continue;
      final days = leaveDaysFor(hours: entry.hours, targetHours: targets(entry.date));
      if (entry.date.isAfter(today)) {
        planned += days;
      } else {
        used += days;
      }
    }

    return LeaveListBody(
      year: _year,
      items: [
        for (final entry in sorted)
          LeaveListItem(
            id: entry.id,
            date: entry.date,
            type: entry.type,
            amountLabel: _amountLabel(entry.hours, targets(entry.date)),
            planned: entry.date.isAfter(today),
          ),
      ],
      usedDays: used,
      plannedDays: planned,
      quotaDays: (quota?.totalDays ?? 30) + (quota?.rolloverDays ?? 0),
      // A year ahead is useful — that is where next year's block gets booked —
      // but there is no point walking further into an empty calendar.
      canStepForward: _year < today.year + 1,
      onStepYear: (direction) => setState(() => _year += direction),
      onAdd: _add,
      onEdit: (item) => _edit(item.date),
      onRemove: (item) =>
          ref.read(leaveRepositoryProvider).deleteLeave(item.id, item.date),
    );
  }

  /// That date's own target, preferring the stored `DayEntry` and falling back
  /// to recomputing it — a day booked a moment ago has a row, but the range
  /// provider is a one-shot future and may not have caught up yet.
  ///
  /// Build-time only: it watches. The edit path uses [_targetFor], which awaits
  /// the same sources instead, because a date picked for next year has no warm
  /// provider behind it.
  double Function(DateTime) _targetResolver(int year) {
    final days = ref
            .watch(dayEntriesInRangeProvider(DateTime(year), DateTime(year + 1)))
            .valueOrNull ??
        const <DayEntry>[];
    final stored = {for (final day in days) day.date: day.targetHours};

    final settings = ref.watch(latestSettingsProvider).valueOrNull;
    final holidays =
        ref.watch(publicHolidaysForYearProvider(year)).valueOrNull ?? const [];
    final fractions = {for (final h in holidays) h.date: h.fraction};

    return (date) {
      final day = stored[dateOnly(date)];
      if (day != null) return day;
      if (settings == null) return 0;
      return computeTargetHours(
        date: date,
        workDays: settings.workDays,
        weeklyHours: settings.weeklyHours,
        holidayFraction: fractions[dateOnly(date)],
      );
    };
  }

  String _amountLabel(double hours, double targetHours) {
    final days = leaveDaysFor(hours: hours, targetHours: targetHours);
    return switch (days) {
      1.0 => 'full day',
      0.75 => '¾ day',
      0.5 => '½ day',
      0.25 => '¼ day',
      // An imported entry that does not land on a quarter is shown as it is,
      // rather than rounded into a claim the data does not make.
      _ => AppFormat.hm(hours),
    };
  }

  Future<void> _add() async {
    final picked = await showAppDatePicker(
      context: context,
      initial: dateOnly(DateTime.now()),
      last: DateTime(_year + 1, 12, 31),
    );
    if (picked == null || !mounted) return;
    await _edit(picked);
    if (mounted) setState(() => _year = picked.year);
  }

  Future<double> _targetFor(DateTime date) async {
    final day = dateOnly(date);
    final settings = await ref.read(latestSettingsProvider.future);
    if (settings == null) return 0;

    final entry = await ref.read(dayEntryForDateProvider(day).future);
    if (entry != null) return entry.targetHours;

    final holiday = await ref.read(publicHolidayForDateProvider(day).future);
    return computeTargetHours(
      date: day,
      workDays: settings.workDays,
      weeklyHours: settings.weeklyHours,
      holidayFraction: holiday?.fraction,
    );
  }

  Future<void> _edit(DateTime date) async {
    final day = dateOnly(date);
    final existing = await ref.read(leaveForDateProvider(day).future);
    final targetHours = await _targetFor(day);
    if (!mounted) return;

    final edit = await showLeaveSheet(
      context: context,
      date: day,
      targetHours: targetHours,
      existing: existing,
    );
    if (edit == null || !mounted) return;

    final repo = ref.read(leaveRepositoryProvider);
    // One kind of leave per day: the old row goes before the new one lands, or
    // the day would count twice against the quota and twice in its balance.
    for (final entry in existing) {
      await repo.deleteLeave(entry.id, day);
    }
    if (!edit.cleared) {
      await repo.addLeave(date: day, type: edit.type!, hours: edit.hours!);
    }
  }
}
