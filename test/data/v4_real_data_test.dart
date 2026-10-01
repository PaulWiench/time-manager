/// The v3 -> v4 migration, run against a copy of the phone's own database.
///
/// This is the only test that matters for the upgrade: the file it reads is
/// the export Paul took on 1 Oct 2026 immediately before the jobs release, and
/// the phone will run exactly this migration over exactly this data (plus
/// whatever he tracked since). Every row of every table is compared value for
/// value — raw SQLite on both sides, so the generated code under test is not
/// also the thing checking it.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/v4_migration.dart';
import 'package:time_manager/data/repositories/recalculation_service.dart';

final _home = Platform.environment['HOME'];
/// TM_BACKUP points the test at a newer export, as taken right before an
/// install; without it, the 1 Oct export it was written against.
final _backup = File(
  Platform.environment['TM_BACKUP'] ??
      '$_home/time-manager-backups/pre-jobs-migration/timemanager-20261001-184731.sqlite',
);
final _isPinnedExport = !Platform.environment.containsKey('TM_BACKUP');

/// Each v3 table and the columns that identify a row in it.
const _tables = {
  'work_sessions': 'id',
  'break_entries': 'id',
  'leave_entries': 'id',
  'public_holidays': 'date',
  'day_entries': 'date',
  'balance_snapshots': 'date',
  'vacation_quotas': 'year',
  'app_settings': 'id',
  'audit_log_entries': 'id',
};

Map<String, List<Map<String, Object?>>> _dump(String path) {
  final db = raw.sqlite3.open(path, mode: raw.OpenMode.readOnly);
  try {
    return {
      for (final MapEntry(key: table, value: key) in _tables.entries)
        table: [
          for (final row in db.select('SELECT * FROM $table ORDER BY $key'))
            Map<String, Object?>.of(row),
        ],
    };
  } finally {
    db.close();
  }
}

File _copyOfBackup() {
  final dir = Directory.systemTemp.createTempSync('tm-v4');
  final copy = _backup.copySync('${dir.path}/db.sqlite');
  // The backup itself is kept read-only, and a copy inherits that.
  Process.runSync('chmod', ['u+w', copy.path]);
  return copy;
}

Future<void> _openAndMigrate(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  // Any query opens the database, and opening is what migrates it.
  await db.customSelect('SELECT 1').get();
  await db.close();
}

void main() {
  if (!_backup.existsSync()) {
    test('real-data migration', () {}, skip: 'backup not on this machine');
    return;
  }

  late Map<String, List<Map<String, Object?>>> before;
  late Map<String, List<Map<String, Object?>>> after;
  late raw.Database migrated;

  setUpAll(() async {
    final file = _copyOfBackup();
    before = _dump(file.path);
    await _openAndMigrate(file);
    after = _dump(file.path);
    migrated = raw.sqlite3.open(file.path, mode: raw.OpenMode.readOnly);
  });

  tearDownAll(() => migrated.close());

  test('the backup is the v3 file it should be', () {
    final db = raw.sqlite3.open(_backup.path, mode: raw.OpenMode.readOnly);
    expect(db.userVersion, 3);
    if (_isPinnedExport) {
      expect(db.select('SELECT COUNT(*) AS n FROM work_sessions').first['n'], 329);
    }
    db.close();
  });

  test('ends at v4, intact, with every reference resolving', () {
    expect(migrated.userVersion, 4);
    expect(migrated.select('PRAGMA integrity_check').first.values.first, 'ok');
    expect(migrated.select('PRAGMA foreign_key_check'), isEmpty);
  });

  for (final table in _tables.keys) {
    test('$table: every row survives with every value unchanged', () {
      // The audit log gains exactly one row, the migration's own record.
      final rows = after[table]!
          .where((r) => !(table == 'audit_log_entries' && r['action'] == 'migrate'))
          .toList();
      expect(rows.length, before[table]!.length);
      for (var i = 0; i < rows.length; i++) {
        for (final MapEntry(key: column, value: value) in before[table]![i].entries) {
          expect(rows[i][column], value, reason: '$table row $i column $column');
        }
      }
    });
  }

  test('every per-day row now belongs to the first job', () {
    for (final table in [
      'work_sessions',
      'break_entries',
      'leave_entries',
      'day_entries',
      'balance_snapshots',
      'vacation_quotas',
      'app_settings',
    ]) {
      expect(
        migrated.select('SELECT DISTINCT job_id FROM $table').map((r) => r['job_id']),
        anyOf(isEmpty, equals([kFirstJobId])),
        reason: table,
      );
    }
  });

  test('the job starts on the day tracking started', () {
    final jobs = migrated.select('SELECT * FROM jobs');
    expect(jobs, hasLength(1));
    expect(jobs.first['id'], kFirstJobId);
    expect(jobs.first['name'], 'Hochschule Karlsruhe');
    expect(jobs.first['end_date'], isNull);
    // Onboarding seeded 0:00 the day before tracking began.
    expect(jobs.first['starting_balance_hours'], 0.0);
    final start = DateTime.fromMillisecondsSinceEpoch((jobs.first['start_date'] as int) * 1000);
    expect(start, DateTime(2026, 3, 15));
  });

  test('vacation days are grouped into the four bookings they were', () {
    final groups = migrated.select('''
      SELECT vacation_id, GROUP_CONCAT(date(date, 'unixepoch', 'localtime'), ' ') AS days
      FROM (SELECT * FROM leave_entries WHERE type = 'vacation' ORDER BY date)
      GROUP BY vacation_id ORDER BY MIN(date)
    ''').map((r) => r['days']).toList();
    if (_isPinnedExport) expect(groups, [
      '2026-06-05',
      '2026-07-17 2026-07-20',
      '2026-08-31 2026-09-01 2026-09-02 2026-09-03 2026-09-04 '
          '2026-09-07 2026-09-08 2026-09-09 2026-09-10 2026-09-11',
      '2026-10-26 2026-10-27 2026-10-28 2026-10-29 2026-10-30',
    ]);
    expect(migrated.select('SELECT COUNT(*) AS n FROM vacations').first['n'], groups.length);
    expect(
      migrated.select("SELECT COUNT(*) AS n FROM leave_entries WHERE type != 'vacation' "
          'AND vacation_id IS NOT NULL').first['n'],
      0,
      reason: 'sick and flex days are not bookings',
    );
  });

  test('recalculating every day since the start reproduces every stored number', () async {
    // The strongest check there is on the job-aware engine: re-derive all
    // of it, from 15 March to the moment of the export, and compare with what
    // the pre-jobs engine had stored. Same day entries, same balances.
    final file = _copyOfBackup();
    final db = AppDatabase(NativeDatabase(file));
    // The export's own timestamp is in its file name: timemanager-YYYYMMDD-HHMMSS.
    final stamp = RegExp(r'(\d{8})-(\d{6})').firstMatch(_backup.path)!;
    final d = stamp.group(1)!, t = stamp.group(2)!;
    final exportedAt = DateTime(int.parse(d.substring(0, 4)), int.parse(d.substring(4, 6)),
        int.parse(d.substring(6)), int.parse(t.substring(0, 2)), int.parse(t.substring(2, 4)),
        int.parse(t.substring(4)));
    await RecalculationService(db, now: () => exportedAt)
        .recalculateRangeFrom(kFirstJobId, DateTime(2026, 3, 15));
    await db.close();
    final recomputed = _dump(file.path);

    String key(Map<String, Object?> row) => '${row['date']}';
    final days = {for (final row in recomputed['day_entries']!) key(row): row};
    for (final old in before['day_entries']!) {
      final now = days[key(old)];
      expect(now, isNotNull, reason: 'day ${old['date']} vanished');
      for (final column in ['net_worked_hours', 'leave_hours', 'target_hours', 'balance_delta']) {
        expect(now![column] as double, closeTo(old[column] as double, 1e-9),
            reason: '$column on ${DateTime.fromMillisecondsSinceEpoch((old['date'] as int) * 1000)}');
      }
    }
    expect(days.length, before['day_entries']!.length, reason: 'no day entries invented');

    final balances = {for (final row in recomputed['balance_snapshots']!) key(row): row};
    for (final old in before['balance_snapshots']!) {
      final now = balances[key(old)];
      expect(now, isNotNull, reason: 'snapshot ${old['date']} vanished');
      expect(now!['balance'] as double, closeTo(old['balance'] as double, 1e-9),
          reason: 'balance on ${DateTime.fromMillisecondsSinceEpoch((old['date'] as int) * 1000)}');
    }
  });

  test('a migration that fails leaves the v3 file exactly as it was', () async {
    final file = _copyOfBackup();
    // An orphaned session — a date with no day entry — is what a broken
    // rebuild would produce. Planting one makes the final check throw.
    final db = raw.sqlite3.open(file.path);
    db.execute("INSERT INTO work_sessions (id, date, start_time, status) "
        "VALUES ('orphan', 1, 1, 'completed')");
    db.close();
    final planted = _dump(file.path);

    await expectLater(
      _openAndMigrate(file),
      throwsA(predicate((e) => '$e'.contains('broken references'))),
    );

    final check = raw.sqlite3.open(file.path, mode: raw.OpenMode.readOnly);
    expect(check.userVersion, 3);
    expect(check.select("SELECT name FROM sqlite_master WHERE name = 'jobs'"), isEmpty);
    check.close();
    expect(_dump(file.path), planted);
  });
}
