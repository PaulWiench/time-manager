import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/date_only.dart';
import '../database/database.dart';
import '../database/enums.dart';
import 'recalculation_service.dart';

/// Leave entries (vacation/sick/flex_day) — Requirements & Scope § 4.
class LeaveRepository {
  final AppDatabase db;
  final RecalculationService recalc;

  LeaveRepository(this.db, this.recalc);

  Stream<List<LeaveEntry>> watchForDate(DateTime date) =>
      db.leaveEntryDao.watchForDate(dateOnly(date));

  Future<List<LeaveEntry>> forYear(int year) => db.leaveEntryDao.forYear(year);

  Stream<List<LeaveEntry>> watchForYear(int year) =>
      db.leaveEntryDao.watchForYear(year);

  Future<void> addLeave({
    required DateTime date,
    required LeaveType type,
    required double hours,
    String? notes,
  }) async {
    final day = dateOnly(date);
    await db.transaction(() async {
      await db.dayEntryDao.upsert(DayEntriesCompanion.insert(date: day));
      final id = const Uuid().v4();
      await db.leaveEntryDao.insertLeave(LeaveEntriesCompanion.insert(
        id: Value(id),
        date: day,
        type: type,
        hours: hours,
        notes: Value(notes),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'create',
        entityType: 'LeaveEntry',
        entityId: Value(id),
        newValue: Value(jsonEncode({'type': type.name, 'hours': hours})),
      ));
    });
    await recalc.recalculateFrom(day);
  }

  /// Replaces the leave on every date in [hoursByDate] — one entry per day,
  /// whatever was there before.
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
  Future<void> setLeaveForDates({
    required Map<DateTime, double> hoursByDate,
    required LeaveType type,
    String? notes,
  }) async {
    if (hoursByDate.isEmpty) return;

    final days = {
      for (final entry in hoursByDate.entries) dateOnly(entry.key): entry.value,
    };
    final earliest = days.keys.reduce((a, b) => a.isBefore(b) ? a : b);

    await db.transaction(() async {
      for (final MapEntry(key: day, value: hours) in days.entries) {
        for (final existing in await db.leaveEntryDao.forDate(day)) {
          await db.leaveEntryDao.deleteLeave(existing.id);
          await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
            action: 'delete',
            entityType: 'LeaveEntry',
            entityId: Value(existing.id),
          ));
        }

        if (hours <= 0) continue;

        // LeaveEntries.date references DayEntries.date, so the day has to
        // exist before the leave can point at it.
        await db.dayEntryDao.upsert(DayEntriesCompanion.insert(date: day));
        final id = const Uuid().v4();
        await db.leaveEntryDao.insertLeave(LeaveEntriesCompanion.insert(
          id: Value(id),
          date: day,
          type: type,
          hours: hours,
          notes: Value(notes),
        ));
        await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
          action: 'create',
          entityType: 'LeaveEntry',
          entityId: Value(id),
          newValue: Value(jsonEncode({'type': type.name, 'hours': hours})),
        ));
      }
    });

    await recalc.recalculateRangeFrom(earliest);
  }

  /// Removes every leave entry on each of [dates], in one pass.
  Future<void> clearLeaveForDates(Iterable<DateTime> dates) async {
    final days = {for (final date in dates) dateOnly(date)};
    if (days.isEmpty) return;
    final earliest = days.reduce((a, b) => a.isBefore(b) ? a : b);

    await db.transaction(() async {
      for (final day in days) {
        for (final existing in await db.leaveEntryDao.forDate(day)) {
          await db.leaveEntryDao.deleteLeave(existing.id);
          await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
            action: 'delete',
            entityType: 'LeaveEntry',
            entityId: Value(existing.id),
          ));
        }
      }
    });

    await recalc.recalculateRangeFrom(earliest);
  }

  Future<void> deleteLeave(String id, DateTime date) async {
    await db.transaction(() async {
      await db.leaveEntryDao.deleteLeave(id);
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'delete',
        entityType: 'LeaveEntry',
        entityId: Value(id),
      ));
    });
    await recalc.recalculateFrom(date);
  }
}
