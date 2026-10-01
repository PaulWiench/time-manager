import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/database/enums.dart';
import '../domain/date_only.dart';
import '../domain/leave_days.dart';
import '../domain/recalculation_engine.dart';
import '../domain/vacation_bookings.dart';
import 'database_providers.dart';
import 'day_providers.dart';
import 'job_providers.dart';
import 'settings_providers.dart';
import 'stats_providers.dart';

/// Every booking's name for the selected job, by booking id.
final vacationNamesProvider = StreamProvider.autoDispose<Map<String, String?>>((ref) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Stream.value(const {});
  return ref
      .watch(appDatabaseProvider)
      .jobDao
      .watchVacations(jobId)
      .map((rows) => {for (final row in rows) row.id: row.name});
});

/// What one leave entry is worth in days, against its own date's target —
/// the stored day entry's, or the schedule's for a date with none yet.
double Function(LeaveEntry) leaveDaysResolver(List<DayEntry> dayEntries, AppSetting? settings) {
  final targets = {for (final day in dayEntries) day.date: day.targetHours};
  return (entry) {
    final target = targets[dateOnly(entry.date)] ??
        (settings == null
            ? 0.0
            : computeTargetHours(
                date: entry.date,
                workDays: settings.workDays,
                weeklyHours: settings.weeklyHours,
              ));
    return leaveDaysFor(hours: entry.hours, targetHours: target);
  };
}

/// The selected job's vacation bookings in [year], planned first.
final vacationBookingsProvider =
    Provider.autoDispose.family<List<VacationBooking>, int>((ref, year) {
  final entries = ref.watch(leaveForYearProvider(year)).valueOrNull ?? const <LeaveEntry>[];
  final dayEntries =
      ref.watch(dayEntriesInRangeProvider(DateTime(year), DateTime(year + 1))).valueOrNull ??
          const <DayEntry>[];
  final settings = ref.watch(latestSettingsProvider).valueOrNull;
  final names = ref.watch(vacationNamesProvider).valueOrNull ?? const {};
  final daysFor = leaveDaysResolver(dayEntries, settings);

  return groupVacations(
    [
      for (final entry in entries)
        if (entry.type == LeaveType.vacation)
          VacationDay(date: entry.date, vacationId: entry.vacationId, days: daysFor(entry)),
    ],
    names: names,
    today: DateTime.now(),
  );
});

/// The selected job's vacation days in [year] not yet booked — entitlement
/// less everything taken and planned. Null until the entitlement is known.
final vacationDaysLeftProvider = Provider.autoDispose.family<double?, int>((ref, year) {
  final entitlement = ref.watch(vacationEntitlementProvider(year));
  if (entitlement == null) return null;
  final booked =
      ref.watch(vacationBookingsProvider(year)).fold<double>(0, (sum, b) => sum + b.days);
  return entitlement.totalDays - booked;
});

/// The booking a given vacation day belongs to, for History's label.
final vacationBookingForDateProvider =
    Provider.autoDispose.family<VacationBooking?, DateTime>((ref, date) {
  final day = dateOnly(date);
  for (final booking in ref.watch(vacationBookingsProvider(day.year))) {
    if (booking.dates.contains(day)) return booking;
  }
  return null;
});
