import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

part 'day_providers.g.dart';

/// All family providers below expect [date] already normalized to midnight
/// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
/// each time would defeat provider caching.

@riverpod
Stream<List<WorkSession>> sessionsForDate(Ref ref, DateTime date) {
  return ref.watch(workSessionRepositoryProvider).watchSessionsForDate(date);
}

@riverpod
Stream<DayEntry?> dayEntryForDate(Ref ref, DateTime date) {
  return ref.watch(appDatabaseProvider).dayEntryDao.watchForDate(date);
}

@riverpod
Stream<List<LeaveEntry>> leaveForDate(Ref ref, DateTime date) {
  return ref.watch(leaveRepositoryProvider).watchForDate(date);
}

@riverpod
Stream<List<BreakEntry>> breaksForDate(Ref ref, DateTime date) {
  return ref.watch(appDatabaseProvider).breakEntryDao.watchForDate(date);
}
