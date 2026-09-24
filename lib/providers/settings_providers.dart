import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

final latestSettingsProvider = StreamProvider<AppSetting?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchLatest();
});

/// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
final effectiveSettingsForProvider =
    FutureProvider.autoDispose.family<AppSetting?, DateTime>((ref, date) {
  return ref.watch(settingsRepositoryProvider).effectiveFor(date);
});
