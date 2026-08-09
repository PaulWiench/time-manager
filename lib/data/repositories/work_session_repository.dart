import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/date_only.dart';
import '../database/database.dart';
import '../database/enums.dart';
import 'recalculation_service.dart';

/// Everything session-related routes through here rather than the raw DAO,
/// so the "only one active session," "too-short sessions are discarded,"
/// and "every mutation triggers a recalculation" rules (Requirements § 1)
/// are enforced in one place instead of at every call site.
class WorkSessionRepository {
  final AppDatabase db;
  final RecalculationService recalc;

  WorkSessionRepository(this.db, this.recalc);

  Stream<List<WorkSession>> watchSessionsForDate(DateTime date) =>
      db.workSessionDao.watchForDate(dateOnly(date));

  Future<WorkSession?> activeSession() async {
    final active = await db.workSessionDao.activeSessions();
    return active.isEmpty ? null : active.first;
  }

  Future<void> checkIn(DateTime at) async {
    final active = await db.workSessionDao.activeSessions();
    if (active.isNotEmpty) {
      throw StateError('A session is already active');
    }

    final day = dateOnly(at);
    await db.transaction(() async {
      await db.dayEntryDao.upsert(DayEntriesCompanion.insert(date: day));
      await db.workSessionDao.insertSession(WorkSessionsCompanion.insert(
        date: day,
        startTime: at,
        status: SessionStatus.active,
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'create',
        entityType: 'WorkSession',
        newValue: Value(jsonEncode({'startTime': at.toIso8601String()})),
      ));
    });
    // No recalculation needed yet — an active session has no end time and
    // doesn't contribute to net worked hours until it's checked out.
  }

  /// Stops the active session at [at]. Sessions shorter than the
  /// configured minimum are discarded rather than completed (Requirements
  /// § 1), and are still written to the audit log.
  Future<void> checkOut({required String sessionId, required DateTime at}) async {
    final session = await db.workSessionDao.byId(sessionId);
    if (session == null) {
      throw ArgumentError('No session with id $sessionId');
    }

    final settings = await db.settingsDao.effectiveFor(dateOnly(session.date));
    final minMinutes = settings?.minSessionMinutes ?? 5;
    final duration = at.difference(session.startTime);
    final tooShort = duration.inMinutes < minMinutes;

    await db.transaction(() async {
      await db.workSessionDao.updateSession(WorkSessionsCompanion(
        id: Value(session.id),
        date: Value(session.date),
        startTime: Value(session.startTime),
        endTime: Value(at),
        status: Value(tooShort ? SessionStatus.discarded : SessionStatus.completed),
        updatedAt: Value(DateTime.now()),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: tooShort ? 'discard' : 'update',
        entityType: 'WorkSession',
        entityId: Value(session.id),
        newValue: Value(jsonEncode({
          'endTime': at.toIso8601String(),
          'discarded': tooShort,
        })),
      ));
    });

    await recalc.recalculateFrom(session.date);
  }

  /// Retroactive edit of a past session's boundaries. Requirements § 6:
  /// "Any past entry ... can be edited or deleted ... Balance recalculates
  /// immediately and retroactively."
  Future<void> editSession({
    required String sessionId,
    DateTime? start,
    DateTime? end,
    String? notes,
  }) async {
    final session = await db.workSessionDao.byId(sessionId);
    if (session == null) {
      throw ArgumentError('No session with id $sessionId');
    }

    final oldValue = jsonEncode({
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
    });
    final newStart = start ?? session.startTime;
    final newEnd = end ?? session.endTime;

    await db.transaction(() async {
      await db.workSessionDao.updateSession(WorkSessionsCompanion(
        id: Value(session.id),
        date: Value(dateOnly(newStart)),
        startTime: Value(newStart),
        endTime: Value(newEnd),
        status: Value(session.status),
        notes: Value(notes ?? session.notes),
        updatedAt: Value(DateTime.now()),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'WorkSession',
        entityId: Value(session.id),
        oldValue: Value(oldValue),
        newValue: Value(jsonEncode({
          'startTime': newStart.toIso8601String(),
          'endTime': newEnd?.toIso8601String(),
        })),
      ));
    });

    await recalc.recalculateFrom(session.date);
    final movedToNewDay = !dateOnly(newStart).isAtSameMomentAs(session.date);
    if (movedToNewDay) {
      await recalc.recalculateFrom(dateOnly(newStart));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final session = await db.workSessionDao.byId(sessionId);
    if (session == null) return;

    await db.transaction(() async {
      await db.workSessionDao.deleteSession(sessionId);
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'delete',
        entityType: 'WorkSession',
        entityId: Value(sessionId),
        oldValue: Value(jsonEncode({
          'startTime': session.startTime.toIso8601String(),
          'endTime': session.endTime?.toIso8601String(),
        })),
      ));
    });

    await recalc.recalculateFrom(session.date);
  }
}
