import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'break_entry_dao.g.dart';

@DriftAccessor(tables: [BreakEntries])
class BreakEntryDao extends DatabaseAccessor<AppDatabase>
    with _$BreakEntryDaoMixin {
  BreakEntryDao(super.db);

  Future<List<BreakEntry>> forDate(DateTime date) =>
      (select(breakEntries)..where((t) => t.date.equals(date))).get();

  Stream<List<BreakEntry>> watchForDate(DateTime date) =>
      (select(breakEntries)..where((t) => t.date.equals(date))).watch();

  Future<int> insertBreak(BreakEntriesCompanion entry) =>
      into(breakEntries).insert(entry);

  Future<bool> updateBreak(BreakEntriesCompanion entry) =>
      update(breakEntries).replace(entry);

  Future<int> deleteBreak(String id) =>
      (delete(breakEntries)..where((t) => t.id.equals(id))).go();
}
