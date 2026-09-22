import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/database.dart';

/// Where an export landed, so the caller can show the path and offer to share it.
class ExportResult {
  final File database;
  final File json;

  const ExportResult({required this.database, required this.json});

  /// The directory both files share — what gets shown to the user, since the
  /// full paths are far too long to read on a phone.
  String get directory => p.dirname(database.path);
}

/// Writes a self-contained copy of the whole database somewhere the user (and
/// `adb pull`) can actually reach.
///
/// This exists because the release build is not debuggable, so `adb run-as`
/// cannot read the app-private database file — without an in-app export there
/// is no way to back up a running install short of rooting the phone.
class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  /// Every table, dumped generically rather than through the typed DAOs: a
  /// backup should keep working even when the schema gains columns, and should
  /// never be silently filtered by application-level query logic.
  static const _tables = [
    'work_sessions',
    'break_entries',
    'leave_entries',
    'public_holidays',
    'day_entries',
    'balance_snapshots',
    'vacation_quotas',
    'app_settings',
    'audit_log_entries',
  ];

  /// [into] exists so tests can export somewhere other than the device's
  /// external storage, which no plugin serves under `flutter test`.
  Future<ExportResult> exportAll({DateTime? now, Directory? into}) async {
    final stamp = _stamp(now ?? DateTime.now());
    final dir = into ?? await _backupDirectory();
    await dir.create(recursive: true);

    final dbFile = File(p.join(dir.path, 'timemanager-$stamp.sqlite'));
    final jsonFile = File(p.join(dir.path, 'timemanager-$stamp.json'));

    // VACUUM INTO takes a consistent snapshot of a live database, WAL included.
    // Copying the file by hand would risk catching it mid-write.
    if (await dbFile.exists()) await dbFile.delete();
    await _db.customStatement("VACUUM INTO '${_escape(dbFile.path)}'");

    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(await _dump(now ?? DateTime.now())),
    );

    return ExportResult(database: dbFile, json: jsonFile);
  }

  Future<Map<String, Object?>> _dump(DateTime now) async {
    final tables = <String, Object?>{};
    for (final table in _tables) {
      final rows = await _db.customSelect('SELECT * FROM "$table"').get();
      tables[table] = rows.map((r) => r.data.map(_jsonSafe)).toList();
    }
    return {
      'app': 'TimeManager',
      'schemaVersion': _db.schemaVersion,
      'exportedAt': now.toIso8601String(),
      'tables': tables,
    };
  }

  /// Drift hands back whatever SQLite stored; only blobs aren't JSON-encodable.
  MapEntry<String, Object?> _jsonSafe(String key, Object? value) =>
      MapEntry(key, value is List<int> ? base64Encode(value) : value);

  /// The app-specific external directory is the only place reachable by both
  /// `adb pull` and a file manager without asking for a storage permission.
  Future<Directory> _backupDirectory() async {
    final base = Platform.isAndroid
        ? await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory()
        : await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'backups'));
  }

  static String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  /// Single quotes are the only character SQLite string literals escape.
  static String _escape(String path) => path.replaceAll("'", "''");
}
