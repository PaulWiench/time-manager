import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

part 'stats_providers.g.dart';

@riverpod
Future<List<BalanceSnapshot>> balanceSnapshotsInRange(Ref ref, DateTime start, DateTime endExclusive) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.forRange(start, endExclusive);
}

@riverpod
Future<List<WorkSession>> workSessionsInRange(Ref ref, DateTime start, DateTime endExclusive) {
  return ref.watch(appDatabaseProvider).workSessionDao.forRange(start, endExclusive);
}

@riverpod
Future<List<LeaveEntry>> leaveForYear(Ref ref, int year) {
  return ref.watch(leaveRepositoryProvider).forYear(year);
}

@riverpod
Future<VacationQuota?> vacationQuotaForYear(Ref ref, int year) {
  return ref.watch(vacationQuotaRepositoryProvider).forYear(year);
}
