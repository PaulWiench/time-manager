import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

part 'vacation_quota_providers.g.dart';

@riverpod
Stream<VacationQuota?> vacationQuotaForYear(Ref ref, int year) {
  return ref.watch(vacationQuotaRepositoryProvider).watchForYear(year);
}
