/// These migrations only ever run for real on one database: the one on the
/// phone, holding every tracked day since March. So each is tested three ways —
/// the schema matches afterwards, no row is touched, and the real backup file
/// opens.
///
/// The phone is at v2, so `v2 -> v3` is the path that will actually execute
/// there. `v1 -> v3` is tested too because `onUpgrade`'s `if`s are
/// non-exclusive by design and a two-step jump has to run both bodies.
library;

import 'dart:io';

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

  test('migrates a v1 database to v3', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  test('migrates a v2 database to v3 — the path the phone will take', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  test('keeps every row, and the new columns arrive unset', () async {
    final date = DateTime(2026, 3, 16);

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 3,
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

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
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

  test('opens the phone\'s own backup and migrates it', () async {
    // The emulator's database is v2-native from here on, so it never
    // exercises the path that matters. This is the file pulled off the phone.
    final dir = Directory('${Platform.environment['HOME']}/time-manager-backups/db');
    if (!dir.existsSync()) {
      markTestSkipped('no backup directory on this machine');
      return;
    }

    // Sorted by modification time, not by name. Two naming schemes have been
    // through this directory — `time_manager_<stamp>` and `timemanager-<stamp>`
    // — and they sort against each other by prefix rather than by date, so a
    // lexicographic "last" could quietly pick a months-old file and still pass.
    final backups = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sqlite'))
        .toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    if (backups.isEmpty) {
      markTestSkipped('no backup on this machine');
      return;
    }
    printOnFailure('migrating ${backups.last.path}');

    final copy = File('${Directory.systemTemp.createTempSync('tm-migrate').path}/db.sqlite');
    await backups.last.copy(copy.path);

    final db = AppDatabase(NativeDatabase(copy));
    // Opening is what runs the migration; reading proves it survived it.
    final sessions = await db.select(db.workSessions).get();
    final snapshots = await db.select(db.balanceSnapshots).get();
    final settings = await db.select(db.appSettings).get();
    await db.close();

    expect(sessions, isNotEmpty, reason: 'the backup should hold real sessions');
    expect(snapshots, isNotEmpty);
    expect(settings.every((s) => s.balanceFloorHours == null), isTrue);
    // Every pre-v3 row must come out of the upgrade with a usable window,
    // because the balance now asks it whether the working day is over.
    expect(settings.every((s) => s.workWindowStartMinutes == 8 * 60), isTrue);
    expect(settings.every((s) => s.workWindowEndMinutes == 18 * 60), isTrue);
  });
}
