import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/data/repositories/job_repository.dart';
import 'package:time_manager/data/repositories/leave_repository.dart';
import 'package:time_manager/data/repositories/recalculation_service.dart';
import 'package:time_manager/data/repositories/work_session_repository.dart';

void main() {
  // Wednesday 14 Oct 2026, 18:00.
  final now = DateTime(2026, 10, 14, 18);
  DateTime day(int d, [int h = 0, int m = 0]) => DateTime(2026, 10, d, h, m);

  late AppDatabase db;
  late RecalculationService recalc;
  late WorkSessionRepository sessions;
  late JobRepository jobs;
  late LeaveRepository leave;

  Future<int> create(String name, {double weekly = 40, List<int> days = const [1, 2, 3, 4, 5],
      double starting = 0, DateTime? start}) {
    return jobs.createJob(
      name: name,
      startDate: start ?? day(12),
      weeklyHours: weekly,
      workDays: days,
      workWindowStartMinutes: 8 * 60,
      workWindowEndMinutes: 18 * 60,
      startingBalanceHours: starting,
      vacationDaysPerYear: 30,
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recalc = RecalculationService(db, now: () => now);
    sessions = WorkSessionRepository(db, recalc);
    jobs = JobRepository(db, recalc, sessions);
    leave = LeaveRepository(db, recalc);
  });

  tearDown(() => db.close());

  test('a new job starts from its own balance and settles its missed days', () async {
    final id = await create('Lecturing', weekly: 6, days: [2, 4], starting: 1.5);
    // Mon 12: rest day for this job; Tue 13: missed (3 h); Wed 14: today.
    final tuesday = await db.balanceSnapshotDao.forDate(id, day(13));
    expect(tuesday!.balance, closeTo(1.5 - 3, 1e-9));
    final settings = await db.settingsDao.effectiveFor(id, day(14));
    expect(settings!.weeklyHours, 6);
    expect((await db.vacationQuotaDao.forYear(id, 2026))!.totalDays, 30);
  });

  test('two jobs keep separate days, balances and running sessions', () async {
    final a = await create('Research', start: day(5));
    final b = await create('Lecturing', weekly: 6, days: [2, 4], start: day(5));

    await sessions.checkIn(a, day(13, 8));
    // The other job can run at the same time.
    await sessions.checkIn(b, day(13, 9));
    expect(await sessions.activeSession(a), isNotNull);
    expect(await sessions.activeSession(b), isNotNull);
    expect(() => sessions.checkIn(a, day(13, 10)), throwsStateError, reason: 'one per job');

    await sessions.checkOut(sessionId: (await sessions.activeSession(a))!.id, at: day(13, 16));
    await sessions.checkOut(sessionId: (await sessions.activeSession(b))!.id, at: day(13, 12));

    final dayA = (await db.dayEntryDao.forDate(a, day(13)))!;
    final dayB = (await db.dayEntryDao.forDate(b, day(13)))!;
    expect(dayA.netWorkedHours, closeTo(7.5, 1e-9), reason: '8 h less the 30 min break');
    expect(dayA.targetHours, 8);
    expect(dayB.netWorkedHours, 3);
    expect(dayB.targetHours, 3);
    // Leave on one job is not leave on the other.
    await leave.setLeaveForDates(jobId: b, hoursByDate: {day(15): 3}, type: LeaveType.vacation);
    expect(await db.leaveEntryDao.forDate(a, day(15)), isEmpty);
  });

  test('ending a job checks out its running session and stops its shortfall', () async {
    final id = await create('Lecturing', start: day(5));
    await sessions.checkIn(id, day(14, 9));

    await jobs.endJob(id, day(14), now: day(14, 17));

    expect(await sessions.activeSession(id), isNull);
    final job = (await db.jobDao.byId(id))!;
    expect(job.endDate, day(14));
    expect(() => sessions.checkIn(id, day(14, 17, 30)), throwsStateError, reason: 'ended');

    // A day after the end owes nothing.
    await recalc.recalculateRangeFrom(id, day(14));
    final balanceAtEnd = (await db.balanceSnapshotDao.forDate(id, day(14)))!.balance;
    final later = RecalculationService(db, now: () => DateTime(2026, 10, 20, 12));
    await later.recalculateRangeFrom(id, day(14));
    expect((await db.balanceSnapshotDao.forDate(id, DateTime(2026, 10, 19)))!.balance,
        balanceAtEnd);

    await jobs.reopenJob(id);
    expect((await db.jobDao.byId(id))!.endDate, isNull);
  });

  test('dates that would orphan tracked time are refused', () async {
    final id = await create('Research', start: day(5));
    await sessions.checkIn(id, day(7, 9));
    await sessions.checkOut(sessionId: (await sessions.activeSession(id))!.id, at: day(7, 12));

    Future<void> update({required DateTime start, DateTime? end}) => jobs.updateJob(id,
        name: 'Research', startDate: start, endDate: end, startingBalanceHours: 0);

    expect(() => update(start: day(8)), throwsA(isA<JobDatesError>()));
    expect(() => update(start: day(5), end: day(6)), throwsA(isA<JobDatesError>()));
    expect(() => update(start: day(5), end: day(4)), throwsA(isA<JobDatesError>()));
    await update(start: day(1));
    expect((await db.jobDao.byId(id))!.startDate, day(1));
    // Moving the start earlier carries the schedule back with it.
    expect(await db.settingsDao.effectiveFor(id, day(1)), isNotNull);
  });

  test('the selected job is remembered and falls back to an active one', () async {
    final a = await create('Research');
    final b = await create('Lecturing');
    expect(await jobs.watchSelectedId().first, a, reason: 'first active by start date');
    await jobs.select(b);
    expect(await jobs.watchSelectedId().first, b);
  });
}
