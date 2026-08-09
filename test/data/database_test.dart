import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('DayEntry must exist before a WorkSession referencing its date', () async {
    final date = DateTime(2026, 8, 10);

    // Inserting the session first should fail the FK constraint.
    expect(
      () => db.workSessionDao.insertSession(
        WorkSessionsCompanion.insert(
          date: date,
          startTime: DateTime(2026, 8, 10, 8),
          status: SessionStatus.active,
        ),
      ),
      throwsA(anything),
    );

    await db.dayEntryDao.upsert(DayEntriesCompanion.insert(date: date));

    final sessionId = await db.workSessionDao.insertSession(
      WorkSessionsCompanion.insert(
        date: date,
        startTime: DateTime(2026, 8, 10, 8),
        status: SessionStatus.active,
      ),
    );
    expect(sessionId, isNonZero);

    final sessions = await db.workSessionDao.forDate(date);
    expect(sessions, hasLength(1));
    expect(sessions.single.status, SessionStatus.active);
    expect(sessions.single.id, isNotEmpty); // clientDefault UUID populated
  });

  test('break, leave, and holiday round-trip with their enum columns', () async {
    final date = DateTime(2026, 8, 10);
    await db.dayEntryDao.upsert(DayEntriesCompanion.insert(date: date));

    await db.breakEntryDao.insertBreak(BreakEntriesCompanion.insert(
      date: date,
      startTime: DateTime(2026, 8, 10, 12),
      endTime: DateTime(2026, 8, 10, 12, 30),
      type: BreakType.synthetic,
    ));
    final breaks = await db.breakEntryDao.forDate(date);
    expect(breaks.single.type, BreakType.synthetic);

    await db.leaveEntryDao.insertLeave(LeaveEntriesCompanion.insert(
      date: date,
      type: LeaveType.vacation,
      hours: 8.0,
    ));
    final leave = await db.leaveEntryDao.forDate(date);
    expect(leave.single.type, LeaveType.vacation);

    await db.publicHolidayDao.upsertHoliday(PublicHolidaysCompanion.insert(
      date: DateTime(2026, 12, 25),
      name: '1. Weihnachtstag',
      source: HolidaySource.auto,
    ));
    final holiday = await db.publicHolidayDao.forDate(DateTime(2026, 12, 25));
    expect(holiday?.fraction, 1.0);
  });

  test('AppSettings work-days converter defaults to Mon-Fri', () async {
    await db.settingsDao.insertSettings(AppSettingsCompanion.insert());
    final settings = await db.settingsDao.effectiveFor(DateTime.now());
    expect(settings?.workDays, [1, 2, 3, 4, 5]);
    expect(settings?.weeklyHours, 40.0);
  });

  test('balance snapshots support latestBefore lookups', () async {
    await db.balanceSnapshotDao.upsert(BalanceSnapshotsCompanion.insert(
      date: DateTime(2026, 8, 8),
      balance: 2.0,
    ));
    await db.balanceSnapshotDao.upsert(BalanceSnapshotsCompanion.insert(
      date: DateTime(2026, 8, 9),
      balance: 1.5,
    ));

    final latest = await db.balanceSnapshotDao.latestBefore(DateTime(2026, 8, 10));
    expect(latest?.balance, 1.5);
  });

  test('audit log entries are append-only and queryable by entity', () async {
    await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
      action: 'balance_edit',
      entityType: 'BalanceSnapshot',
      entityId: const Value('2026-08-09'),
      newValue: const Value('{"balance": 1.5}'),
    ));

    final entries = await db.auditLogDao.forEntity('BalanceSnapshot', '2026-08-09');
    expect(entries, hasLength(1));
    expect(entries.single.action, 'balance_edit');
  });
}
