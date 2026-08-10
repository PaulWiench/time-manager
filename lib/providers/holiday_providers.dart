import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

part 'holiday_providers.g.dart';

@riverpod
Stream<List<PublicHoliday>> publicHolidaysForYear(Ref ref, int year) {
  return ref.watch(publicHolidayRepositoryProvider).watchForYear(year);
}
