import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/leave_repository.dart';
import '../data/repositories/public_holiday_repository.dart';
import '../data/repositories/recalculation_service.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/vacation_quota_repository.dart';
import '../data/repositories/work_session_repository.dart';
import 'database_providers.dart';

final recalculationServiceProvider = Provider<RecalculationService>((ref) {
  return RecalculationService(ref.watch(appDatabaseProvider));
});

final workSessionRepositoryProvider = Provider<WorkSessionRepository>((ref) {
  return WorkSessionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
});

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
});

final publicHolidayRepositoryProvider = Provider<PublicHolidayRepository>((ref) {
  return PublicHolidayRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(recalculationServiceProvider),
  );
});

final vacationQuotaRepositoryProvider = Provider<VacationQuotaRepository>((ref) {
  return VacationQuotaRepository(ref.watch(appDatabaseProvider));
});

/// Seeds this year's and next year's German public holidays on app start.
/// `seedYear` only inserts dates that don't already exist, so this is a
/// cheap no-op on every launch after the first — and covers the
/// December-into-January boundary so next year's holidays are already
/// present before it turns over, not just by the time someone opens the
/// Settings screen after New Year's.
final holidaySeedProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(publicHolidayRepositoryProvider);
  // One-time cleanup of stray future BalanceSnapshots from before
  // recalculation_service.dart's _cascadeBalanceFrom was scoped to never
  // write speculative snapshots past today — see RecalculationService.
  // purgeFutureSnapshots for why those could corrupt the displayed
  // balance. Runs every launch; a no-op once none remain.
  await ref.watch(recalculationServiceProvider).purgeFutureSnapshots();
  final year = DateTime.now().year;
  await repo.seedYear(year);
  await repo.seedYear(year + 1);
});
