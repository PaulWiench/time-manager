import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/day_rollover.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

final dayRolloverRepositoryProvider = Provider<DayRollover>((ref) {
  return DayRollover(
    ref.watch(appDatabaseProvider),
    ref.watch(workSessionRepositoryProvider),
    ref.watch(recalculationServiceProvider),
  );
});

/// Closes out the days that passed while the app was shut — see [DayRollover].
///
/// Fire-and-forget beside `holidaySeedProvider`, and idempotent the same way.
final dayRolloverProvider = FutureProvider<void>((ref) async {
  await ref.watch(dayRolloverRepositoryProvider).run();
});
