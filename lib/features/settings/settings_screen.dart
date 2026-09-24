import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/date_only.dart';
import '../../providers/database_providers.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/vacation_quota_providers.dart';
import 'audit_log_screen.dart';
import 'export_service.dart';
import 'holiday_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(latestSettingsProvider).valueOrNull;

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Settings rows are versioned, so a save writes a whole new row: every
    // field not being edited has to be carried forward explicitly or it
    // silently resets.
    Future<void> patch({
      double? weeklyHours,
      List<int>? workDays,
      int? minSessionMinutes,
      bool? autoBreakEnabled,
      bool? restrictCheckin,
      double? balanceFloorHours,
      double? balanceCapHours,
      bool? balanceAnnualReset,
      bool clearBalanceBounds = false,
    }) {
      return ref.read(settingsRepositoryProvider).save(
            effectiveFrom: dateOnly(DateTime.now()),
            weeklyHours: weeklyHours ?? settings.weeklyHours,
            workDays: workDays ?? settings.workDays,
            minSessionMinutes: minSessionMinutes ?? settings.minSessionMinutes,
            autoBreakEnabled: autoBreakEnabled ?? settings.autoBreakEnabled,
            restrictCheckin: restrictCheckin ?? settings.restrictCheckin,
            balanceFloorHours:
                clearBalanceBounds ? null : balanceFloorHours ?? settings.balanceFloorHours,
            balanceCapHours:
                clearBalanceBounds ? null : balanceCapHours ?? settings.balanceCapHours,
            balanceAnnualReset: balanceAnnualReset ?? settings.balanceAnnualReset,
          );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 14, AppSpace.screenPadding, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Settings', style: AppTextStyles.screenTitle.copyWith(color: colors.text)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenPadding, 4, AppSpace.screenPadding, 20),
                children: [
                  _Kicker('Schedule', colors),
                  _NavRow(
                    label: 'Weekly hours',
                    value: AppFormat.hoursLabel(settings.weeklyHours),
                    colors: colors,
                    onTap: () => _editWeeklyHours(context, settings.weeklyHours, (v) => patch(weeklyHours: v)),
                  ),
                  _NavRow(
                    label: 'Work days',
                    value: _workDaysLabel(settings.workDays),
                    colors: colors,
                    onTap: () => _editWorkDays(context, settings.workDays, (v) => patch(workDays: v)),
                  ),
                  _NavRow(label: 'Starting balance', value: 'Set during onboarding', colors: colors, onTap: null),

                  _Kicker('Breaks', colors),
                  _ToggleRow(
                    label: 'Auto-break enabled',
                    value: settings.autoBreakEnabled,
                    colors: colors,
                    onChanged: (v) => patch(autoBreakEnabled: v),
                  ),
                  _NavRow(
                    label: 'Minimum session length',
                    value: '${settings.minSessionMinutes} min',
                    colors: colors,
                    onTap: () => _editMinSession(context, settings.minSessionMinutes, (v) => patch(minSessionMinutes: v)),
                  ),
                  _ToggleRow(
                    label: 'Restrict check-in',
                    value: settings.restrictCheckin,
                    colors: colors,
                    onChanged: (v) => patch(restrictCheckin: v),
                    isLast: true,
                  ),

                  _Kicker('Balance & leave', colors),
                  _NavRow(
                    label: 'Floor / cap',
                    value: _boundsLabel(settings.balanceFloorHours, settings.balanceCapHours),
                    colors: colors,
                    onTap: () => _comingSoon(context),
                  ),
                  _VacationQuotaRow(colors: colors),
                  _NavRow(label: 'Rollover policy', value: 'Indefinite', colors: colors, onTap: () => _comingSoon(context)),
                  _PublicHolidaysRow(colors: colors),

                  _Kicker('Notifications', colors),
                  _NavRow(label: 'Notifications', value: 'All off', colors: colors, onTap: () => _comingSoon(context), isLast: true),

                  _Kicker('Data', colors),
                  _NavRow(
                    label: 'Export backup',
                    value: 'Database + JSON',
                    colors: colors,
                    onTap: () => _exportBackup(context, ref),
                    isLast: true,
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.divider))),
                    child: Opacity(
                      opacity: 0.6,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Audit log', style: AppTextStyles.meta.copyWith(color: colors.text)),
                              Icon(AppIcons.caretRight, size: 12, color: colors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The release build isn't debuggable, so `adb run-as` can't read the
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

  /// Either bound can stand alone — a floor without a cap is a perfectly
  /// normal configuration, and neither set is the default.
  String _boundsLabel(double? floor, double? cap) {
    if (floor == null && cap == null) return 'Not set';
    final parts = [
      if (floor != null) AppFormat.hm(floor),
      if (cap != null) AppFormat.hm(cap, signed: true),
    ];
    return parts.join(' / ');
  }

  String _workDaysLabel(List<int> days) {
    const names = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final sorted = [...days]..sort();
    if (sorted.isEmpty) return 'None';
    // Common contiguous case (e.g. Mon-Fri) renders as a range.
    final isContiguous = sorted.length > 1 && sorted.last - sorted.first == sorted.length - 1;
    if (isContiguous) return '${names[sorted.first]}–${names[sorted.last]}';
    return sorted.map((d) => names[d]).join(', ');
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editable in a later milestone.')),
    );
  }

  Future<void> _editWeeklyHours(BuildContext context, double current, ValueChanged<double> onSave) async {
    var value = current;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Weekly hours'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () => setState(() => value = (value - 0.5).clamp(0, 80)), icon: const Icon(Icons.remove)),
              SizedBox(width: 60, child: Text(AppFormat.hoursLabel(value), textAlign: TextAlign.center)),
              IconButton(onPressed: () => setState(() => value = (value + 0.5).clamp(0, 80)), icon: const Icon(Icons.add)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () { onSave(value); Navigator.pop(context); }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Future<void> _editMinSession(BuildContext context, int current, ValueChanged<int> onSave) async {
    var value = current;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Minimum session length'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () => setState(() => value = (value - 1).clamp(0, 60)), icon: const Icon(Icons.remove)),
              SizedBox(width: 70, child: Text('$value min', textAlign: TextAlign.center)),
              IconButton(onPressed: () => setState(() => value = (value + 1).clamp(0, 60)), icon: const Icon(Icons.add)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () { onSave(value); Navigator.pop(context); }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Future<void> _editWorkDays(BuildContext context, List<int> current, ValueChanged<List<int>> onSave) async {
    final selected = current.toSet();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Work days'),
          content: Wrap(
            spacing: 4,
            children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  label: Text(names[i]),
                  selected: selected.contains(i + 1),
                  onSelected: (on) => setState(() => on ? selected.add(i + 1) : selected.remove(i + 1)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () { onSave(selected.toList()..sort()); Navigator.pop(context); }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _Kicker(this.label, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(label.toUpperCase(), style: AppTextStyles.kickerSm.copyWith(color: colors.textMuted)),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final VoidCallback? onTap;
  final bool isLast;

  const _NavRow({required this.label, required this.value, required this.colors, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.divider))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body.copyWith(color: colors.text, fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(value, style: AppTextStyles.body.copyWith(color: colors.textMuted, fontWeight: FontWeight.w400)),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(AppIcons.caretRight, size: 13, color: colors.textMuted),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final AppColors colors;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleRow({required this.label, required this.value, required this.colors, required this.onChanged, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.divider))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: colors.text, fontWeight: FontWeight.w500)),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 34,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: value ? colors.accentFill : colors.divider, borderRadius: BorderRadius.circular(10)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 16, height: 16, decoration: BoxDecoration(color: value ? Colors.white : colors.surface2, shape: BoxShape.circle)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VacationQuotaRow extends ConsumerWidget {
  final AppColors colors;
  const _VacationQuotaRow({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final quota = ref.watch(vacationQuotaForYearProvider(year)).valueOrNull;
    final totalDays = quota?.totalDays ?? 30;
    return _NavRow(
      label: 'Vacation quota',
      value: '${totalDays.round()} days/yr',
      colors: colors,
      onTap: () => _editVacationQuota(context, ref, year: year, current: totalDays),
    );
  }

  Future<void> _editVacationQuota(BuildContext context, WidgetRef ref, {required int year, required double current}) async {
    var value = current;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Vacation quota'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () => setState(() => value = (value - 1).clamp(0, 60)), icon: const Icon(Icons.remove)),
              SizedBox(width: 70, child: Text('${value.round()} days', textAlign: TextAlign.center)),
              IconButton(onPressed: () => setState(() => value = (value + 1).clamp(0, 60)), icon: const Icon(Icons.add)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                ref.read(vacationQuotaRepositoryProvider).setQuota(year: year, totalDays: value);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicHolidaysRow extends ConsumerWidget {
  final AppColors colors;
  const _PublicHolidaysRow({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final count = ref.watch(publicHolidaysForYearProvider(year)).valueOrNull?.length ?? 0;
    return _NavRow(
      label: 'Public holidays',
      value: 'DE (BW) · $count',
      colors: colors,
      isLast: true,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HolidayListScreen())),
    );
  }
}
