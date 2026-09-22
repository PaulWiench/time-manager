import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/features/settings/export_service.dart';

void main() {
  late AppDatabase db;
  late Directory dir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('tm-export-test');
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('exports a readable database copy and a JSON dump of every table', () async {
    const id = 'session-1';
    final date = DateTime(2026, 9, 22);
    await db.into(db.dayEntries).insert(DayEntriesCompanion.insert(date: date));
    await db.into(db.workSessions).insert(
          WorkSessionsCompanion.insert(
            id: const Value(id),
            date: date,
            startTime: DateTime(2026, 9, 22, 8, 42),
            endTime: Value(DateTime(2026, 9, 22, 12, 37)),
            status: SessionStatus.completed,
          ),
        );

    final result = await ExportService(db).exportAll(into: dir);

    expect(await result.database.exists(), isTrue);
    expect(await result.json.exists(), isTrue);

    // The copy has to be a real database, not just bytes on disk: open it and
    // read the row back out.
    final copy = AppDatabase(NativeDatabase(result.database));
    addTearDown(copy.close);
    final sessions = await copy.select(copy.workSessions).get();
    expect(sessions.single.id, id);

    final dump = jsonDecode(await result.json.readAsString()) as Map<String, Object?>;
    final tables = dump['tables'] as Map<String, Object?>;
    expect(tables.keys, containsAll(<String>['work_sessions', 'day_entries', 'audit_log_entries']));
    expect(tables['work_sessions'], hasLength(1));
    expect(dump['schemaVersion'], db.schemaVersion);
  });

  test('a second export in the same second overwrites rather than failing', () async {
    final at = DateTime(2026, 9, 22, 21, 30, 5);
    await ExportService(db).exportAll(into: dir, now: at);
    final second = await ExportService(db).exportAll(into: dir, now: at);

    expect(await second.database.exists(), isTrue);
    expect(dir.listSync().whereType<File>().length, 2);
  });
}
