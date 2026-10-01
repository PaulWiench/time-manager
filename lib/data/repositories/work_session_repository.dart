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

  Stream<List<WorkSession>> watchSessionsForDate(int jobId, DateTime date) =>
      db.workSessionDao.watchForDate(jobId, dateOnly(date));

  Future<WorkSession?> activeSession(int jobId) async {
    final active = await db.workSessionDao.activeSessions(jobId);
    return active.isEmpty ? null : active.first;
  }

  /// Starts a session for [jobId]. Jobs run independently, so another job's
  /// running session does not stop this one; the same job twice does.
  ///
  /// An ended job cannot be checked in to — not even at a time before its
  /// end, which is what editing History is for.
  Future<void> checkIn(int jobId, DateTime at) async {
    final job = await db.jobDao.byId(jobId);
    if (job == null) throw ArgumentError('No job with id $jobId');
    if (job.endDate != null) throw StateError('${job.name} has ended');
    final active = await db.workSessionDao.activeSessions(jobId);
    if (active.isNotEmpty) {
      throw StateError('A session is already active');
    }

    final day = dateOnly(at);
    await db.transaction(() async {
      await db.dayEntryDao.ensure(jobId, day);
      await db.workSessionDao.insertSession(WorkSessionsCompanion.insert(
        jobId: Value(jobId),
        date: day,
        startTime: at,
        status: SessionStatus.active,
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'create',
        entityType: 'WorkSession',
        newValue: Value(jsonEncode({'jobId': jobId, 'startTime': at.toIso8601String()})),
      ));
    });
    // An active session has no end time and doesn't contribute to net
    // worked hours yet, but the DayEntry row was just created with default
    // (zero) target_hours — recalc so target/balance are correct while the
    // session is still running, not just after checkout.
    await recalc.recalculateFrom(jobId, day);
  }

  /// "Started earlier?": moves the running session's start back to
  /// [newStart]. Only earlier, never into the previous session of the same
  /// day, never before the day began — the sheet enforces the same limits,
  /// this is what holds if it ever does not.
  Future<void> moveActiveStart({required String sessionId, required DateTime newStart}) async {
    final session = await db.workSessionDao.byId(sessionId);
    if (session == null || session.status != SessionStatus.active) {
      throw StateError('Only a running session can be moved');
    }
    if (!newStart.isBefore(session.startTime)) {
      throw ArgumentError('The new start must be earlier than the current one');
    }
    if (dateOnly(newStart) != session.date) {
      throw ArgumentError('A session cannot start before its own day');
    }
    final previous =
        await db.workSessionDao.lastCompletedBefore(session.jobId, session.date, session.startTime);
    if (previous != null && newStart.isBefore(previous.endTime!)) {
      throw ArgumentError('That overlaps the session that ended at ${previous.endTime}');
    }
    await editSession(sessionId: sessionId, start: newStart);
  }

  /// "Check in at…": the user was on break and forgot to check back in.
  /// Starts a running session at [at], which lies between the last check-out
  /// and now. Checking in exactly at the last check-out means there was no
  /// break at all, so the two become one session again.
  Future<void> checkInAt(int jobId, DateTime at, {DateTime? now}) async {
    final clock = now ?? DateTime.now();
    if (at.isAfter(clock)) throw ArgumentError('That is in the future');
    final day = dateOnly(at);
    final last = await db.workSessionDao.lastCompletedBefore(jobId, day, clock);
    if (last != null && at.isBefore(last.endTime!)) {
      throw ArgumentError('You checked out at ${last.endTime}');
    }
    if (last != null && at.isAtSameMomentAs(last.endTime!)) {
      await db.transaction(() async {
        await db.workSessionDao.updateSession(WorkSessionsCompanion(
          id: Value(last.id),
          jobId: Value(last.jobId),
          date: Value(last.date),
          startTime: Value(last.startTime),
          endTime: const Value(null),
          status: const Value(SessionStatus.active),
          notes: Value(last.notes),
          createdAt: Value(last.createdAt),
          updatedAt: Value(DateTime.now()),
        ));
        await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
          action: 'update',
          entityType: 'WorkSession',
          entityId: Value(last.id),
          oldValue: Value(jsonEncode({'endTime': last.endTime!.toIso8601String()})),
          newValue: Value(jsonEncode({'endTime': null, 'resumed': true})),
        ));
      });
      await recalc.recalculateFrom(jobId, day);
      return;
    }
    await checkIn(jobId, at);
  }

  /// Stops the active session at [at]. Sessions shorter than the
  /// configured minimum are discarded rather than completed (Requirements
  /// § 1), and are still written to the audit log.
  Future<void> checkOut({required String sessionId, required DateTime at}) async {
    final session = await db.workSessionDao.byId(sessionId);
    if (session == null) {
      throw ArgumentError('No session with id $sessionId');
    }

    final settings = await db.settingsDao.effectiveFor(session.jobId, dateOnly(session.date));
    final minMinutes = settings?.minSessionMinutes ?? 5;
    final duration = at.difference(session.startTime);
    final tooShort = duration.inMinutes < minMinutes;

    await db.transaction(() async {
      await db.workSessionDao.updateSession(WorkSessionsCompanion(
        id: Value(session.id),
        jobId: Value(session.jobId),
        date: Value(session.date),
        startTime: Value(session.startTime),
        endTime: Value(at),
        status: Value(tooShort ? SessionStatus.discarded : SessionStatus.completed),
        notes: Value(session.notes),
        createdAt: Value(session.createdAt),
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

    await recalc.recalculateFrom(session.jobId, session.date);
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
      // A start moved onto another day points the session at that day.
      await db.dayEntryDao.ensure(session.jobId, dateOnly(newStart));
      await db.workSessionDao.updateSession(WorkSessionsCompanion(
        id: Value(session.id),
        jobId: Value(session.jobId),
        date: Value(dateOnly(newStart)),
        startTime: Value(newStart),
        endTime: Value(newEnd),
        status: Value(session.status),
        notes: Value(notes ?? session.notes),
        createdAt: Value(session.createdAt),
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

    await recalc.recalculateFrom(session.jobId, session.date);
    final movedToNewDay = !dateOnly(newStart).isAtSameMomentAs(session.date);
    if (movedToNewDay) {
      await recalc.recalculateFrom(session.jobId, dateOnly(newStart));
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

    await recalc.recalculateFrom(session.jobId, session.date);
  }

  /// Deletes [date]'s synthetic break and converts that time back to work,
  /// by flagging the DayEntry `auto_break_overridden` so recalculation
  /// never re-derives one for this date — Requirements § "tap a synthetic
  /// break to delete it ... flags the day so it's never silently
  /// reinserted." No confirmation dialog, per the UX doc.
  Future<void> deleteSyntheticBreak(int jobId, DateTime date) async {
    final day = dateOnly(date);
    await db.transaction(() async {
      await db.dayEntryDao.ensure(jobId, day);
      await (db.update(db.dayEntries)
            ..where((t) => t.jobId.equals(jobId) & t.date.equals(day)))
          .write(const DayEntriesCompanion(autoBreakOverridden: Value(true)));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'DayEntry',
        entityId: Value(day.toIso8601String()),
        newValue: Value(jsonEncode({'autoBreakOverridden': true})),
      ));
    });
    await recalc.recalculateFrom(jobId, day);
  }

  /// Records a user-added break within a session's span. Per Data Model §
  /// DayEntry (see `domain/recalculation_engine.dart`'s doc comment), a
  /// manual break is treated as an annotation only — it doesn't reduce
  /// net worked hours the way the auto-break deduction does — so the
  /// recalc call here is just to keep `DayEntry.updatedAt` fresh, not
  /// because the numbers change.
  Future<void> addManualBreak({
    required int jobId,
    required DateTime date,
    required DateTime start,
    required DateTime end,
  }) async {
    final day = dateOnly(date);
    final breakId = const Uuid().v4();
    await db.transaction(() async {
      await db.dayEntryDao.ensure(jobId, day);
      await db.breakEntryDao.insertBreak(BreakEntriesCompanion.insert(
        id: Value(breakId),
        jobId: Value(jobId),
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
    await recalc.recalculateFrom(jobId, day);
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
        jobId: Value(existing.jobId),
        date: Value(existing.date),
        startTime: Value(start),
        endTime: Value(end),
        type: Value(existing.type),
        createdAt: Value(existing.createdAt),
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
    await recalc.recalculateFrom(existing.jobId, existing.date);
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
    await recalc.recalculateFrom(existing.jobId, existing.date);
  }
}
