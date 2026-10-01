/// Schema v3 -> v4: jobs, and named vacations.
///
/// The only database this will ever run on for real is the one on Paul's
/// phone, holding every tracked day since March 2026. So it is written to fail
/// whole or not at all:
///
/// - Everything happens inside one transaction. Drift writes the new
///   `user_version` only after `onUpgrade` returns, so a throw anywhere below
///   rolls the file back to exactly the v3 it was, and the next launch tries
///   again from v3 rather than from a half-migrated mix.
/// - Before committing it compares every table's row count with the count it
///   started from, and runs `PRAGMA foreign_key_check`. Any difference throws,
///   which is the rollback above.
///
/// Foreign keys are off while it runs. They have to be — a table rebuild
/// drops and recreates tables other tables point at — and they are anyway:
/// `beforeOpen` is what turns them on, and it runs after migrations. The
/// pragma below only makes that explicit; it cannot be changed inside the
/// transaction, which is why it comes first.
library;

import 'package:drift/drift.dart';

import 'database.dart';

/// The job every pre-v4 row belongs to.
const int kFirstJobId = 1;
const String kFirstJobName = 'Hochschule Karlsruhe';

/// Tables whose rows must all survive, by name. `app_settings` gains a column
/// in place; the rest are rebuilt.
const _carriedTables = [
  'work_sessions',
  'break_entries',
  'leave_entries',
  'public_holidays',
  'day_entries',
  'balance_snapshots',
  'vacation_quotas',
  'app_settings',
  'audit_log_entries',
];

Future<void> migrateToV4(AppDatabase db, Migrator m) async {
  await db.customStatement('PRAGMA foreign_keys = OFF');

  await db.transaction(() async {
    final before = await _rowCounts(db);

    await m.createTable(db.jobs);
    await m.createTable(db.vacations);
    await m.createTable(db.appPreferences);

    // The job starts where the settings history starts: onboarding wrote the
    // first row with the tracking start as its effectiveFrom.
    final firstEffective = await db
        .customSelect('SELECT MIN(effective_from) AS d FROM app_settings')
        .map((row) => row.read<DateTime?>('d'))
        .getSingle();
    final now = DateTime.now();
    final start = firstEffective ?? DateTime(now.year, now.month, now.day);
    // The starting balance onboarding seeded is the snapshot the day before
    // the start; it moves onto the job, where the cascade now looks for it.
    final startDay = DateTime(start.year, start.month, start.day);
    final seeded = await db
        .customSelect(
          'SELECT balance FROM balance_snapshots WHERE date < ? ORDER BY date DESC LIMIT 1',
          variables: [Variable<DateTime>(startDay)],
        )
        .map((row) => row.read<double>('balance'))
        .getSingleOrNull();
    await db.into(db.jobs).insert(JobsCompanion.insert(
          id: const Value(kFirstJobId),
          name: kFirstJobName,
          startDate: startDay,
          startingBalanceHours: Value(seeded ?? 0),
        ));

    // Parents before children, so every rebuilt child is created against the
    // new (job_id, date) key it points at.
    for (final rebuild in <(TableInfo, GeneratedColumn<int>)>[
      (db.dayEntries, db.dayEntries.jobId),
      (db.balanceSnapshots, db.balanceSnapshots.jobId),
      (db.vacationQuotas, db.vacationQuotas.jobId),
      (db.workSessions, db.workSessions.jobId),
      (db.breakEntries, db.breakEntries.jobId),
    ]) {
      final (table, jobId) = rebuild;
      await m.alterTable(TableMigration(
        table,
        newColumns: [jobId],
        columnTransformer: {jobId: const Constant(kFirstJobId)},
      ));
    }
    await m.alterTable(TableMigration(
      db.leaveEntries,
      newColumns: [db.leaveEntries.jobId, db.leaveEntries.vacationId],
      columnTransformer: {
        db.leaveEntries.jobId: const Constant(kFirstJobId),
        db.leaveEntries.vacationId: const Constant<String>(null),
      },
    ));
    await m.addColumn(db.appSettings, db.appSettings.jobId);

    await _groupVacations(db);

    final after = await _rowCounts(db);
    for (final table in _carriedTables) {
      if (before[table] != after[table]) {
        throw StateError(
          'v4 migration changed the row count of $table '
          '(${before[table]} -> ${after[table]}); rolled back',
        );
      }
    }
    final orphans = await db.customSelect('PRAGMA foreign_key_check').get();
    if (orphans.isNotEmpty) {
      throw StateError(
        'v4 migration left ${orphans.length} broken references '
        '(first: ${orphans.first.data}); rolled back',
      );
    }
    final unassigned = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM leave_entries '
          "WHERE type = 'vacation' AND vacation_id IS NULL",
        )
        .map((row) => row.read<int>('n'))
        .getSingle();
    if (unassigned != 0) {
      throw StateError('v4 migration left $unassigned vacation days unbooked');
    }

    await db.into(db.auditLogEntries).insert(AuditLogEntriesCompanion.insert(
          action: 'migrate',
          entityType: 'Database',
          newValue: Value('{"schemaVersion":4,"job":"$kFirstJobName",'
              '"jobStart":"${start.toIso8601String()}"}'),
        ));
  });
}

Future<Map<String, int>> _rowCounts(AppDatabase db) async => {
      for (final table in _carriedTables)
        table: await db
            .customSelect('SELECT COUNT(*) AS n FROM $table')
            .map((row) => row.read<int>('n'))
            .getSingle(),
    };

/// Turns the vacation days already on record into bookings.
///
/// Leave was written one row per day with nothing tying a fortnight together.
/// Days belong to the same booking when nothing but rest days lies between
/// them — 17 July (Friday) and 20 July (Monday) are one vacation, 5 June and
/// 17 July are two. A rest day is a weekday outside the work days in force at
/// the time, or a full public holiday.
Future<void> _groupVacations(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT id, date FROM leave_entries WHERE type = 'vacation' ORDER BY date",
      )
      .get();
  if (rows.isEmpty) return;

  final holidays = {
    for (final row in await db
        .customSelect(
          "SELECT date FROM public_holidays WHERE source != 'removed' AND fraction >= 1",
        )
        .get())
      _day(row.read<DateTime>('date')),
  };
  final settings = await db
      .customSelect(
        'SELECT effective_from, work_days FROM app_settings '
        'ORDER BY effective_from, created_at',
      )
      .get();

  bool isWorkday(DateTime day) {
    var workDays = '1,2,3,4,5';
    for (final row in settings) {
      if (_day(row.read<DateTime>('effective_from')).isAfter(day)) break;
      workDays = row.read<String>('work_days');
    }
    final weekdays = workDays.isEmpty ? <int>{} : workDays.split(',').map(int.parse).toSet();
    return weekdays.contains(day.weekday) && !holidays.contains(day);
  }

  bool onlyRestDaysBetween(DateTime a, DateTime b) {
    for (var d = DateTime(a.year, a.month, a.day + 1);
        d.isBefore(b);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (isWorkday(d)) return false;
    }
    return true;
  }

  final groups = <List<String>>[];
  DateTime? previous;
  for (final row in rows) {
    final day = _day(row.read<DateTime>('date'));
    if (previous == null || !onlyRestDaysBetween(previous, day)) groups.add([]);
    groups.last.add(row.read<String>('id'));
    previous = day;
  }

  for (final ids in groups) {
    final vacationId = await db
        .into(db.vacations)
        .insertReturning(VacationsCompanion.insert(jobId: kFirstJobId))
        .then((v) => v.id);
    for (final id in ids) {
      await db.customUpdate(
        'UPDATE leave_entries SET vacation_id = ? WHERE id = ?',
        variables: [Variable<String>(vacationId), Variable<String>(id)],
        updates: {db.leaveEntries},
      );
    }
  }
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
