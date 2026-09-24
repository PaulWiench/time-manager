/// Settings and its editors.
///
/// The two sub-screens read the database directly, so they are not here; what
/// is here is the screen the design drew, and the dialogs behind its rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/features/settings/settings_body.dart';
import 'package:time_manager/features/settings/settings_view.dart';
import 'package:time_manager/widgets/app_dialog.dart';
import 'package:time_manager/widgets/buttons.dart';
import 'package:time_manager/widgets/stepper_field.dart';

import 'harness.dart';

const _configured = SettingsView(
  weeklyHours: '39.5 h',
  workDays: 'Mon–Fri',
  startingBalance: '0:00',
  autoBreakEnabled: true,
  minSessionLength: '5 min',
  restrictCheckin: false,
  balanceBounds: '−20:00 / +40:00',
  annualResetLabel: 'Annual reset off',
  vacationQuota: '30 days/yr',
  rolloverPolicy: 'Indefinite',
  holidayRegion: 'Baden-Württemberg',
  holidayCount: 'DE · 13',
  notifications: 'All off',
);

const _unset = SettingsView(
  weeklyHours: '40 h',
  workDays: 'Mon–Fri',
  startingBalance: '0:00',
  autoBreakEnabled: true,
  minSessionLength: '5 min',
  restrictCheckin: true,
  balanceBounds: 'Not set',
  annualResetLabel: 'Annual reset off',
  vacationQuota: '30 days/yr',
  rolloverPolicy: 'Indefinite',
  holidayRegion: 'Baden-Württemberg',
  holidayCount: 'DE · 13',
  notifications: 'All off',
);

void main() {
  setUpAll(loadAppFonts);

  final screens = <String, Widget>{
    'settings': SettingsBody(
      view: _configured,
      onEditWeeklyHours: () {},
      onEditWorkDays: () {},
      onToggleAutoBreak: (_) {},
      onEditMinSession: () {},
      onToggleRestrictCheckin: (_) {},
      onEditBalanceBounds: () {},
      onEditVacationQuota: () {},
      onEditRollover: () {},
      onOpenHolidays: () {},
      onEditNotifications: () {},
      onExportBackup: () {},
      onOpenAuditLog: () {},
    ),
    'settings-bounds-unset': SettingsBody(view: _unset),
    'settings-stepper-dialog': AppDialog(
      title: 'Weekly hours',
      actions: [
        AppTextButton(label: 'Cancel', onPressed: () {}),
        const PrimaryPill(label: 'Save', expand: false, height: 44),
      ],
      child: StepperField(
        label: '39.5',
        unit: 'h',
        onDecrease: () {},
        onIncrease: () {},
      ),
    ),
    'settings-workdays-dialog': AppDialog(
      title: 'Work days',
      actions: [
        AppTextButton(label: 'Cancel', onPressed: () {}),
        const PrimaryPill(label: 'Save', expand: false, height: 44),
      ],
      child: WeekdayToggles(selected: const {1, 2, 3, 4, 5}, onToggle: (_) {}),
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
