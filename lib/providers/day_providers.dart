import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'database_providers.dart';
import 'job_providers.dart';
import 'repository_providers.dart';

/// All family providers below expect [date] already normalized to midnight
/// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
/// each time would defeat provider caching.
///
/// Every one of them reads the selected job's rows (see `job_providers.dart`),
/// so a screen built on them follows the job switcher without knowing it.

final sessionsForDateProvider =
    StreamProvider.autoDispose.family<List<WorkSession>, DateTime>((ref, date) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Stream.value(const []);
  return ref.watch(workSessionRepositoryProvider).watchSessionsForDate(jobId, date);
});

final dayEntryForDateProvider =
    StreamProvider.autoDispose.family<DayEntry?, DateTime>((ref, date) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Stream.value(null);
  return ref.watch(appDatabaseProvider).dayEntryDao.watchForDate(jobId, date);
});

final leaveForDateProvider =
    StreamProvider.autoDispose.family<List<LeaveEntry>, DateTime>((ref, date) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Stream.value(const []);
  return ref.watch(leaveRepositoryProvider).watchForDate(jobId, date);
});

final breaksForDateProvider =
    StreamProvider.autoDispose.family<List<BreakEntry>, DateTime>((ref, date) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Stream.value(const []);
  return ref.watch(appDatabaseProvider).breakEntryDao.watchForDate(jobId, date);
});

final publicHolidayForDateProvider =
    StreamProvider.autoDispose.family<PublicHoliday?, DateTime>((ref, date) {
  return ref.watch(publicHolidayRepositoryProvider).watchForDate(date);
});

/// A Riverpod family takes exactly one argument, so ranges are keyed by a
/// record — structurally equal for equal dates, which is what keeps the
/// provider cached across rebuilds. The wrapper function below preserves the
/// two-argument call shape the generator used to emit.
typedef _Range = ({DateTime start, DateTime endExclusive});

final _dayEntriesInRange =
    FutureProvider.autoDispose.family<List<DayEntry>, _Range>((ref, r) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Future.value(const []);
  return ref.watch(appDatabaseProvider).dayEntryDao.forRange(jobId, r.start, r.endExclusive);
});

/// Used by History's Month/Week rows to aggregate worked hours + balance
/// delta over a range without a per-day family provider each.
AutoDisposeFutureProvider<List<DayEntry>> dayEntriesInRangeProvider(
  DateTime start,
  DateTime endExclusive,
) =>
    _dayEntriesInRange((start: start, endExclusive: endExclusive));
