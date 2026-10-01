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
import '../../widgets/app_date_picker.dart';
import '../../widgets/leave_sheet.dart';
import 'leave_list_body.dart';
import '../../providers/job_providers.dart';

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
    final entitlement = ref.watch(vacationEntitlementProvider(_year));
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
      items: _group(sorted, targets, today),
      usedDays: used,
      plannedDays: planned,
      quotaDays: entitlement?.totalDays ?? 30,
      // A year ahead is useful — that is where next year's block gets booked —
      // but there is no point walking further into an empty calendar.
      canStepForward: _year < today.year + 1,
      onStepYear: (direction) => setState(() => _year += direction),
      onAdd: () => _book(targets),
      onEdit: (item) => _edit(item.date),
      onRemove: (item) {
        final jobId = ref.read(selectedJobIdProvider);
        if (jobId != null) {
          ref.read(leaveRepositoryProvider).clearLeaveForDates(jobId, item.dates);
        }
      },
    );
  }

  /// Collapses days that run together into one row.
  ///
  /// Two entries join when they are the same kind of leave for the same share
  /// of the day, on the same side of today, with nothing but unbookable days
  /// between them — so a Friday and the following Monday are one run, and a
  /// Friday and the Tuesday after are two.
  List<LeaveListItem> _group(
    List<LeaveEntry> sorted,
    double Function(DateTime) targets,
    DateTime today,
  ) {
    String amount(LeaveEntry e) => _amountLabel(e.hours, targets(e.date));

    bool joins(LeaveEntry prev, LeaveEntry next) {
      if (prev.type != next.type) return false;
      if (prev.date.isAfter(today) != next.date.isAfter(today)) return false;
      // Compared as a share of the day, not as hours: two full days either
      // side of a half-day holiday are both "full day" at different lengths.
      if (amount(prev) != amount(next)) return false;

      for (var d = shiftDays(dateOnly(prev.date), 1);
          d.isBefore(dateOnly(next.date));
          d = shiftDays(d, 1)) {
        if (targets(d) > 0) return false;
      }
      return true;
    }

    final items = <LeaveListItem>[];
    var run = <LeaveEntry>[];

    void flush() {
      if (run.isEmpty) return;
      items.add(LeaveListItem(
        dates: [for (final e in run) dateOnly(e.date)],
        type: run.first.type,
        amountLabel: amount(run.first),
        planned: run.first.date.isAfter(today),
      ));
      run = [];
    }

    for (final entry in sorted) {
      if (run.isNotEmpty && !joins(run.last, entry)) flush();
      run.add(entry);
    }
    flush();

    return items;
  }

  /// That date's own target, preferring the stored `DayEntry` and falling back
  /// to recomputing it — a day booked a moment ago has a row, but the range
  /// provider is a one-shot future and may not have caught up yet.
  ///
  /// Spans the year either side of [year], because the range picker can be
  /// walked into December and January. Without the neighbours' holidays a
  /// public holiday just outside the listed year would look like an ordinary
  /// workday and quietly consume a vacation day.
  ///
  /// Build-time only: it watches. The single-date edit path uses [_targetFor],
  /// which awaits the same sources instead.
  double Function(DateTime) _targetResolver(int year) {
    final days = ref
            .watch(dayEntriesInRangeProvider(DateTime(year - 1), DateTime(year + 2)))
            .valueOrNull ??
        const <DayEntry>[];
    final stored = {for (final day in days) day.date: day.targetHours};

    final settings = ref.watch(latestSettingsProvider).valueOrNull;
    final fractions = <DateTime, double>{
      for (final offset in [-1, 0, 1])
        for (final h in ref
                .watch(publicHolidaysForYearProvider(year + offset))
                .valueOrNull ??
            const <PublicHoliday>[])
          h.date: h.fraction,
    };

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

  /// Book a span of days at once.
  ///
  /// Vacation is almost never one day, and this used to be a single-date picker
  /// feeding a single-date sheet — a fortnight was fourteen trips through both.
  /// The picker hands back the days already filtered, so nothing here repeats
  /// the workday rules.
  Future<void> _book(double Function(DateTime) targets) async {
    final picked = await showAppDateRangePicker(
      context: context,
      initialMonth: DateTime(_year, DateTime.now().month),
      bookable: (date) => targets(date) > 0,
    );
    if (picked == null || picked.isEmpty || !mounted) return;

    final dates = picked.toList()..sort();
    // Only a single day can meaningfully offer "Remove": across a span the
    // sheet is booking, not editing one existing entry.
    final existing = dates.length == 1
        ? await ref.read(leaveForDateProvider(dates.first).future)
        : const <LeaveEntry>[];
    if (!mounted) return;

    final edit = await showLeaveSheet(
      context: context,
      dates: dates,
      targetFor: targets,
      existing: existing,
    );
    if (edit == null || !mounted) return;

    final repo = ref.read(leaveRepositoryProvider);
    final jobId = ref.read(selectedJobIdProvider);
    if (jobId == null) return;
    if (edit.cleared) {
      await repo.clearLeaveForDates(jobId, dates);
    } else {
      await repo.setLeaveForDates(
        jobId: jobId,
        hoursByDate: {for (final date in dates) date: edit.hoursFor(targets(date))},
        type: edit.type!,
        vacationName: edit.name,
      );
    }
    if (mounted) setState(() => _year = dates.first.year);
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
      dates: [day],
      targetFor: (_) => targetHours,
      existing: existing,
    );
    if (edit == null || !mounted) return;

    // One kind of leave per day: the old row goes before the new one lands, or
    // the day would count twice against the quota and twice in its balance.
    // `setLeaveForDates` does that clearing itself.
    final repo = ref.read(leaveRepositoryProvider);
    final jobId = ref.read(selectedJobIdProvider);
    if (jobId == null) return;
    if (edit.cleared) {
      await repo.clearLeaveForDates(jobId, [day]);
    } else {
      await repo.setLeaveForDates(
        jobId: jobId,
        hoursByDate: {day: edit.hoursFor(targetHours)},
        type: edit.type!,
        vacationName: edit.name,
      );
    }
  }
}
