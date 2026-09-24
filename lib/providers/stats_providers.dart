import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

/// See `day_providers.dart` for why ranges are keyed by a record.
typedef _Range = ({DateTime start, DateTime endExclusive});

final _balanceSnapshotsInRange =
    FutureProvider.autoDispose.family<List<BalanceSnapshot>, _Range>((ref, r) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.forRange(r.start, r.endExclusive);
});

AutoDisposeFutureProvider<List<BalanceSnapshot>> balanceSnapshotsInRangeProvider(
  DateTime start,
  DateTime endExclusive,
) =>
    _balanceSnapshotsInRange((start: start, endExclusive: endExclusive));

final _workSessionsInRange =
    FutureProvider.autoDispose.family<List<WorkSession>, _Range>((ref, r) {
  return ref.watch(appDatabaseProvider).workSessionDao.forRange(r.start, r.endExclusive);
});

AutoDisposeFutureProvider<List<WorkSession>> workSessionsInRangeProvider(
  DateTime start,
  DateTime endExclusive,
) =>
    _workSessionsInRange((start: start, endExclusive: endExclusive));

final leaveForYearProvider =
    FutureProvider.autoDispose.family<List<LeaveEntry>, int>((ref, year) {
  return ref.watch(leaveRepositoryProvider).forYear(year);
});

final vacationQuotaForYearProvider =
    FutureProvider.autoDispose.family<VacationQuota?, int>((ref, year) {
  return ref.watch(vacationQuotaRepositoryProvider).forYear(year);
});
