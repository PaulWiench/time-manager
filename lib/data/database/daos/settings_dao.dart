import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// The active settings row for [date]: the one with the highest
  /// `effectiveFrom` that is <= [date]. See Data Model § Settings.
  Future<AppSetting?> effectiveFor(DateTime date) => (select(appSettings)
        ..where((t) => t.effectiveFrom.isSmallerOrEqualValue(date))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom)])
        ..limit(1))
      .getSingleOrNull();

  Stream<AppSetting?> watchLatest() => (select(appSettings)
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom)])
        ..limit(1))
      .watchSingleOrNull();

  Future<int> insertSettings(AppSettingsCompanion entry) =>
      into(appSettings).insert(entry);
}
