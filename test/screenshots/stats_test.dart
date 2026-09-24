/// Stats: each tab, the not-enough-data state, and the custom range note.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/features/stats/stats_body.dart';
import 'package:time_manager/features/stats/stats_view.dart';

import 'fixtures/stats_fixtures.dart' as fixtures;
import 'harness.dart';

void main() {
  setUpAll(loadAppFonts);

  final screens = <String, Widget>{
    'stats-overview': StatsBody(
      tab: StatsTab.overview,
      range: StatsRange.sixMonths,
      overview: fixtures.overview(),
    ),
    'stats-patterns': StatsBody(
      tab: StatsTab.patterns,
      range: StatsRange.month,
      patterns: fixtures.patterns(),
    ),
    'stats-leave': StatsBody(
      tab: StatsTab.leave,
      range: StatsRange.year,
      leave: fixtures.leave(),
    ),
    'stats-empty': StatsBody(
      tab: StatsTab.overview,
      range: StatsRange.week,
      overview: fixtures.sparseOverview(),
    ),
    'stats-custom': StatsBody(
      tab: StatsTab.overview,
      range: StatsRange.custom,
      customRangeLabel: '1 Aug – 22 Sep 2026',
      overview: fixtures.overview(days: 53),
    ),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} (${brightness.name})', (tester) async {
        await renderGolden(
          tester,
          name: entry.key,
          brightness: brightness,
          child: entry.value,
        );
      });
    }
  }
}
