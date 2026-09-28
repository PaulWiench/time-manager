import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'repository_providers.dart';

final latestSettingsProvider = StreamProvider<AppSetting?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchLatest();
});

/// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
///
/// A stream, not a one-shot future. As a future it resolved once and never
/// again, so every number derived from settings — the day's target, the
/// balance's work window, the leave fractions — went on showing the old value
/// until something disposed the provider. Found by changing the work window on
/// the phone and watching Home not move until the app was restarted.
final effectiveSettingsForProvider =
    StreamProvider.autoDispose.family<AppSetting?, DateTime>((ref, date) {
  return ref.watch(settingsRepositoryProvider).watchEffectiveFor(date);
});
