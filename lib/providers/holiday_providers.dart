import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

final publicHolidaysForYearProvider =
    StreamProvider.autoDispose.family<List<PublicHoliday>, int>((ref, year) {
  return ref.watch(publicHolidayRepositoryProvider).watchForYear(year);
});
