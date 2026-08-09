import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<AppSetting?> latestSettings(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchLatest();
}

/// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
@riverpod
Future<AppSetting?> effectiveSettingsFor(Ref ref, DateTime date) {
  return ref.watch(settingsRepositoryProvider).effectiveFor(date);
}
