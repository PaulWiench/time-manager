/// Home in every state the design drew it in, both themes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/features/home/home_body.dart';
import 'package:time_manager/features/home/home_view.dart';

import 'fixtures/home_fixtures.dart' as fixtures;
import 'harness.dart';

void main() {
  setUpAll(loadAppFonts);

  final states = <String, HomeView Function()>{
    'home-a-tracking': fixtures.tracking,
    'home-b-break': fixtures.onBreak,
    'home-c-checked-out': fixtures.checkedOut,
    'home-d-empty': fixtures.empty,
    'home-e-overtime': fixtures.overtime,
    'home-f-warning': fixtures.warning,
    'home-g-leave': fixtures.partialLeave,
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final entry in states.entries) {
      testWidgets('${entry.key} (${brightness.name})', (tester) async {
        await renderGolden(
          tester,
          name: entry.key,
          brightness: brightness,
          // Real callbacks, because a null one renders the disabled variant
          // and the design's states are all live.
          child: HomeBody(
            view: entry.value(),
            onOpenSettings: () {},
            onToggleTracking: () {},
          ),
        );
      });
    }
  }
}
