/// Settings, drawn from a [SettingsView] and nothing else.
library;

import 'package:flutter/widgets.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/settings_row.dart';
import 'settings_view.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({
    super.key,
    required this.view,
    this.onEditWeeklyHours,
    this.onEditWorkDays,
    this.onEditWorkHours,
    this.onToggleAutoBreak,
    this.onEditMinSession,
    this.onToggleRestrictCheckin,
    this.onEditBalanceBounds,
    this.onOpenLeave,
    this.onEditVacationQuota,
    this.onEditRollover,
    this.onOpenHolidays,
    this.onEditNotifications,
    this.onExportBackup,
    this.onOpenAuditLog,
    this.onInfo,
  });

  final SettingsView view;

  final VoidCallback? onEditWeeklyHours;
  final VoidCallback? onEditWorkDays;
  final VoidCallback? onEditWorkHours;
  final ValueChanged<bool>? onToggleAutoBreak;
  final VoidCallback? onEditMinSession;
  final ValueChanged<bool>? onToggleRestrictCheckin;
  final VoidCallback? onEditBalanceBounds;
  final VoidCallback? onOpenLeave;
  final VoidCallback? onEditVacationQuota;
  final VoidCallback? onEditRollover;
  final VoidCallback? onOpenHolidays;
  final VoidCallback? onEditNotifications;
  final VoidCallback? onExportBackup;
  final VoidCallback? onOpenAuditLog;

  /// A row's icon was tapped: open that setting's "about" sheet.
  final ValueChanged<SettingKey>? onInfo;

  VoidCallback? _info(SettingKey key) => onInfo == null ? null : () => onInfo!(key);

  @override
  Widget build(BuildContext context) {
    return TabScreen(
      title: 'Settings',
      gutter: AppSpace.gutterDense,
      children: [
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'SCHEDULE',
          rows: [
            SettingsRow.navigate(
              icon: AppIcons.hourglassMedium,
              label: 'Weekly hours',
              onInfo: _info(SettingKey.weeklyHours),
              value: view.weeklyHours,
              onTap: onEditWeeklyHours,
            ),
            SettingsRow.navigate(
              icon: AppIcons.calendarDots,
              label: 'Work days',
              onInfo: _info(SettingKey.workDays),
              value: view.workDays,
              onTap: onEditWorkDays,
            ),
            SettingsRow.navigate(
              icon: AppIcons.clock,
              label: 'Work hours',
              onInfo: _info(SettingKey.workHours),
              sub: 'When the day is over',
              value: view.workHours,
              onTap: onEditWorkHours,
            ),
            SettingsRow.static(
              icon: AppIcons.plusMinus,
              label: 'Starting balance',
              onInfo: _info(SettingKey.startingBalance),
              sub: 'Set during onboarding',
              value: view.startingBalance,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'BREAKS',
          rows: [
            SettingsRow.toggle(
              icon: AppIcons.coffee,
              label: 'Auto-break',
              onInfo: _info(SettingKey.autoBreak),
              sub: '30 min after 6 h, 45 min after 9 h',
              value: view.autoBreakEnabled,
              onChanged: onToggleAutoBreak ?? (_) {},
            ),
            SettingsRow.navigate(
              icon: AppIcons.timer,
              label: 'Minimum session length',
              onInfo: _info(SettingKey.minSession),
              value: view.minSessionLength,
              onTap: onEditMinSession,
            ),
            SettingsRow.toggle(
              icon: AppIcons.clockUser,
              label: 'Restrict check-in',
              onInfo: _info(SettingKey.restrictCheckin),
              // Honest rather than aspirational: the switch stores a value and
              // nothing reads it. A setting that can refuse a check-in can
              // cost a day's tracking, so it stays unarmed until it is asked
              // for deliberately.
              sub: "Check-in isn't refused yet",
              value: view.restrictCheckin,
              onChanged: onToggleRestrictCheckin ?? (_) {},
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'BALANCE',
          rows: [
            SettingsRow.navigate(
              icon: AppIcons.scales,
              label: 'Floor / cap',
              onInfo: _info(SettingKey.balanceBounds),
              sub: view.annualResetLabel,
              value: view.balanceBounds,
              onTap: onEditBalanceBounds,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'LEAVE',
          rows: [
            SettingsRow.navigate(
              icon: AppIcons.calendarCheck,
              label: 'Vacation & sick days',
              onInfo: _info(SettingKey.leave),
              sub: 'Book, edit or remove a day',
              value: view.leaveCount,
              onTap: onOpenLeave,
            ),
            SettingsRow.navigate(
              icon: AppIcons.airplaneTilt,
              label: 'Vacation quota',
              onInfo: _info(SettingKey.vacationQuota),
              sub: view.vacationQuotaSub,
              value: view.vacationQuota,
              onTap: onEditVacationQuota,
            ),
            SettingsRow.navigate(
              icon: AppIcons.umbrellaSimple,
              label: 'Rollover policy',
              onInfo: _info(SettingKey.rollover),
              value: view.rolloverPolicy,
              onTap: onEditRollover,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'HOLIDAYS',
          rows: [
            SettingsRow.navigate(
              icon: AppIcons.confetti,
              label: 'Public holidays',
              onInfo: _info(SettingKey.holidays),
              sub: view.holidayRegion,
              value: view.holidayCount,
              onTap: onOpenHolidays,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'NOTIFICATIONS',
          rows: [
            SettingsRow.navigate(
              icon: AppIcons.bellSimple,
              label: 'Notifications',
              onInfo: _info(SettingKey.notifications),
              value: view.notifications,
              onTap: onEditNotifications,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        SettingsGroup(
          title: 'DATA',
          rows: [
            SettingsRow.navigate(
              icon: AppIcons.floppyDisk,
              label: 'Export backup',
              onInfo: _info(SettingKey.exportBackup),
              sub: 'Database and JSON, to this phone',
              onTap: onExportBackup,
            ),
          ],
        ),
        // Outside every group and dashed: the raw log is rarely needed, and
        // dashed is this design's word for "not a normal thing".
        const SizedBox(height: AppSpace.s8),
        AdvancedRow(
          icon: AppIcons.code,
          label: 'Audit log',
          sub: 'Every change, as stored',
          onTap: onOpenAuditLog,
        ),
      ],
    );
  }
}
