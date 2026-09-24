/// A development entrypoint that wipes the database and seeds six months of
/// plausible history.
///
/// It exists because eight of Home's states and every Stats chart need a
/// history that a fresh install does not have and that cannot be produced by
/// hand. It is also the single most dangerous file in the repository, so it is
/// guarded three ways:
///
///   1. It refuses to run outside a debug build.
///   2. It refuses to run without `--dart-define=WIPE=yes-really`.
///   3. It does not live in `lib/` at all, so nothing the app ships can
///      reach it even by accident. `lib/main.dart` is what release APKs
///      build from, and it has never heard of this file.
///
/// Run it, and only ever against the emulator:
///
///     flutter run -d emulator-5554 --target tool/main_dev.dart \
///       --dart-define=WIPE=yes-really
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:time_manager/app.dart';
import 'package:time_manager/providers/database_providers.dart';

import 'seed_scenarios.dart';

const _confirmation = String.fromEnvironment('WIPE');

/// Which day today should look like. Override with
/// `--dart-define=STATE=onBreak`.
const _state = String.fromEnvironment('STATE', defaultValue: 'tracking');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    throw StateError('main_dev is a debug entrypoint and must never ship.');
  }
  if (_confirmation != 'yes-really') {
    throw StateError(
      'Refusing to wipe: pass --dart-define=WIPE=yes-really to confirm.',
    );
  }

  final container = ProviderContainer();
  final db = container.read(appDatabaseProvider);

  debugPrint('main_dev: wiping and seeding…');
  await wipe(db);
  await seed(
    db,
    now: DateTime.now(),
    state: SeedState.values.firstWhere(
      (value) => value.name == _state,
      orElse: () => SeedState.tracking,
    ),
  );
  debugPrint('main_dev: seeded.');

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TimeManagerApp(),
    ),
  );
}
