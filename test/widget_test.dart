import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_manager/app.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/providers/database_providers.dart';

void main() {
  testWidgets('a fresh install boots straight into onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The real provider opens a file-backed DB via path_provider,
          // which needs platform channels unavailable under `flutter
          // test` -- swap in an in-memory DB, same as the repository
          // integration tests. `closeStreamsSynchronously` avoids a
          // zero-duration Timer drift otherwise schedules on stream
          // teardown, which flutter_test's end-of-test "no pending
          // timers" invariant check would fail on.
          appDatabaseProvider.overrideWith((ref) => AppDatabase(
                DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
              )),
        ],
        child: const TimeManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    // No Settings row exists yet, so `_RootGate` should route to
    // onboarding's first step rather than the bottom-nav shell.
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
