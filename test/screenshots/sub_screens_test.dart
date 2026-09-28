/// The three surfaces the redesign rebuilt and never rendered.
///
/// Public holidays, the audit log and the edit-session sheet all read the
/// database directly, which is why they sat outside `settings_test.dart` and
/// went unverified through Phases 7 to 9. Each now has a presentational half
/// that takes plain rows, so each can be looked at here.
///
/// Every date is fixed, including the `now` each screen compares against —
/// a past holiday is tinted differently from an upcoming one, and the audit
/// log labels one group TODAY, so a render that read the clock would drift.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/features/settings/audit_log_body.dart';
import 'package:time_manager/features/settings/holiday_list_body.dart';
import 'package:time_manager/features/settings/leave_list_body.dart';
import 'package:time_manager/widgets/app_date_picker.dart';
import 'package:time_manager/widgets/edit_session_sheet.dart';
import 'package:time_manager/widgets/leave_sheet.dart';
import 'package:time_manager/widgets/press_scale.dart';

import '../fixtures/rows.dart';
import 'harness.dart';

/// Mirrors what `showAppSheet` does around a sheet body: scrim behind,
/// anchored to the bottom, `surface` ground, top-only corner radius.
Widget _asSheet(Widget child) => Builder(
      builder: (context) => ColoredBox(
        color: context.colors.scrim,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadAppFonts);

  final now = DateTime(2026, 9, 22, 18, 51);

  final holidays = [
    holidayRow(date: DateTime(2026, 1, 1), name: 'Neujahr'),
    holidayRow(date: DateTime(2026, 1, 6), name: 'Heilige Drei Könige'),
    holidayRow(date: DateTime(2026, 4, 3), name: 'Karfreitag'),
    holidayRow(date: DateTime(2026, 4, 6), name: 'Ostermontag'),
    holidayRow(date: DateTime(2026, 5, 1), name: 'Tag der Arbeit'),
    holidayRow(date: DateTime(2026, 5, 14), name: 'Christi Himmelfahrt'),
    // A half day and a hand-added one, so both sub-labels are covered.
    holidayRow(date: DateTime(2026, 12, 24), name: 'Heiligabend', fraction: 0.5),
    holidayRow(
      date: DateTime(2026, 12, 31),
      name: 'Betriebsruhe',
      source: HolidaySource.manual,
    ),
  ];

  final audit = [
    auditRow(
      timestamp: DateTime(2026, 9, 22, 18, 51),
      action: 'checkOut',
      entityType: 'WorkSession',
      entityId: '6f3a91c4-2b17-4d8e-9a05-1c7e4f2b8d63',
    ),
    auditRow(
      timestamp: DateTime(2026, 9, 22, 8, 42),
      action: 'checkIn',
      entityType: 'WorkSession',
      entityId: 'a71e5b92-8c34-4f16-b2d7-93e05a1c6f48',
    ),
    auditRow(
      timestamp: DateTime(2026, 9, 21, 16, 41),
      action: 'editSession',
      entityType: 'WorkSession',
      entityId: 'd94c17a3-5e68-4b2f-8107-2a6b9d3e5c71',
    ),
    auditRow(
      timestamp: DateTime(2026, 9, 21, 12, 30),
      action: 'deleteSyntheticBreak',
      entityType: 'BreakEntry',
      entityId: '3b8f26d1-9a47-4c05-b6e3-7f1d84a2c905',
    ),
    // A settings change has no entity id — the row has to survive that.
    auditRow(
      timestamp: DateTime(2026, 9, 20, 21, 8),
      action: 'updateSettings',
      entityType: 'AppSetting',
    ),
  ];

  final session = sessionRow(
    start: DateTime(2026, 9, 21, 8, 5),
    end: DateTime(2026, 9, 21, 16, 41),
  );

  // Paul's own shape: a solid block already taken, and three days still ahead
  // that he is not actually taking — the entries this screen exists to remove.
  // The August-into-September block is one run across a weekend, which is the
  // case the collapsing exists for.
  final leave = [
    LeaveListItem(
      dates: [
        DateTime(2026, 8, 31),
        for (var day = 1; day <= 4; day++) DateTime(2026, 9, day),
      ],
      type: LeaveType.vacation,
      amountLabel: 'full day',
      planned: false,
    ),
    LeaveListItem(
      dates: [DateTime(2026, 9, 15)],
      type: LeaveType.sick,
      amountLabel: 'full day',
      planned: false,
    ),
    LeaveListItem(
      dates: [DateTime(2026, 9, 24)],
      type: LeaveType.flexDay,
      amountLabel: '½ day',
      planned: false,
    ),
    LeaveListItem(
      dates: [for (var day = 28; day <= 30; day++) DateTime(2026, 9, day)],
      type: LeaveType.vacation,
      amountLabel: 'full day',
      planned: true,
    ),
  ];

  final screens = <String, Widget>{
    'settings-leave-list': LeaveListBody(
      year: 2026,
      items: leave,
      usedDays: 5,
      plannedDays: 3,
      quotaDays: 30,
      onAdd: () {},
      onEdit: (_) {},
      onRemove: (_) {},
      onStepYear: (_) {},
    ),
    'settings-leave-sheet': _asSheet(LeaveSheetView(
      subtitle: 'Mon 28 Sep',
      targetHours: 7.9,
      type: LeaveType.vacation,
      fraction: LeaveFraction.full,
      hasExisting: true,
      onType: (_) {},
      onFraction: (_) {},
      onClear: () {},
      onSave: () {},
    )),
    // The same sheet booking a span — a longer subtitle, no Remove, and the
    // notice that fires when the days do not all carry the same target.
    'settings-leave-sheet-range': _asSheet(LeaveSheetView(
      subtitle: 'Mon 12 Oct – Fri 23 Oct · 9 days',
      targetHours: 7.9,
      mixedTargets: true,
      type: LeaveType.vacation,
      fraction: LeaveFraction.full,
      hasExisting: false,
      onType: (_) {},
      onFraction: (_) {},
      onSave: () {},
    )),
    'settings-holidays': HolidayListBody(
      year: 2026,
      holidays: holidays,
      now: now,
      onAdd: () {},
      onEdit: (_) {},
      onRemove: (_) {},
    ),
    'settings-audit-log': AuditLogBody(entries: audit, now: now),
    // Staged the way `showAppSheet` presents it — scrim, bottom-anchored, top
    // corners rounded — rather than as a bare widget filling the screen, so
    // the render shows the thing the user actually meets.
    'history-edit-sheet': _asSheet(EditSessionSheetView(
      date: session.date,
      netHours: 8.1,
      start: session.startTime,
      end: session.endTime!,
      notes: TextEditingController(text: 'Release prep for v1.2, left at 16:41 for the train.'),
      manualBreaks: [
        breakRow(
          start: DateTime(2026, 9, 21, 12, 0),
          end: DateTime(2026, 9, 21, 12, 30),
          type: BreakType.manual,
        ),
      ],
      onPickStart: () {},
      onPickEnd: () {},
      onAddBreak: () {},
      onRemoveBreak: (_) {},
      onSave: () {},
      onDelete: () {},
    )),
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

    // Rendered mid-selection, because the initial state of a range picker is
    // an ordinary empty calendar and says nothing about the feature. `now` is
    // pinned so the "today" outline cannot drift the render by a cell each
    // morning.
    testWidgets('settings-date-range-picker (${brightness.name})', (tester) async {
      await renderGolden(
        tester,
        name: 'settings-date-range-picker',
        brightness: brightness,
        child: AppDateRangePicker(
          initialMonth: DateTime(2026, 10),
          // Weekdays only, so every weekend in the span draws as skipped.
          bookable: (date) => date.weekday <= 5,
          now: DateTime(2026, 9, 28),
        ),
        interact: (tester) async {
          // Mon 12 to Fri 23 October, then the 21st tapped back off.
          for (final day in ['12', '23', '21']) {
            await tester.tap(find.widgetWithText(PressScale, day));
            await tester.pump();
          }
        },
      );
    });
  }
}
