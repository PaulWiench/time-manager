import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'database_providers.dart';
import 'job_providers.dart';
import 'repository_providers.dart';

/// See `day_providers.dart` for why ranges are keyed by a record.
typedef _Range = ({DateTime start, DateTime endExclusive});

final _balanceSnapshotsInRange =
    FutureProvider.autoDispose.family<List<BalanceSnapshot>, _Range>((ref, r) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Future.value(const []);
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.forRange(jobId, r.start, r.endExclusive);
});

AutoDisposeFutureProvider<List<BalanceSnapshot>> balanceSnapshotsInRangeProvider(
  DateTime start,
  DateTime endExclusive,
) =>
    _balanceSnapshotsInRange((start: start, endExclusive: endExclusive));

final _workSessionsInRange =
    FutureProvider.autoDispose.family<List<WorkSession>, _Range>((ref, r) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Future.value(const []);
  return ref.watch(appDatabaseProvider).workSessionDao.forRange(jobId, r.start, r.endExclusive);
});

AutoDisposeFutureProvider<List<WorkSession>> workSessionsInRangeProvider(
  DateTime start,
  DateTime endExclusive,
) =>
    _workSessionsInRange((start: start, endExclusive: endExclusive));

final leaveForYearProvider =
    StreamProvider.autoDispose.family<List<LeaveEntry>, int>((ref, year) {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return Stream.value(const []);
  return ref.watch(leaveRepositoryProvider).watchForYear(jobId, year);
});

// The vacation quota lives in `vacation_quota_providers.dart` and is watched,
// not fetched. A one-shot copy used to sit here under the same name, so Stats
// showed a stale quota until the tab was rebuilt — and no file could import
// both providers without an ambiguous-import error.
