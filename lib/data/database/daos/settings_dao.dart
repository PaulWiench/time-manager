import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// The active settings row for [date]: the one with the highest
  /// `effectiveFrom` that is <= [date]. Ties (two rows saved with the same
  /// `effectiveFrom`) break in favor of whichever was saved most recently —
  /// "last write wins" for same-day changes. See Data Model § Settings.
  Future<AppSetting?> effectiveFor(int jobId, DateTime date) => (select(appSettings)
        ..where((t) => t.jobId.equals(jobId) & t.effectiveFrom.isSmallerOrEqualValue(date))
        ..orderBy([
          (t) => OrderingTerm.desc(t.effectiveFrom),
          (t) => OrderingTerm.desc(t.createdAt),
        ])
        ..limit(1))
      .getSingleOrNull();

  /// [effectiveFor] as a stream, so a screen showing settings-derived numbers
  /// updates when they change rather than at the next app launch.
  Stream<AppSetting?> watchEffectiveFor(int jobId, DateTime date) => (select(appSettings)
        ..where((t) => t.jobId.equals(jobId) & t.effectiveFrom.isSmallerOrEqualValue(date))
        ..orderBy([
          (t) => OrderingTerm.desc(t.effectiveFrom),
          (t) => OrderingTerm.desc(t.createdAt),
        ])
        ..limit(1))
      .watchSingleOrNull();

  Stream<AppSetting?> watchLatest(int jobId) => (select(appSettings)
        ..where((t) => t.jobId.equals(jobId))
        ..orderBy([
          (t) => OrderingTerm.desc(t.effectiveFrom),
          (t) => OrderingTerm.desc(t.createdAt),
        ])
        ..limit(1))
      .watchSingleOrNull();

  Future<AppSetting?> latest(int jobId) => (select(appSettings)
        ..where((t) => t.jobId.equals(jobId))
        ..orderBy([
          (t) => OrderingTerm.desc(t.effectiveFrom),
          (t) => OrderingTerm.desc(t.createdAt),
        ])
        ..limit(1))
      .getSingleOrNull();

  /// Whether any job has settings yet — i.e. onboarding has run.
  Future<bool> any() async =>
      (await (select(appSettings)..limit(1)).getSingleOrNull()) != null;

  Future<int> insertSettings(AppSettingsCompanion entry) =>
      into(appSettings).insert(entry);
}
