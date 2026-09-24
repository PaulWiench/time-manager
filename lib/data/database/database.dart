import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'converters.dart';
import 'enums.dart';
import 'daos/audit_log_dao.dart';
import 'daos/balance_snapshot_dao.dart';
import 'daos/break_entry_dao.dart';
import 'daos/day_entry_dao.dart';
import 'daos/leave_entry_dao.dart';
import 'daos/public_holiday_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/vacation_quota_dao.dart';
import 'daos/work_session_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    WorkSessions,
    BreakEntries,
    LeaveEntries,
    PublicHolidays,
    DayEntries,
    BalanceSnapshots,
    VacationQuotas,
    AppSettings,
    AuditLogEntries,
  ],
  daos: [
    WorkSessionDao,
    BreakEntryDao,
    LeaveEntryDao,
    PublicHolidayDao,
    DayEntryDao,
    BalanceSnapshotDao,
    VacationQuotaDao,
    SettingsDao,
    AuditLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  /// SQLite doesn't enforce FK constraints unless told to per-connection —
  /// without this, the WorkSession/BreakEntry/LeaveEntry -> DayEntry FKs in
  /// tables.dart would silently do nothing.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // v2 adds the balance floor/cap. ADD COLUMN is metadata-only in
        // SQLite and cannot touch existing rows — which matters here, since
        // the only database that will ever run this migration is the one on
        // the phone holding every day since March. Anything that needs a
        // table rebuild instead must also handle the foreign_keys pragma
        // below; this does not.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(appSettings, appSettings.balanceFloorHours);
            await m.addColumn(appSettings, appSettings.balanceCapHours);
            await m.addColumn(appSettings, appSettings.balanceAnnualReset);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'time_manager.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
