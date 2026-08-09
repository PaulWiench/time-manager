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
