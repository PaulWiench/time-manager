import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/date_only.dart';
import '../database/database.dart';
import '../database/enums.dart';
import 'recalculation_service.dart';

/// Leave entries (vacation/sick/flex_day) — Requirements & Scope § 4.
///
/// Leave belongs to one job. Vacation is booked in [Vacations]: the days one
/// booking wrote share a vacation row, which is where the booking's optional
/// name lives.
class LeaveRepository {
  final AppDatabase db;
  final RecalculationService recalc;

  LeaveRepository(this.db, this.recalc);

  Stream<List<LeaveEntry>> watchForDate(int jobId, DateTime date) =>
      db.leaveEntryDao.watchForDate(jobId, dateOnly(date));

  Future<List<LeaveEntry>> forYear(int jobId, int year) =>
      db.leaveEntryDao.forYear(jobId, year);

  Stream<List<LeaveEntry>> watchForYear(int jobId, int year) =>
      db.leaveEntryDao.watchForYear(jobId, year);

  Future<void> addLeave({
    required int jobId,
    required DateTime date,
    required LeaveType type,
    required double hours,
    String? notes,
  }) =>
      setLeaveForDates(jobId: jobId, hoursByDate: {date: hours}, type: type, notes: notes);

  /// Replaces [jobId]'s leave on every date in [hoursByDate] — one entry per
  /// day, whatever was there before.
  ///
  /// Booking a fortnight one `addLeave` at a time is wrong twice over. Each
  /// call cascades the balance from its own date through today, so ten days
  /// costs ten cascades; and a bare add on a date that already has leave
  /// double-counts it, against both the quota and the day's balance. So the
  /// whole booking is one transaction with a single cascade from the earliest
  /// date, and every date is cleared before it is written.
  ///
  /// Hours are per date rather than one figure for the set: a half-day public
  /// holiday inside a fortnight is worth half of what its neighbours are.
  ///
  /// Vacation days become one booking, named [vacationName] (trimmed; empty
  /// means unnamed), or join [vacationId] when re-booking an existing one.
  Future<void> setLeaveForDates({
    required int jobId,
    required Map<DateTime, double> hoursByDate,
    required LeaveType type,
    String? notes,
    String? vacationName,
    String? vacationId,
  }) async {
    if (hoursByDate.isEmpty) return;

    final days = {
      for (final entry in hoursByDate.entries) dateOnly(entry.key): entry.value,
    };
    final earliest = days.keys.reduce((a, b) => a.isBefore(b) ? a : b);

    await db.transaction(() async {
      String? booking;
      if (type == LeaveType.vacation && days.values.any((h) => h > 0)) {
        booking = vacationId ??
            (await db.into(db.vacations).insertReturning(VacationsCompanion.insert(
              jobId: jobId,
              name: Value(_cleanName(vacationName)),
            )))
                .id;
      }

      for (final MapEntry(key: day, value: hours) in days.entries) {
        await _clearDay(jobId, day);
        if (hours <= 0) continue;

        // LeaveEntries point at their (job, date) day, so it has to exist
        // before the leave can point at it.
        await db.dayEntryDao.ensure(jobId, day);
        final id = const Uuid().v4();
        await db.leaveEntryDao.insertLeave(LeaveEntriesCompanion.insert(
          id: Value(id),
          jobId: Value(jobId),
          date: day,
          type: type,
          hours: hours,
          notes: Value(notes),
          vacationId: Value(booking),
        ));
        await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
          action: 'create',
          entityType: 'LeaveEntry',
          entityId: Value(id),
          newValue: Value(jsonEncode({'jobId': jobId, 'type': type.name, 'hours': hours})),
        ));
      }
      await _dropEmptyVacations();
    });

    await recalc.recalculateRangeFrom(jobId, earliest);
  }

  /// Removes every one of [jobId]'s leave entries on each of [dates], in one
  /// pass.
  Future<void> clearLeaveForDates(int jobId, Iterable<DateTime> dates) async {
    final days = {for (final date in dates) dateOnly(date)};
    if (days.isEmpty) return;
    final earliest = days.reduce((a, b) => a.isBefore(b) ? a : b);

    await db.transaction(() async {
      for (final day in days) {
        await _clearDay(jobId, day);
      }
      await _dropEmptyVacations();
    });

    await recalc.recalculateRangeFrom(jobId, earliest);
  }

  Future<void> deleteLeave(String id, DateTime date) async {
    final entry = await (db.select(db.leaveEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return;
    await db.transaction(() async {
      await db.leaveEntryDao.deleteLeave(id);
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'delete',
        entityType: 'LeaveEntry',
        entityId: Value(id),
      ));
      await _dropEmptyVacations();
    });
    await recalc.recalculateFrom(entry.jobId, date);
  }

  /// Renames every day of one booking at once — the name lives on the booking.
  Future<void> renameVacation(String vacationId, String? name) async {
    final before = await db.jobDao.vacationById(vacationId);
    if (before == null) return;
    final clean = _cleanName(name);
    await db.transaction(() async {
      await db.jobDao.renameVacation(vacationId, clean);
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'Vacation',
        entityId: Value(vacationId),
        oldValue: Value(jsonEncode({'name': before.name})),
        newValue: Value(jsonEncode({'name': clean})),
      ));
    });
  }

  /// Moves a booking to new dates: its old days are cleared and the new ones
  /// are written under the same booking, so it keeps its name.
  Future<void> rebookVacation({
    required String vacationId,
    required Map<DateTime, double> hoursByDate,
  }) async {
    final vacation = await db.jobDao.vacationById(vacationId);
    if (vacation == null) return;
    final oldDates = [
      for (final entry in await db.leaveEntryDao.forVacation(vacationId)) entry.date,
    ];
    await db.transaction(() async {
      for (final day in oldDates) {
        await _clearDay(vacation.jobId, day);
      }
    });
    // The booking row is only dropped once it has no days at all, which
    // setLeaveForDates checks after writing the new ones.
    await setLeaveForDates(
      jobId: vacation.jobId,
      hoursByDate: hoursByDate,
      type: LeaveType.vacation,
      vacationId: vacationId,
    );
    if (oldDates.isNotEmpty) {
      final earliest = oldDates.reduce((a, b) => a.isBefore(b) ? a : b);
      await recalc.recalculateRangeFrom(vacation.jobId, earliest);
    }
  }

  Future<void> _clearDay(int jobId, DateTime day) async {
    for (final existing in await db.leaveEntryDao.forDate(jobId, day)) {
      await db.leaveEntryDao.deleteLeave(existing.id);
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'delete',
        entityType: 'LeaveEntry',
        entityId: Value(existing.id),
      ));
    }
  }

  /// A booking whose every day was cleared or re-booked elsewhere is gone.
  Future<void> _dropEmptyVacations() => db.customUpdate(
        'DELETE FROM vacations WHERE id NOT IN '
        '(SELECT vacation_id FROM leave_entries WHERE vacation_id IS NOT NULL)',
        updates: {db.vacations},
        updateKind: UpdateKind.delete,
      );

  static String? _cleanName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
  }
}
