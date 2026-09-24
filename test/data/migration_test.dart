/// The v1 -> v2 migration only ever runs for real on one database: the one on
/// the phone, holding every tracked day since March. So it is tested three
/// ways — the schema matches afterwards, no row is touched, and the real
/// backup file opens.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';

import '../drift/generated/schema.dart';
import '../drift/generated/schema_v1.dart' as v1;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('migrates a v1 database to v2', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('keeps every row, and the new columns arrive unset', () async {
    final date = DateTime(2026, 3, 16);

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
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

        final day = await db.select(db.dayEntries).getSingle();
        expect(day.netWorkedHours, 8.1);
      },
    );
  });

  test('opens the phone\'s own backup and migrates it', () async {
    // The emulator's database is v2-native from here on, so it never
    // exercises the path that matters. This is the file pulled off the phone.
    final backups = Directory('${Platform.environment['HOME']}/time-manager-backups/db')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sqlite'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (backups.isEmpty) {
      markTestSkipped('no backup on this machine');
      return;
    }

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
  });
}
