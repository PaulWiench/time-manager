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
import '../../core/icons/app_icons.dart';
import '../../domain/leave_days.dart';
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
import 'setting_info_sheet.dart';
import 'settings_view.dart';
import '../../providers/job_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(latestSettingsProvider).valueOrNull;
    final jobId = ref.watch(selectedJobIdProvider);
    if (settings == null || jobId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final year = DateTime.now().year;
    final quota = ref.watch(vacationQuotaForYearProvider(year)).valueOrNull;
    final holidays = ref.watch(publicHolidaysForYearProvider(year)).valueOrNull;
    final leave = ref.watch(leaveForYearProvider(year)).valueOrNull;

    final view = SettingsView(
      weeklyHours: AppFormat.hoursLabel(settings.weeklyHours),
      workDays: workDaysLabel(settings.workDays),
      startingBalance: AppFormat.hm(
        ref.watch(selectedJobProvider)?.startingBalanceHours ?? 0,
        signed: true,
      ),
      autoBreakEnabled: settings.autoBreakEnabled,
      minSessionLength: '${settings.minSessionMinutes} min',
      workHours: workHoursLabel(
        settings.workWindowStartMinutes,
        settings.workWindowEndMinutes,
      ),
      restrictCheckin: settings.restrictCheckin,
      balanceBounds: balanceBoundsLabel(
        settings.balanceFloorHours,
        settings.balanceCapHours,
      ),
      annualResetLabel:
          'Annual reset ${settings.balanceAnnualReset ? 'on' : 'off'}',
      leaveCount: switch (leave?.length ?? 0) {
        0 => 'None yet',
        final n => '$n in $year',
      },
      vacationQuota: '${(quota?.totalDays ?? 30).round()} days/yr',
      vacationQuotaSub: () {
        final e = ref.watch(vacationEntitlementProvider(year));
        if (e == null || !e.prorated.isProrated) return null;
        return '${formatLeaveDays(e.prorated.days)} in $year, pro-rated';
      }(),
      // Was hardcoded to 'Indefinite' over a stub editor. `VacationQuotas` has
      // no column saying which policy applies, so the app does not know one —
      // and claiming otherwise on a settings screen is worse than admitting it.
      rolloverPolicy: 'Not configured',
      holidayRegion: 'Baden-Württemberg',
      holidayCount: 'DE · ${holidays?.length ?? 0}',
      notifications: 'All off',
    );

    // The schedule, window and balance bounds are the selected job's own.
    Future<void> patch({
      double? weeklyHours,
      List<int>? workDays,
      WorkWindow? workWindow,
      BalanceBounds? bounds,
    }) {
      return ref
          .read(settingsRepositoryProvider)
          .save(
            jobId: jobId,
            effectiveFrom: dateOnly(DateTime.now()),
            weeklyHours: weeklyHours ?? settings.weeklyHours,
            workDays: workDays ?? settings.workDays,
            minSessionMinutes: settings.minSessionMinutes,
            autoBreakEnabled: settings.autoBreakEnabled,
            restrictCheckin: settings.restrictCheckin,
            workWindowStartMinutes:
                workWindow?.startMinutes ?? settings.workWindowStartMinutes,
            workWindowEndMinutes:
                workWindow?.endMinutes ?? settings.workWindowEndMinutes,
            // The bounds are nullable on purpose, so "clear the floor" has to
            // travel as a whole BalanceBounds rather than as a null argument
            // that would be indistinguishable from "leave it alone".
            balanceFloorHours: bounds != null
                ? bounds.floorHours
                : settings.balanceFloorHours,
            balanceCapHours: bounds != null
                ? bounds.capHours
                : settings.balanceCapHours,
            balanceAnnualReset: bounds != null
                ? bounds.annualReset
                : settings.balanceAnnualReset,
          );
    }

    // Breaks apply to every job, so a change writes every job's next row.
    Future<void> patchAllJobs({
      int? minSessionMinutes,
      bool? autoBreakEnabled,
      bool? restrictCheckin,
    }) {
      return ref
          .read(settingsRepositoryProvider)
          .saveForAllJobs(
            effectiveFrom: dateOnly(DateTime.now()),
            minSessionMinutes: minSessionMinutes,
            autoBreakEnabled: autoBreakEnabled,
            restrictCheckin: restrictCheckin,
          );
    }

    Future<void> onEditBounds() async {
      final bounds = await editBalanceBounds(
        context,
        floorHours: settings.balanceFloorHours,
        capHours: settings.balanceCapHours,
        annualReset: settings.balanceAnnualReset,
      );
      if (bounds != null) await patch(bounds: bounds);
    }

    final entitlement = ref.watch(vacationEntitlementProvider(year));

    SettingInfo infoFor(SettingKey key) => switch (key) {
      SettingKey.weeklyHours => SettingInfo(
        name: 'Weekly hours',
        group: 'Schedule',
        value: view.weeklyHours,
        icon: AppIcons.hourglassMedium,
        body:
            'Your contracted hours per week, split evenly across your work days '
            'to set each day\'s target.',
        footnote:
            'A change applies from today. Days already past keep the target '
            'they had.',
        control: NumberControl(
          value: settings.weeklyHours,
          min: 0,
          max: 80,
          step: 0.5,
          unit: 'h',
          format: (v) =>
              v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1),
          onSave: (v) => patch(weeklyHours: v),
        ),
      ),
      SettingKey.workDays => SettingInfo(
        name: 'Work days',
        group: 'Schedule',
        value: view.workDays,
        icon: AppIcons.calendarDots,
        body:
            'Days with a target. Other days are rest days and never count as missed; '
            'work on them still counts in full.',
        control: WorkDaysControl(
          value: settings.workDays,
          onSave: (v) => patch(workDays: v),
        ),
      ),
      SettingKey.workHours => SettingInfo(
        name: 'Work hours',
        group: 'Schedule',
        value: view.workHours,
        icon: AppIcons.clock,
        body:
            'Your normal working hours. Checked out inside them, the app treats the '
            'gap as a break and holds today\'s shortfall back; after they end, the day '
            'is over and the balance settles.',
        control: WorkWindowControl(
          start: settings.workWindowStartMinutes,
          end: settings.workWindowEndMinutes,
          onSave: (start, end) => patch(
            workWindow: WorkWindow(startMinutes: start, endMinutes: end),
          ),
        ),
      ),
      SettingKey.startingBalance => SettingInfo(
        name: 'Starting balance',
        group: 'Schedule',
        value: view.startingBalance,
        icon: AppIcons.plusMinus,
        body:
            'Hours you were already ahead (+) or behind (−) when you started '
            'tracking. Every balance since builds on it.',
      ),
      SettingKey.autoBreak => SettingInfo(
        name: 'Auto-break',
        group: 'Breaks · all jobs',
        value: view.autoBreakEnabled ? 'on' : 'off',
        icon: AppIcons.coffee,
        tone: SettingTone.breaks,
        body:
            'Deducts the legally required break (30 min after 6 h, 45 min after 9 h) '
            'when you didn\'t check out for one.',
        rules: const [
          ('After 6 h of work', '30 min'),
          ('After 9 h of work', '45 min'),
        ],
        footnote:
            'Time between your sessions counts toward it first; only what is '
            'still missing is deducted.',
        control: ToggleControl(
          label: 'Deduct missing breaks',
          value: settings.autoBreakEnabled,
          onSave: (v) => patchAllJobs(autoBreakEnabled: v),
        ),
      ),
      SettingKey.minSession => SettingInfo(
        name: 'Minimum session length',
        group: 'Breaks · all jobs',
        value: view.minSessionLength,
        icon: AppIcons.timer,
        body:
            'Shorter sessions are discarded, so an accidental double tap doesn\'t '
            'log a 0:01 session.',
        control: NumberControl(
          value: settings.minSessionMinutes.toDouble(),
          min: 0,
          max: 60,
          step: 1,
          unit: 'min',
          format: (v) => '${v.round()}',
          onSave: (v) => patchAllJobs(minSessionMinutes: v.round()),
        ),
      ),
      SettingKey.restrictCheckin => SettingInfo(
        name: 'Restrict check-in',
        group: 'Breaks · all jobs',
        value: view.restrictCheckin ? 'on' : 'off',
        icon: AppIcons.clockUser,
        body:
            'Ties sessions to your work hours. When on, a session left running '
            'overnight is stopped at the end of your work hours, and "Started earlier?" '
            'won\'t move a start before they begin. Check-in itself is not refused yet.',
        control: ToggleControl(
          label: 'Use work hours as the limit',
          value: settings.restrictCheckin,
          onSave: (v) => patchAllJobs(restrictCheckin: v),
        ),
      ),
      SettingKey.balanceBounds => SettingInfo(
        name: 'Floor / cap',
        group: 'Balance',
        value: view.balanceBounds,
        icon: AppIcons.scales,
        body:
            'Limits for your balance. Past either one, the balance turns marigold so '
            'you see it. Nothing is cut off. The annual reset is stored but not applied '
            'yet.',
        openLabel: 'Open setting',
        onOpen: () => onEditBounds(),
      ),
      SettingKey.leave => SettingInfo(
        name: 'Vacation & sick days',
        group: 'Leave',
        value: view.leaveCount,
        icon: AppIcons.calendarCheck,
        tone: SettingTone.vacation,
        body:
            'Book vacation, sick and flex days, or change ones already booked. A '
            'day of leave counts its own target, so the balance stays even.',
        openLabel: 'Open list',
        onOpen: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LeaveListScreen())),
      ),
      SettingKey.vacationQuota => SettingInfo(
        name: 'Vacation quota',
        group: 'Leave',
        value: view.vacationQuota,
        icon: AppIcons.airplaneTilt,
        tone: SettingTone.vacation,
        body: entitlement != null && entitlement.prorated.isProrated
            ? 'Vacation days per full year. This year the job covers '
                  '${entitlement.prorated.fullMonths} full months, so it is pro-rated: '
                  '${formatLeaveDays(entitlement.yearlyQuota)} × '
                  '${entitlement.prorated.fullMonths}/12 = '
                  '${formatLeaveDays(entitlement.prorated.exact)}, which makes '
                  '${formatLeaveDays(entitlement.prorated.days)} days in $year.'
            : 'Vacation days per full year. In a year a job starts or ends, it is '
                  'pro-rated by full months; half a day or more rounds up.',
        control: NumberControl(
          value: quota?.totalDays ?? 30,
          min: 0,
          max: 60,
          step: 1,
          unit: 'days',
          format: (v) => '${v.round()}',
          onSave: (v) => ref
              .read(vacationQuotaRepositoryProvider)
              .setQuota(jobId: jobId, year: year, totalDays: v),
        ),
      ),
      SettingKey.rollover => SettingInfo(
        name: 'Rollover policy',
        group: 'Leave',
        value: view.rolloverPolicy,
        icon: AppIcons.umbrellaSimple,
        body:
            'What happens to unused vacation days at the end of the year: carried '
            'over, forfeited, or carried over until a deadline. Not configurable yet.',
      ),
      SettingKey.holidays => SettingInfo(
        name: 'Public holidays',
        group: 'Holidays · all jobs',
        value: view.holidayCount,
        icon: AppIcons.confetti,
        tone: SettingTone.holiday,
        body:
            'Days off with no target, loaded for Baden-Württemberg. You can add or '
            'remove days, including half days.',
        openLabel: 'Open list',
        onOpen: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HolidayListScreen())),
      ),
      SettingKey.notifications => SettingInfo(
        name: 'Notifications',
        group: 'Notifications',
        value: view.notifications,
        icon: AppIcons.bellSimple,
        body:
            'Optional reminders, such as checking out. Not built yet, so nothing is '
            'sent.',
      ),
      SettingKey.exportBackup => SettingInfo(
        name: 'Export backup',
        group: 'Data',
        value: 'to this phone',
        icon: AppIcons.floppyDisk,
        body:
            'Writes a copy of the whole database and a JSON dump to this phone\'s app '
            'folder. Take one before anything big; it is how a backup gets off the '
            'phone.',
        openLabel: 'Export now',
        onOpen: () => _exportBackup(context, ref),
      ),
    };

    return SettingsBody(
      view: view,
      onInfo: (key) => showSettingInfo(context, infoFor(key)),
      onEditWeeklyHours: () async {
        final value = await editNumber(
          context,
          title: 'Weekly hours',
          initial: settings.weeklyHours,
          min: 0,
          max: 80,
          step: 0.5,
          format: (v) =>
              v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1),
          unit: 'h',
        );
        if (value != null) await patch(weeklyHours: value);
      },
      onEditWorkDays: () async {
        final value = await editWorkDays(context, settings.workDays);
        if (value != null) await patch(workDays: value);
      },
      onEditWorkHours: () async {
        final window = await editWorkWindow(
          context,
          startMinutes: settings.workWindowStartMinutes,
          endMinutes: settings.workWindowEndMinutes,
        );
        if (window != null) await patch(workWindow: window);
      },
      onToggleAutoBreak: (on) => patchAllJobs(autoBreakEnabled: on),
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
        if (value != null) await patchAllJobs(minSessionMinutes: value.round());
      },
      onToggleRestrictCheckin: (on) => patchAllJobs(restrictCheckin: on),
      onEditBalanceBounds: onEditBounds,
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
              .setQuota(jobId: jobId, year: year, totalDays: value);
        }
      },
      onOpenLeave: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LeaveListScreen())),
      onEditRollover: () => _notYet(context),
      onOpenHolidays: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HolidayListScreen())),
      onEditNotifications: () => _notYet(context),
      onExportBackup: () => _exportBackup(context, ref),
      onOpenAuditLog: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
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
      final result = await ExportService(
        ref.read(appDatabaseProvider),
      ).exportAll();
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
