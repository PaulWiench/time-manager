import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

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
    // An active session has no end time and doesn't contribute to net
    // worked hours yet, but the DayEntry row was just created with default
    // (zero) target_hours — recalc so target/balance are correct while the
    // session is still running, not just after checkout.
    await recalc.recalculateFrom(day);
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

  /// Deletes [date]'s synthetic break and converts that time back to work,
  /// by flagging the DayEntry `auto_break_overridden` so recalculation
  /// never re-derives one for this date — Requirements § "tap a synthetic
  /// break to delete it ... flags the day so it's never silently
  /// reinserted." No confirmation dialog, per the UX doc.
  Future<void> deleteSyntheticBreak(DateTime date) async {
    final day = dateOnly(date);
    await db.transaction(() async {
      await db.dayEntryDao.upsert(DayEntriesCompanion(
        date: Value(day),
        autoBreakOverridden: const Value(true),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'DayEntry',
        entityId: Value(day.toIso8601String()),
        newValue: Value(jsonEncode({'autoBreakOverridden': true})),
      ));
    });
    await recalc.recalculateFrom(day);
  }

  /// Records a user-added break within a session's span. Per Data Model §
  /// DayEntry (see `domain/recalculation_engine.dart`'s doc comment), a
  /// manual break is treated as an annotation only — it doesn't reduce
  /// net worked hours the way the auto-break deduction does — so the
  /// recalc call here is just to keep `DayEntry.updatedAt` fresh, not
  /// because the numbers change.
  Future<void> addManualBreak({required DateTime date, required DateTime start, required DateTime end}) async {
    final day = dateOnly(date);
    final breakId = const Uuid().v4();
    await db.transaction(() async {
      await db.breakEntryDao.insertBreak(BreakEntriesCompanion.insert(
        id: Value(breakId),
        date: day,
        startTime: start,
        endTime: end,
        type: BreakType.manual,
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'create',
        entityType: 'BreakEntry',
        entityId: Value(breakId),
        newValue: Value(jsonEncode({
          'startTime': start.toIso8601String(),
          'endTime': end.toIso8601String(),
        })),
      ));
    });
    await recalc.recalculateFrom(day);
  }

  Future<void> updateManualBreak({required String breakId, required DateTime start, required DateTime end}) async {
    final existing = await (db.select(db.breakEntries)..where((t) => t.id.equals(breakId))).getSingleOrNull();
    if (existing == null) return;

    final oldValue = jsonEncode({
      'startTime': existing.startTime.toIso8601String(),
      'endTime': existing.endTime.toIso8601String(),
    });

    await db.transaction(() async {
      await db.breakEntryDao.updateBreak(BreakEntriesCompanion(
        id: Value(existing.id),
        date: Value(existing.date),
        startTime: Value(start),
        endTime: Value(end),
        type: Value(existing.type),
        updatedAt: Value(DateTime.now()),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'BreakEntry',
        entityId: Value(existing.id),
        oldValue: Value(oldValue),
        newValue: Value(jsonEncode({
          'startTime': start.toIso8601String(),
          'endTime': end.toIso8601String(),
        })),
      ));
    });
    await recalc.recalculateFrom(existing.date);
  }

  Future<void> deleteManualBreak(String breakId) async {
    final existing = await (db.select(db.breakEntries)..where((t) => t.id.equals(breakId))).getSingleOrNull();
    if (existing == null) return;

    await db.transaction(() async {
      await db.breakEntryDao.deleteBreak(breakId);
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'delete',
        entityType: 'BreakEntry',
        entityId: Value(breakId),
        oldValue: Value(jsonEncode({
          'startTime': existing.startTime.toIso8601String(),
          'endTime': existing.endTime.toIso8601String(),
        })),
      ));
    });
    await recalc.recalculateFrom(existing.date);
  }
}
