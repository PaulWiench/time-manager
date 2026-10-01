/// Add / edit job (additions handoff §3.6) and the End job sheet (§3.7).
///
/// One screen for a job's details, schedule, balance and leave. Saving an
/// existing job writes a new settings row from today when its schedule
/// changed — the same versioning Settings uses — so its past days keep the
/// targets they had.
library;

import 'package:flutter/material.dart'
    show MediaQuery, Scaffold, TimeOfDay, showTimePicker;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../data/repositories/job_repository.dart';
import '../../domain/date_only.dart';
import '../../domain/leave_days.dart';
import '../../domain/vacation_proration.dart';
import '../../providers/database_providers.dart';
import '../../providers/job_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/app_form_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/stepper_field.dart';
import '../settings/settings_editors.dart';
import '../settings/settings_view.dart' show balanceBoundsLabel;

final _date = DateFormat('d MMM yyyy');
final _dayMonth = DateFormat('d MMM');

/// [jobId] null adds a new job.
class EditJobScreen extends ConsumerStatefulWidget {
  const EditJobScreen({super.key, this.jobId});

  final int? jobId;

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  final _name = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String? _saveError;

  Job? _job;
  AppSetting? _settings;
  VacationQuota? _quota;
  DateTime? _firstTracked;
  DateTime? _lastTracked;

  late DateTime _start = dateOnly(DateTime.now());
  DateTime? _end;
  double _weeklyHours = 39.5;
  Set<int> _workDays = {1, 2, 3, 4, 5};
  int _windowStart = 8 * 60;
  int _windowEnd = 18 * 60;
  double _startingBalance = 0;
  double? _floor;
  double? _cap;
  bool _annualReset = false;
  double _quotaDays = 30;

  bool get _isNew => widget.jobId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.jobId;
    final db = ref.read(appDatabaseProvider);
    if (id == null) {
      // A new job starts from the selected one's shape — most second jobs
      // share the work window, if not the hours.
      final current = ref.read(selectedJobIdProvider);
      final s = current == null ? null : await db.settingsDao.latest(current);
      if (s != null) {
        _windowStart = s.workWindowStartMinutes;
        _windowEnd = s.workWindowEndMinutes;
      }
    } else {
      final job = await db.jobDao.byId(id);
      final settings = await db.settingsDao.latest(id);
      final quota = await db.vacationQuotaDao.standingFor(id, DateTime.now().year);
      final span = await ref.read(jobRepositoryProvider).trackedSpan(id);
      if (job == null) return;
      _job = job;
      _settings = settings;
      _quota = quota;
      _firstTracked = span.first;
      _lastTracked = span.last;
      _name.text = job.name;
      _start = dateOnly(job.startDate);
      _end = job.endDate == null ? null : dateOnly(job.endDate!);
      _startingBalance = job.startingBalanceHours;
      if (settings != null) {
        _weeklyHours = settings.weeklyHours;
        _workDays = {...settings.workDays};
        _windowStart = settings.workWindowStartMinutes;
        _windowEnd = settings.workWindowEndMinutes;
        _floor = settings.balanceFloorHours;
        _cap = settings.balanceCapHours;
        _annualReset = settings.balanceAnnualReset;
      }
      _quotaDays = quota?.totalDays ?? 30;
    }
    if (mounted) setState(() => _loaded = true);
  }

  // ---------------------------------------------------------------- checks

  String? get _nameError => _name.text.trim().isEmpty ? 'Give the job a name' : null;

  String? get _startError => _firstTracked != null && _start.isAfter(_firstTracked!)
      ? 'Sessions exist from ${_dayMonth.format(_firstTracked!)}. Start on or before that.'
      : null;

  String? get _endError {
    final end = _end;
    if (end == null) return null;
    if (end.isBefore(_start)) return 'Ends before it starts';
    if (_lastTracked != null && end.isBefore(_lastTracked!)) {
      return 'Sessions exist until ${_dayMonth.format(_lastTracked!)}. End on or after that.';
    }
    return null;
  }

  String? get _scheduleError {
    if (_workDays.isEmpty || _weeklyHours <= 0) return 'Pick at least one work day';
    if (_windowStart >= _windowEnd) return 'Window must end after it starts';
    return null;
  }

  bool get _valid =>
      _nameError == null && _startError == null && _endError == null && _scheduleError == null;

  // ---------------------------------------------------------------- pickers

  Future<void> _pickDate({required bool start}) async {
    final picked = await showAppDatePicker(
      context: context,
      initial: start ? _start : (_end ?? dateOnly(DateTime.now())),
      last: DateTime(DateTime.now().year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _start = dateOnly(picked);
      } else {
        _end = dateOnly(picked);
      }
    });
  }

  Future<void> _pickTime({required bool from}) async {
    final minutes = from ? _windowStart : _windowEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final value = picked.hour * 60 + picked.minute;
      if (from) {
        _windowStart = value;
      } else {
        _windowEnd = value;
      }
    });
  }

  Future<void> _editBounds() async {
    final bounds = await editBalanceBounds(
      context,
      floorHours: _floor,
      capHours: _cap,
      annualReset: _annualReset,
    );
    if (bounds == null || !mounted) return;
    setState(() {
      _floor = bounds.floorHours;
      _cap = bounds.capHours;
      _annualReset = bounds.annualReset;
    });
  }

  // ---------------------------------------------------------------- saving

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final jobs = ref.read(jobRepositoryProvider);
    final today = dateOnly(DateTime.now());
    final days = _workDays.toList()..sort();
    try {
      if (_isNew) {
        await jobs.createJob(
          name: _name.text,
          startDate: _start,
          endDate: _end,
          weeklyHours: _weeklyHours,
          workDays: days,
          workWindowStartMinutes: _windowStart,
          workWindowEndMinutes: _windowEnd,
          startingBalanceHours: _startingBalance,
          balanceFloorHours: _floor,
          balanceCapHours: _cap,
          balanceAnnualReset: _annualReset,
          vacationDaysPerYear: _quotaDays,
        );
      } else {
        final id = widget.jobId!;
        await jobs.updateJob(
          id,
          name: _name.text,
          startDate: _start,
          endDate: _end,
          startingBalanceHours: _startingBalance,
        );
        final s = _settings;
        final scheduleChanged = s == null ||
            s.weeklyHours != _weeklyHours ||
            !(s.workDays.length == days.length && s.workDays.toSet().containsAll(days)) ||
            s.workWindowStartMinutes != _windowStart ||
            s.workWindowEndMinutes != _windowEnd ||
            s.balanceFloorHours != _floor ||
            s.balanceCapHours != _cap ||
            s.balanceAnnualReset != _annualReset;
        if (scheduleChanged) {
          await ref.read(settingsRepositoryProvider).save(
                jobId: id,
                // A job that has not started yet gets its schedule from its start.
                effectiveFrom: _start.isAfter(today) ? _start : today,
                weeklyHours: _weeklyHours,
                workDays: days,
                minSessionMinutes: s?.minSessionMinutes ?? 5,
                autoBreakEnabled: s?.autoBreakEnabled ?? true,
                restrictCheckin: s?.restrictCheckin ?? false,
                workWindowStartMinutes: _windowStart,
                workWindowEndMinutes: _windowEnd,
                balanceFloorHours: _floor,
                balanceCapHours: _cap,
                balanceAnnualReset: _annualReset,
              );
        }
        if ((_quota?.totalDays ?? 30) != _quotaDays) {
          await ref
              .read(vacationQuotaRepositoryProvider)
              .setQuota(jobId: id, year: today.year, totalDays: _quotaDays);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } on JobDatesError catch (e) {
      if (mounted) setState(() => _saveError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _endJob() async {
    final job = _job;
    if (job == null) return;
    final summary = ref.read(jobSummaryProvider(job.id));
    final lastDay = await showEndJobSheet(
      context,
      job: job,
      finalBalance: summary?.balance ?? job.startingBalanceHours,
      yearlyQuota: _quotaDays,
      earliest: _lastTracked ?? dateOnly(job.startDate),
    );
    if (lastDay == null || !mounted) return;
    await ref.read(jobRepositoryProvider).endJob(job.id, lastDay);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reopen() async {
    final job = _job;
    if (job == null) return;
    await ref.read(jobRepositoryProvider).reopenJob(job.id);
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------- layout

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!_loaded) {
      return Scaffold(backgroundColor: colors.background, body: const SizedBox.shrink());
    }

    final job = _job;
    final perDay = _workDays.isEmpty ? 0.0 : _weeklyHours / _workDays.length;
    final year = DateTime.now().year;
    final prorated = proratedVacationDays(
      yearlyQuota: _quotaDays,
      jobStart: _start,
      jobEnd: _end,
      year: year,
    );
    final showCallout = _start.year == year || _end?.year == year;

    Widget section(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.s1),
              child: Text(title, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
            ),
            const SizedBox(height: AppSpace.s2),
            Container(
              padding: const EdgeInsets.all(AppSpace.s4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.divider, width: AppStroke.hair),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpace.s3),
                    child,
                  ],
                ],
              ),
            ),
          ],
        );

    Widget caption(String text, {bool warning = false}) => Text(
          text,
          style: AppTextStyles.caption
              .copyWith(color: warning ? colors.warningText : colors.textMuted),
        );

    Widget divider() => Container(height: AppStroke.hair, color: colors.divider);

    return SubScreen(
      title: _isNew ? 'New job' : 'Edit job',
      subtitle: job == null ? null : '${job.name} · since ${_date.format(job.startDate)}',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutterDense,
          0,
          AppSpace.gutterDense,
          AppSpace.s8 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          section('DETAILS', [
            AppTextField(
              label: 'NAME',
              controller: _name,
              placeholder: 'e.g. Lecturing',
              autofocus: _isNew,
              maxLength: 40,
              error: _name.text.isEmpty && !_isNew ? _nameError : null,
              onChanged: (_) => setState(() {}),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SheetField(
                    label: 'START DATE',
                    value: _date.format(_start),
                    onTap: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    children: [
                      SheetField(
                        label: 'END DATE',
                        value: _end == null ? 'None' : _date.format(_end!),
                        valueStyle: _end == null
                            ? AppTextStyles.statSm.copyWith(color: colors.textMuted)
                            : null,
                        onTap: () => _pickDate(start: false),
                      ),
                      const SizedBox(height: AppSpace.s1),
                      caption('Optional'),
                    ],
                  ),
                ),
              ],
            ),
            if (_startError != null) caption(_startError!, warning: true),
            if (_endError != null) caption(_endError!, warning: true),
          ]),
          const SizedBox(height: AppSpace.s6),
          section('SCHEDULE', [
            caption('Weekly hours'),
            StepperField(
              label: _weeklyHours == _weeklyHours.roundToDouble()
                  ? '${_weeklyHours.round()}'
                  : _weeklyHours.toStringAsFixed(1),
              unit: 'h',
              onDecrease: _weeklyHours <= 0 ? null : () => setState(() => _weeklyHours -= 0.5),
              onIncrease: _weeklyHours >= 80 ? null : () => setState(() => _weeklyHours += 0.5),
            ),
            divider(),
            caption('Work days · ${AppFormat.hm(perDay)} h per day'),
            WeekdayToggles(
              selected: _workDays,
              onToggle: (day) => setState(() {
                final next = {..._workDays};
                if (!next.remove(day)) next.add(day);
                _workDays = next;
              }),
            ),
            divider(),
            Row(
              children: [
                Expanded(
                  child: SheetField(
                    label: 'WINDOW FROM',
                    value: AppFormat.minutesOfDay(_windowStart),
                    onTap: () => _pickTime(from: true),
                  ),
                ),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: SheetField(
                    label: 'UNTIL',
                    value: AppFormat.minutesOfDay(_windowEnd),
                    onTap: () => _pickTime(from: false),
                  ),
                ),
              ],
            ),
            if (_scheduleError != null) caption(_scheduleError!, warning: true),
          ]),
          const SizedBox(height: AppSpace.s6),
          section('BALANCE', [
            caption('Starting balance'),
            StepperField(
              label: AppFormat.hm(_startingBalance, signed: _startingBalance != 0),
              unit: 'h',
              onDecrease: () => setState(() => _startingBalance -= 0.25),
              onIncrease: () => setState(() => _startingBalance += 0.25),
            ),
            divider(),
            _LinkRow(
              icon: AppIcons.scales,
              label: 'Floor / cap',
              value: balanceBoundsLabel(_floor, _cap),
              onTap: _editBounds,
            ),
          ]),
          const SizedBox(height: AppSpace.s6),
          section('LEAVE', [
            caption('Vacation days per year'),
            StepperField(
              label: '${_quotaDays.round()}',
              unit: 'd',
              onDecrease: _quotaDays <= 0 ? null : () => setState(() => _quotaDays -= 1),
              onIncrease: _quotaDays >= 60 ? null : () => setState(() => _quotaDays += 1),
            ),
            if (showCallout) ProrateCallout(prorated: prorated, start: _start, year: year, quota: _quotaDays),
          ]),
          const SizedBox(height: AppSpace.s6),
          if (_saveError != null) ...[
            caption(_saveError!, warning: true),
            const SizedBox(height: AppSpace.s3),
          ],
          PrimaryPill(label: 'Save', onPressed: _valid && !_saving ? _save : null),
          if (job != null) ...[
            const SizedBox(height: AppSpace.s3),
            if (job.endDate == null)
              SecondaryPill(label: 'End job…', onPressed: _endJob)
            else
              SecondaryPill(label: 'Reopen job', onPressed: _reopen),
            const SizedBox(height: AppSpace.s2),
            Center(child: caption('Ending keeps the history and final balance')),
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.value, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSize.touch,
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.lg, color: colors.text),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
            ),
            Text(value, style: AppTextStyles.body.copyWith(color: colors.textMuted)),
            const SizedBox(width: AppSpace.s1),
            Icon(AppIcons.caretRight, size: AppIconSize.md, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// "23 days in 2026 — Pro-rated: 9 full months from 15 Mar, 30 × 9/12 =
/// 22.5, rounded up. 30 days from 2027."
class ProrateCallout extends StatelessWidget {
  const ProrateCallout({
    super.key,
    required this.prorated,
    required this.start,
    required this.year,
    required this.quota,
  });

  final ProratedVacation prorated;
  final DateTime start;
  final int year;
  final double quota;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exact = prorated.exact;
    final rounding = exact == prorated.days
        ? ''
        : (prorated.days > exact ? ', rounded up' : ', rounded down');
    final from = start.year == year ? ' from ${_dayMonth.format(start)}' : '';
    final text = prorated.isProrated
        ? 'Pro-rated: ${prorated.fullMonths} full months$from, '
            '${formatLeaveDays(quota)} × ${prorated.fullMonths}/12 = '
            '${exact.toStringAsFixed(exact == exact.roundToDouble() ? 0 : 1)}$rounding. '
            '${formatLeaveDays(quota)} days from ${year + 1}.'
        : 'The full quota: the job covers all of $year.';

    return Container(
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(
        color: colors.accentTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.calendarDots, size: AppIconSize.lg, color: colors.accentText),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${formatLeaveDays(prorated.days)} days in $year',
                    style: AppTextStyles.bodyLg.copyWith(color: colors.accentText)),
                const SizedBox(height: 2),
                Text(text, style: AppTextStyles.caption.copyWith(color: colors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The End job sheet. Returns the chosen last working day, or null.
Future<DateTime?> showEndJobSheet(
  BuildContext context, {
  required Job job,
  required double finalBalance,
  required double yearlyQuota,
  required DateTime earliest,
}) {
  return showAppSheet<DateTime>(
    context: context,
    builder: (_) => EndJobSheet(
      job: job,
      finalBalance: finalBalance,
      yearlyQuota: yearlyQuota,
      earliest: earliest,
    ),
  );
}

class EndJobSheet extends StatefulWidget {
  const EndJobSheet({
    super.key,
    required this.job,
    required this.finalBalance,
    required this.yearlyQuota,
    required this.earliest,
    this.initial,
  });

  final Job job;
  final double finalBalance;
  final double yearlyQuota;
  final DateTime earliest;
  final DateTime? initial;

  @override
  State<EndJobSheet> createState() => _EndJobSheetState();
}

class _EndJobSheetState extends State<EndJobSheet> {
  late DateTime _last = widget.initial ?? dateOnly(DateTime.now());

  Future<void> _pick() async {
    final picked = await showAppDatePicker(
      context: context,
      initial: _last,
      last: DateTime(DateTime.now().year + 3),
    );
    if (picked != null && mounted) setState(() => _last = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tooEarly = _last.isBefore(widget.earliest);
    final prorated = proratedVacationDays(
      yearlyQuota: widget.yearlyQuota,
      jobStart: widget.job.startDate,
      jobEnd: _last,
      year: _last.year,
    );

    Widget consequence(IconData icon, String text) => SizedBox(
          height: 32,
          child: Row(
            children: [
              Icon(icon, size: AppIconSize.lg, color: colors.textMuted),
              const SizedBox(width: AppSpace.s3),
              Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: colors.text))),
            ],
          ),
        );

    return AppSheet(
      title: 'End ${widget.job.name}?',
      subtitle: 'You can reopen it later from Settings → Jobs',
      actions: [
        SecondaryPill(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryPill(
          label: 'End job',
          onPressed: tooEarly ? null : () => Navigator.of(context).pop(_last),
        ),
      ],
      children: [
        GestureDetector(
          onTap: _pick,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tooEarly ? colors.warningTint : colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LAST WORKING DAY',
                          style: AppTextStyles.kicker.copyWith(
                              color: tooEarly ? colors.warningText : colors.textMuted)),
                      const SizedBox(height: 2),
                      Text('${AppFormat.dayRow(_last)} ${_last.year}',
                          style: AppTextStyles.statSm
                              .copyWith(color: tooEarly ? colors.warningText : colors.text)),
                    ],
                  ),
                ),
                Icon(AppIcons.calendarDots, size: AppIconSize.lg, color: colors.textMuted),
              ],
            ),
          ),
        ),
        if (tooEarly)
          Text(
            'Sessions exist until ${_dayMonth.format(widget.earliest)}. End on or after that.',
            style: AppTextStyles.caption.copyWith(color: colors.warningText),
          ),
        Column(
          children: [
            consequence(AppIcons.power, 'Check-in turns off for this job'),
            const SizedBox(height: AppSpace.s3),
            consequence(AppIcons.scales,
                'Final balance ${AppFormat.hm(widget.finalBalance, signed: true)} is kept'),
            const SizedBox(height: AppSpace.s3),
            consequence(AppIcons.clockCounterClockwise, 'History and stats stay available'),
            const SizedBox(height: AppSpace.s3),
            consequence(AppIcons.airplaneTilt,
                'Vacation pro-rated to ${formatLeaveDays(prorated.days)} days in ${_last.year}'),
          ],
        ),
      ],
    );
  }
}
