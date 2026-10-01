/// "Started earlier?" and "Check in at…" in every state the additions
/// handoff draws (§5.3, §5.4), at the design's own example times.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/domain/session_fix.dart';
import 'package:time_manager/widgets/session_fix_sheet.dart';

import 'harness.dart';

DateTime _t(int h, int m) => DateTime(2026, 9, 22, h, m);

final _start = SessionFix.startEarlier(currentStart: _t(8, 12), workWindowStartMinutes: 7 * 60);
final _checkIn = SessionFix.checkInAt(lastCheckOut: _t(12, 30), now: _t(13, 5));

void main() {
  setUpAll(loadAppFonts);

  final sheets = <String, (SessionFix, DateTime, double)>{
    'fix-start-valid': (_start, _t(7, 45), 2.47),
    'fix-start-limit': (_start, _t(7, 0), 2.47),
    'fix-start-invalid': (_start, _t(6, 40), 2.47),
    'fix-start-unchanged': (_start, _t(8, 12), 2.47),
    'fix-checkin-valid': (_checkIn, _t(12, 58), 4.3),
    'fix-checkin-note': (_checkIn, _t(12, 38), 4.3),
    'fix-checkin-future': (_checkIn, _t(13, 20), 4.3),
    'fix-checkin-before': (_checkIn, _t(12, 20), 4.3),
  };

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final MapEntry(key: name, value: (fix, value, net)) in sheets.entries) {
      testWidgets('$name (${brightness.name})', (tester) async {
        await renderGolden(
          tester,
          name: name,
          brightness: brightness,
          size: const Size(1080, 1500),
          child: Builder(
            builder: (context) => Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
                child: SessionFixSheet(
                  fix: fix,
                  todayNetHours: net,
                  initialValue: value,
                  onSave: (_) async {},
                ),
              ),
            ),
          ),
        );
      });
    }
  }
}
