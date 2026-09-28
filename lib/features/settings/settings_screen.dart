/// Settings' data half.
///
/// Every write goes through [_patch], because `app_settings` rows are
/// versioned: a save writes a whole new row, so any field not carried forward
/// silently resets. That trap is the reason this file has one write path and
/// not eight.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../domain/date_only.dart';
import '../../providers/database_providers.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/vacation_quota_providers.dart';
import 'audit_log_screen.dart';
import 'export_service.dart';
import 'holiday_list_screen.dart';
import 'leave_list_screen.dart';
import 'settings_body.dart';
import 'settings_editors.dart';
import 'settings_view.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(latestSettingsProvider).valueOrNull;
    if (settings == null) return const Center(child: CircularProgressIndicator());

    final year = DateTime.now().year;
    final quota = ref.watch(vacationQuotaForYearProvider(year)).valueOrNull;
    final holidays = ref.watch(publicHolidaysForYearProvider(year)).valueOrNull;
    final leave = ref.watch(leaveForYearProvider(year)).valueOrNull;

    final view = SettingsView(
      weeklyHours: AppFormat.hoursLabel(settings.weeklyHours),
      workDays: workDaysLabel(settings.workDays),
      startingBalance: '0:00',
      autoBreakEnabled: settings.autoBreakEnabled,
      minSessionLength: '${settings.minSessionMinutes} min',
      restrictCheckin: settings.restrictCheckin,
      balanceBounds:
          balanceBoundsLabel(settings.balanceFloorHours, settings.balanceCapHours),
      annualResetLabel: 'Annual reset ${settings.balanceAnnualReset ? 'on' : 'off'}',
      leaveCount: switch (leave?.length ?? 0) {
        0 => 'None yet',
        final n => '$n in $year',
      },
      vacationQuota: '${(quota?.totalDays ?? 30).round()} days/yr',
      // Was hardcoded to 'Indefinite' over a stub editor. `VacationQuotas` has
      // no column saying which policy applies, so the app does not know one —
      // and claiming otherwise on a settings screen is worse than admitting it.
      rolloverPolicy: 'Not configured',
      holidayRegion: 'Baden-Württemberg',
      holidayCount: 'DE · ${holidays?.length ?? 0}',
      notifications: 'All off',
    );

    Future<void> patch({
      double? weeklyHours,
      List<int>? workDays,
      int? minSessionMinutes,
      bool? autoBreakEnabled,
      bool? restrictCheckin,
      BalanceBounds? bounds,
    }) {
      return ref.read(settingsRepositoryProvider).save(
            effectiveFrom: dateOnly(DateTime.now()),
            weeklyHours: weeklyHours ?? settings.weeklyHours,
            workDays: workDays ?? settings.workDays,
            minSessionMinutes: minSessionMinutes ?? settings.minSessionMinutes,
            autoBreakEnabled: autoBreakEnabled ?? settings.autoBreakEnabled,
            restrictCheckin: restrictCheckin ?? settings.restrictCheckin,
            // The bounds are nullable on purpose, so "clear the floor" has to
            // travel as a whole BalanceBounds rather than as a null argument
            // that would be indistinguishable from "leave it alone".
            balanceFloorHours:
                bounds != null ? bounds.floorHours : settings.balanceFloorHours,
            balanceCapHours: bounds != null ? bounds.capHours : settings.balanceCapHours,
            balanceAnnualReset:
                bounds != null ? bounds.annualReset : settings.balanceAnnualReset,
          );
    }

    return SettingsBody(
      view: view,
      onEditWeeklyHours: () async {
        final value = await editNumber(
          context,
          title: 'Weekly hours',
          initial: settings.weeklyHours,
          min: 0,
          max: 80,
          step: 0.5,
          format: (v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1),
          unit: 'h',
        );
        if (value != null) await patch(weeklyHours: value);
      },
      onEditWorkDays: () async {
        final value = await editWorkDays(context, settings.workDays);
        if (value != null) await patch(workDays: value);
      },
      onToggleAutoBreak: (on) => patch(autoBreakEnabled: on),
      onEditMinSession: () async {
        final value = await editNumber(
          context,
          title: 'Minimum session length',
          initial: settings.minSessionMinutes.toDouble(),
          min: 0,
          max: 60,
          step: 1,
          format: (v) => '${v.round()}',
          unit: 'min',
        );
        if (value != null) await patch(minSessionMinutes: value.round());
      },
      onToggleRestrictCheckin: (on) => patch(restrictCheckin: on),
      onEditBalanceBounds: () async {
        final bounds = await editBalanceBounds(
          context,
          floorHours: settings.balanceFloorHours,
          capHours: settings.balanceCapHours,
          annualReset: settings.balanceAnnualReset,
        );
        if (bounds != null) await patch(bounds: bounds);
      },
      onEditVacationQuota: () async {
        final value = await editNumber(
          context,
          title: 'Vacation quota',
          initial: quota?.totalDays ?? 30,
          min: 0,
          max: 60,
          step: 1,
          format: (v) => '${v.round()}',
          unit: 'days',
        );
        if (value != null) {
          await ref
              .read(vacationQuotaRepositoryProvider)
              .setQuota(year: year, totalDays: value);
        }
      },
      onOpenLeave: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LeaveListScreen())),
      onEditRollover: () => _notYet(context),
      onOpenHolidays: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const HolidayListScreen())),
      onEditNotifications: () => _notYet(context),
      onExportBackup: () => _exportBackup(context, ref),
      onOpenAuditLog: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
    );
  }

  void _notYet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editable in a later milestone.')),
    );
  }

  /// The release build is not debuggable, so `adb run-as` cannot read the
  /// database — this is the only way to get a backup off a running install.
  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ExportService(ref.read(appDatabaseProvider)).exportAll();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup written to ${result.directory}'),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
