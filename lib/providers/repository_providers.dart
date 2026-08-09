import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/leave_repository.dart';
import '../data/repositories/public_holiday_repository.dart';
import '../data/repositories/recalculation_service.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/vacation_quota_repository.dart';
import '../data/repositories/work_session_repository.dart';
import 'database_providers.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
RecalculationService recalculationService(Ref ref) {
  return RecalculationService(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
WorkSessionRepository workSessionRepository(Ref ref) {
  return WorkSessionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
}

@Riverpod(keepAlive: true)
LeaveRepository leaveRepository(Ref ref) {
  return LeaveRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
}

@Riverpod(keepAlive: true)
PublicHolidayRepository publicHolidayRepository(Ref ref) {
  return PublicHolidayRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
}

@Riverpod(keepAlive: true)
VacationQuotaRepository vacationQuotaRepository(Ref ref) {
  return VacationQuotaRepository(ref.watch(appDatabaseProvider));
}

/// Seeds this year's and next year's German public holidays on app start.
/// `seedYear` only inserts dates that don't already exist, so this is a
/// cheap no-op on every launch after the first — and covers the
/// December-into-January boundary so next year's holidays are already
/// present before it turns over, not just by the time someone opens the
/// Settings screen after New Year's.
@Riverpod(keepAlive: true)
Future<void> holidaySeed(Ref ref) async {
  final repo = ref.watch(publicHolidayRepositoryProvider);
  final year = DateTime.now().year;
  await repo.seedYear(year);
  await repo.seedYear(year + 1);
}
