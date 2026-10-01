/// Jobs (additions handoff §3), with the design's three example jobs.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/data/database/database.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/features/home/home_body.dart';
import 'package:time_manager/features/jobs/edit_job_screen.dart';
import 'package:time_manager/features/jobs/job_pill.dart';
import 'package:time_manager/features/jobs/jobs_screen.dart';
import 'package:time_manager/providers/database_providers.dart';
import 'package:time_manager/providers/job_providers.dart';

import 'fixtures/home_fixtures.dart' as home;
import '../fixtures/rows.dart';
import 'harness.dart';

Job _job(int id, String name, DateTime start, {DateTime? end}) => Job(
      id: id,
      name: name,
      startDate: start,
      endDate: end,
      startingBalanceHours: 0,
      createdAt: start,
      updatedAt: start,
    );

final _research = JobSummary(
  job: _job(1, 'Research assistant', DateTime(2024, 3, 1)),
  settings: settingsRow(),
  active: sessionRow(start: DateTime(2026, 9, 22, 8, 12), status: SessionStatus.active),
  balance: -15.97,
);
final _lecturing = JobSummary(
  job: _job(2, 'Lecturing', DateTime(2026, 3, 15)),
  settings: settingsRow(weeklyHours: 6, workDays: const [2, 4]),
  active: null,
  balance: 1.0833,
);
final _student = JobSummary(
  job: _job(3, 'Working student', DateTime(2023, 10, 1), end: DateTime(2025, 12, 31)),
  settings: settingsRow(),
  active: null,
  balance: 3.333,
);

Widget _asSheet(Widget child) => Builder(
      builder: (context) => ColoredBox(
        color: context.colors.scrim,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: child,
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  final screens = <String, Widget Function()>{
    'jobs-home': () => HomeBody(
          view: home.tracking(),
          jobPill: const JobPillView(name: 'Research assistant', ended: false),
          onToggleTracking: () {},
        ),
    'jobs-home-ended': () => HomeBody(
          view: home.checkedOut(),
          jobPill: const JobPillView(name: 'Working student', ended: true),
          endedJob: const EndedJob(
            finalBalance: 3.333,
            endLabel: '31 Dec 2025',
            spanLabel: 'Oct 2023 – Dec 2025',
          ),
          onSwitchJob: () {},
        ),
    'jobs-switcher': () => _asSheet(JobSwitcherView(
          summaries: [_research, _lecturing, _student],
          selectedId: 1,
          onSelect: (_) {},
          onManage: () {},
        )),
    'jobs-list': () => JobsBody(summaries: [_research, _lecturing, _student]),
    'jobs-end-sheet': () => _asSheet(EndJobSheet(
          job: _lecturing.job,
          finalBalance: 1.0833,
          yearlyQuota: 30,
          earliest: DateTime(2026, 7, 1),
          initial: DateTime(2026, 7, 31),
        )),
    'jobs-new': () => ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
          ],
          child: const EditJobScreen(),
        ),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} (${brightness.name})', (tester) async {
        await renderGolden(
          tester,
          name: entry.key,
          brightness: brightness,
          child: entry.value(),
        );
        // The database's watch streams leave a zero-delay timer behind when
        // the tree goes away; let it fire before the test ends.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
