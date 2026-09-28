/// Settings and its editors.
///
/// The two sub-screens read the database directly, so they are not here; what
/// is here is the screen the design drew, and the dialogs behind its rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/features/settings/settings_body.dart';
import 'package:time_manager/features/settings/settings_view.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/core/theme/app_text_styles.dart';
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
  workHours: '08:00 – 18:00',
  restrictCheckin: false,
  balanceBounds: '−20:00 / +40:00',
  annualResetLabel: 'Annual reset off',
  leaveCount: '16 in 2026',
  vacationQuota: '30 days/yr',
  rolloverPolicy: 'Not configured',
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
  workHours: '07:30 – 17:00',
  restrictCheckin: true,
  balanceBounds: 'Not set',
  annualResetLabel: 'Annual reset off',
  leaveCount: 'None yet',
  vacationQuota: '30 days/yr',
  rolloverPolicy: 'Not configured',
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
    // Two steppers stacked under their own kickers — the layout most likely to
    // overflow the dialog, so it is worth a reference image of its own.
    'settings-work-hours-dialog': AppDialog(
      title: 'Work hours',
      subtitle: 'Outside these, an idle hour means the day is done.',
      actions: [
        AppTextButton(label: 'Cancel', onPressed: () {}),
        const PrimaryPill(label: 'Save', expand: false, height: 44),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FROM', style: AppTextStyles.kicker),
          const SizedBox(height: AppSpace.s2),
          StepperField(label: '08:00', onDecrease: () {}, onIncrease: () {}),
          const SizedBox(height: AppSpace.s5),
          Text('UNTIL', style: AppTextStyles.kicker),
          const SizedBox(height: AppSpace.s2),
          StepperField(label: '18:00', onDecrease: () {}, onIncrease: () {}),
        ],
      ),
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
