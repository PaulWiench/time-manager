import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogEntries])
class AuditLogDao extends DatabaseAccessor<AppDatabase>
    with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  /// Entries are immutable — this DAO intentionally exposes no update or
  /// delete. See Data Model § AuditLogEntry.
  Future<int> record(AuditLogEntriesCompanion entry) =>
      into(auditLogEntries).insert(entry);

  Future<List<AuditLogEntry>> all({int limit = 200}) =>
      (select(auditLogEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  Future<List<AuditLogEntry>> forEntity(String entityType, String entityId) =>
      (select(auditLogEntries)
            ..where((t) =>
                t.entityType.equals(entityType) &
                t.entityId.equals(entityId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();
}
