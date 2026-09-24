import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

/// Note: `stats_providers.dart` declares a one-shot `Future` provider under
/// this same name. They are deliberately separate — Settings wants a live
/// stream, Stats wants a snapshot for a chart — and no file imports both.
final vacationQuotaForYearProvider =
    StreamProvider.autoDispose.family<VacationQuota?, int>((ref, year) {
  return ref.watch(vacationQuotaRepositoryProvider).watchForYear(year);
});
