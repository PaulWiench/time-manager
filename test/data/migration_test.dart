/// These migrations only ever run for real on one database: the one on the
/// phone, holding every tracked day since March. So each is tested three ways —
/// the schema matches afterwards, no row is touched, and the real backup file
/// opens.
///
/// The phone is at v3, so `v3 -> v4` is the path that will actually execute
/// there; `test/data/v4_real_data_test.dart` runs it over the phone's own data
/// row by row. The older jumps are tested too because `onUpgrade`'s `if`s are
/// non-exclusive by design and a multi-step jump has to run every body.
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';

import '../drift/generated/schema.dart';
import '../drift/generated/schema_v1.dart' as v1;
import '../drift/generated/schema_v2.dart' as v2;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // `migrateAndValidate` cannot be used from v4 on: its comparison counts the
  // composite foreign key `FOREIGN KEY (job_id, date) REFERENCES day_entries`
  // differently on its two sides and reports a difference where the SQL is
  // identical. So this compares what the schema *is* rather than how it is
  // spelled: per table, every column (type, NOT NULL, default, key position)
  // and every foreign key, from SQLite's own pragmas. The spelling does
  // differ, harmlessly — an added column sits last in `app_settings`, and
  // tables created by older versions quote their constraints differently.
  Future<List<String>> schemaOf(AppDatabase db) async {
    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata' ORDER BY name")
        .map((row) => row.read<String>('name'))
        .get();
    return [
      for (final table in tables) ...[
        for (final column in (await db.customSelect('PRAGMA table_info("$table")').get())
            .map((r) => '$table.${r.data['name']} ${r.data['type']} '
                'notnull=${r.data['notnull']} default=${r.data['dflt_value']} pk=${r.data['pk']}')
            .toList()
          ..sort())
          column,
        for (final fk in (await db.customSelect('PRAGMA foreign_key_list("$table")').get())
            .map((r) => '$table fk ${r.data['from']} -> ${r.data['table']}.${r.data['to']}')
            .toList()
          ..sort())
          fk,
      ],
    ];
  }

  late List<String> fresh;
  setUpAll(() async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    fresh = await schemaOf(db);
    await db.close();
  });

  for (final from in [1, 2, 3]) {
    test('a v$from database upgrades to exactly the v4 schema', () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);
      expect(await schemaOf(db), fresh);
      expect(await db.customSelect('PRAGMA user_version').map((r) => r.data.values.first).getSingle(), 4);
      await db.close();
    });
  }

  test('keeps every row, and the new columns arrive unset', () async {
    final date = DateTime(2026, 3, 16);

    await _withDataIntegrity(
      verifier,
      oldVersion: 1,
      newVersion: 4,
      createOld: v1.DatabaseAtV1.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) {
        // The generated v1 schema has no data classes, only raw tables, so
        // rows go in by column name. DateTime columns are stored as unix
        // seconds by this database's converter defaults.
        batch.insert(
          db.appSettings,
          RawValuesInsertable({
            'id': Variable<String>('settings-1'),
            'effective_from': Variable<int>(date.millisecondsSinceEpoch ~/ 1000),
            'weekly_hours': Variable<double>(39.5),
            'work_days': Variable<String>('1,2,3,4,5'),
            'min_session_minutes': Variable<int>(5),
            'auto_break_enabled': Variable<bool>(true),
            'restrict_checkin': Variable<bool>(false),
            'created_at': Variable<int>(date.millisecondsSinceEpoch ~/ 1000),
          }),
        );
        batch.insert(
          db.dayEntries,
          RawValuesInsertable({
            'date': Variable<int>(date.millisecondsSinceEpoch ~/ 1000),
            'net_worked_hours': Variable<double>(8.1),
            'leave_hours': Variable<double>(0),
            'target_hours': Variable<double>(7.9),
            'balance_delta': Variable<double>(0.2),
            'auto_break_overridden': Variable<bool>(false),
            'updated_at': Variable<int>(date.millisecondsSinceEpoch ~/ 1000),
          }),
        );
      },
      validateItems: (db) async {
        final settings = await db.select(db.appSettings).getSingle();
        expect(settings.weeklyHours, 39.5);
        // "Not configured" has to survive as null, not become a zero bound
        // that would make the warning treatment fire on every negative day.
        expect(settings.balanceFloorHours, isNull);
        expect(settings.balanceCapHours, isNull);
        expect(settings.balanceAnnualReset, isFalse);
        // The work window, unlike the balance bounds, has no "not configured"
        // state — a row that predates the column has to come out usable.
        expect(settings.workWindowStartMinutes, 8 * 60);
        expect(settings.workWindowEndMinutes, 18 * 60);

        final day = await db.select(db.dayEntries).getSingle();
        expect(day.netWorkedHours, 8.1);
      },
    );
  });

  test('v2 -> v3 leaves the settings row intact and defaults the window', () async {
    final date = DateTime(2026, 3, 16);

    await _withDataIntegrity(
      verifier,
      oldVersion: 2,
      newVersion: 4,
      createOld: v2.DatabaseAtV2.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, db) {
        batch.insert(
          db.appSettings,
          RawValuesInsertable({
            'id': Variable<String>('settings-1'),
            'effective_from': Variable<int>(date.millisecondsSinceEpoch ~/ 1000),
            'weekly_hours': Variable<double>(39.5),
            'work_days': Variable<String>('1,2,3,4,5'),
            'min_session_minutes': Variable<int>(5),
            'auto_break_enabled': Variable<bool>(true),
            'restrict_checkin': Variable<bool>(false),
            // Set on the old row so the assertion below proves the migration
            // carried a v2-only column across rather than re-defaulting it.
            'balance_floor_hours': Variable<double>(-40),
            'balance_annual_reset': Variable<bool>(false),
            'created_at': Variable<int>(date.millisecondsSinceEpoch ~/ 1000),
          }),
        );
      },
      validateItems: (db) async {
        final settings = await db.select(db.appSettings).getSingle();
        expect(settings.weeklyHours, 39.5);
        expect(settings.workDays, [1, 2, 3, 4, 5]);
        expect(settings.balanceFloorHours, -40);
        expect(settings.workWindowStartMinutes, 8 * 60);
        expect(settings.workWindowEndMinutes, 18 * 60);
      },
    );
  });
}

/// `SchemaVerifier.testWithDataIntegrity` without its schema comparison, which
/// misreads the v4 composite foreign key (see `schemaOf` above; the structure
/// is checked there instead). Rows go in at [oldVersion], the app database
/// opens the same file — which migrates it — and [validateItems] reads back.
Future<void> _withDataIntegrity<Old extends GeneratedDatabase>(
  SchemaVerifier verifier, {
  required int oldVersion,
  required int newVersion,
  required Old Function(QueryExecutor) createOld,
  required AppDatabase Function(QueryExecutor) createNew,
  required AppDatabase Function(QueryExecutor) openTestedDatabase,
  required void Function(Batch, Old) createItems,
  required Future<void> Function(AppDatabase) validateItems,
}) async {
  final schema = await verifier.schemaAt(oldVersion);

  final oldDb = createOld(schema.newConnection());
  await oldDb.batch((batch) => createItems(batch, oldDb));
  await oldDb.close();

  final db = openTestedDatabase(schema.newConnection());
  expect(
    await db.customSelect('PRAGMA user_version').map((r) => r.data.values.first).getSingle(),
    newVersion,
  );
  await validateItems(db);
  await db.close();
}
