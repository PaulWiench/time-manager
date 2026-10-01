/// Booking a span of leave in one go.
///
/// The old path was `addLeave` per date. Each call cascades the balance from
/// its own date through today, so a fortnight cost a fortnight of cascades;
/// and a bare add on a date that already held leave double-counted it, against
/// the quota and against the day's balance alike.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/data/repositories/leave_repository.dart';
import 'package:time_manager/data/repositories/recalculation_service.dart';
import 'package:time_manager/data/repositories/settings_repository.dart';
import 'package:time_manager/data/repositories/vacation_quota_repository.dart';

void main() {
  /// The one job every test row belongs to.
  const j = 1;

  // Monday 5 October 2026 through Friday 16 October.
  final monday = DateTime(2026, 10, 5);
  DateTime day(int n) => DateTime(2026, 10, 5 + n);

  // A Friday, after every date the tests touch, so nothing is "in the future".
  final fixedNow = DateTime(2026, 10, 30);

  late AppDatabase db;
  late LeaveRepository leave;
  late VacationQuotaRepository quota;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.jobDao.insertJob(
      JobsCompanion.insert(id: const Value(j), name: 'Test', startDate: monday),
    );
    final recalc = RecalculationService(db, now: () => fixedNow);
    leave = LeaveRepository(db, recalc);
    quota = VacationQuotaRepository(db);

    await SettingsRepository(db, recalc).save(
      jobId: j,
      effectiveFrom: monday,
      weeklyHours: 39.5,
      workDays: const [1, 2, 3, 4, 5],
      minSessionMinutes: 5,
      autoBreakEnabled: true,
      restrictCheckin: false,
    );
  });

  tearDown(() => db.close());

  /// Mon 5 to Fri 16, weekends already dropped by the picker.
  Map<DateTime, double> fortnight({double hours = 7.9}) => {
        for (final n in [0, 1, 2, 3, 4, 7, 8, 9, 10, 11]) day(n): hours,
      };

  test('a fortnight is ten entries and ten balanced days', () async {
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );

    expect(await db.leaveEntryDao.forYear(j, 2026), hasLength(10));
    // Every booked day nets out: leave covers the target exactly.
    for (final n in [0, 4, 7, 11]) {
      final entry = await db.dayEntryDao.forDate(j, day(n));
      expect(entry!.leaveHours, closeTo(7.9, 0.001));
      expect(entry.balanceDelta, closeTo(0, 0.001));
    }
    // The weekend in the middle was never booked and has no row.
    expect(await db.dayEntryDao.forDate(j, day(5)), isNull);

    expect(await quota.usedDaysForYear(j, 2026), closeTo(10, 0.001));
  });

  test('booking over a day that already had leave replaces it', () async {
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: {day(0): 3.95},
      type: LeaveType.vacation,
    );
    expect(await quota.usedDaysForYear(j, 2026), closeTo(0.5, 0.001));

    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );

    // One entry on that date, not two — and ten days against the quota, not
    // ten and a half.
    expect(await db.leaveEntryDao.forDate(j, day(0)), hasLength(1));
    expect(await quota.usedDaysForYear(j, 2026), closeTo(10, 0.001));
    expect((await db.dayEntryDao.forDate(j, day(0)))!.leaveHours, closeTo(7.9, 0.001));
  });

  test('changing the type of a booked span does not stack the two', () async {
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.sick,
    );

    expect(await db.leaveEntryDao.forYear(j, 2026), hasLength(10));
    // Sick days do not come out of the vacation quota.
    expect(await quota.usedDaysForYear(j, 2026), closeTo(0, 0.001));
  });

  test('each date takes off its own hours', () async {
    // A half-day public holiday in the middle of the span: a full day of leave
    // on it is worth half of what its neighbours are.
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: {day(0): 7.9, day(1): 3.95, day(2): 7.9},
      type: LeaveType.vacation,
    );

    expect((await db.dayEntryDao.forDate(j, day(1)))!.leaveHours, closeTo(3.95, 0.001));
    // Still three whole days against the quota, because each is measured
    // against its own target.
    expect((await db.dayEntryDao.forDate(j, day(1)))!.balanceDelta, closeTo(-3.95, 0.001));
  });

  test('clearing a span removes every entry and settles the days', () async {
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );
    await leave.clearLeaveForDates(j, fortnight().keys);

    expect(await db.leaveEntryDao.forYear(j, 2026), isEmpty);
    expect(await quota.usedDaysForYear(j, 2026), closeTo(0, 0.001));
    // The day rows survive, now carrying the full shortfall they always had.
    expect((await db.dayEntryDao.forDate(j, day(0)))!.balanceDelta, closeTo(-7.9, 0.001));
  });

  test('an empty booking is a no-op rather than an error', () async {
    await leave.setLeaveForDates(jobId: j, hoursByDate: const {}, type: LeaveType.vacation);
    await leave.clearLeaveForDates(j, const []);
    expect(await db.leaveEntryDao.forYear(j, 2026), isEmpty);
  });

  test('the whole span lands in one balance cascade', () async {
    await leave.setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );

    // The cascade runs from the earliest booked date through today, writing a
    // snapshot per day and nothing beyond it. Ten separate `addLeave` calls
    // would each have walked the same stretch.
    final snapshots =
        await db.balanceSnapshotDao.forRange(j, monday, DateTime(2026, 11, 30));
    expect(snapshots.first.date, monday);
    expect(snapshots.last.date, fixedNow);
  });

  test('a vacation booked entirely ahead of today is worked out on every day', () async {
    // Found on the phone (1 Oct 2026): 26–30 Oct booked in advance had leave
    // and target on the 26th only. recalculateRangeFrom ran to today or its
    // own start, whichever was later, so for a future booking that was the
    // first day alone, and Stats counted one planned day instead of five.
    final early = RecalculationService(db, now: () => DateTime(2026, 9, 28));
    await LeaveRepository(db, early).setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );
    for (final n in [0, 1, 4, 7, 11]) {
      final entry = await db.dayEntryDao.forDate(j, day(n));
      expect(entry!.leaveHours, closeTo(7.9, 0.001), reason: 'day $n');
      expect(entry.targetHours, closeTo(7.9, 0.001), reason: 'day $n');
    }
  });

  test('days stored before that fix are repaired at launch', () async {
    final early = RecalculationService(db, now: () => DateTime(2026, 9, 28));
    await LeaveRepository(db, early).setLeaveForDates(
      jobId: j,
      hoursByDate: fortnight(),
      type: LeaveType.vacation,
    );
    // Put a day back the way the old code left it.
    await (db.update(db.dayEntries)..where((t) => t.date.equals(day(3))))
        .write(const DayEntriesCompanion(targetHours: Value(0), leaveHours: Value(0)));

    await early.refreshFutureDays();

    final repaired = await db.dayEntryDao.forDate(j, day(3));
    expect(repaired!.leaveHours, closeTo(7.9, 0.001));
    expect(repaired.targetHours, closeTo(7.9, 0.001));
  });

  group('named bookings', () {
    Future<String> bookFortnight({String? name}) async {
      await leave.setLeaveForDates(
        jobId: j,
        hoursByDate: fortnight(),
        type: LeaveType.vacation,
        vacationName: name,
      );
      return (await db.leaveEntryDao.forDate(j, day(0))).single.vacationId!;
    }

    test('a booking is one vacation, named once for all its days', () async {
      final id = await bookFortnight(name: '  Sommer an der Ostsee  ');
      final entries = await db.leaveEntryDao.forVacation(id);
      expect(entries, hasLength(10));
      expect((await db.jobDao.vacationById(id))!.name, 'Sommer an der Ostsee');

      await leave.renameVacation(id, 'Ostsee');
      expect((await db.jobDao.vacationById(id))!.name, 'Ostsee');
      await leave.renameVacation(id, '   ');
      expect((await db.jobDao.vacationById(id))!.name, isNull, reason: 'blank is unnamed');
    });

    test('moving a booking keeps its name and rebooks only scheduled days', () async {
      final id = await bookFortnight(name: 'Ostsee');
      // Mon 19 – Sun 25 Oct: five workdays.
      await leave.moveVacation(vacationId: id, first: day(14), last: day(20));

      final entries = await db.leaveEntryDao.forVacation(id);
      expect(entries.map((e) => e.date), [for (final n in [14, 15, 16, 17, 18]) day(n)]);
      expect((await db.jobDao.vacationById(id))!.name, 'Ostsee');
      // The old fortnight is no longer leave and owes its target again.
      final freed = await db.dayEntryDao.forDate(j, day(0));
      expect(freed!.leaveHours, 0);
      expect(await db.leaveEntryDao.forYear(j, 2026), hasLength(5));
    });

    test('clearing every day of a booking removes the booking', () async {
      final id = await bookFortnight(name: 'Ostsee');
      await leave.clearLeaveForDates(j, fortnight().keys);
      expect(await db.jobDao.vacationById(id), isNull);
    });

    test('sick days are not bookings', () async {
      await leave.setLeaveForDates(jobId: j, hoursByDate: {day(0): 7.9}, type: LeaveType.sick);
      expect((await db.leaveEntryDao.forDate(j, day(0))).single.vacationId, isNull);
      expect(await db.select(db.vacations).get(), isEmpty);
    });
  });
}
