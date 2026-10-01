/// "About this setting" (additions handoff §1.3, variant B, Paul's pick): the
/// sheet a settings row's icon opens. It explains the setting and, where the
/// setting is a value rather than a screen, holds its control — so reading
/// what something does and changing it happen in one place. Finer options
/// that the main list does not show live under ADVANCED here.
library;

import 'package:flutter/material.dart' show Switch;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/date_only.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/buttons.dart';
import '../../widgets/stepper_field.dart';
import 'settings_editors.dart' show BalanceBounds;

/// What the sheet says about one setting.
class SettingInfo {
  const SettingInfo({
    required this.name,
    required this.group,
    required this.value,
    required this.icon,
    required this.body,
    this.tone = SettingTone.plain,
    this.rules = const [],
    this.footnote,
    this.control,
    this.advanced = const [],
    this.appliesFrom,
    this.openLabel,
    this.onOpen,
  });

  final String name;

  /// "Breaks", shown with the current value under the title.
  final String group;
  final String value;
  final IconData icon;
  final String body;
  final SettingTone tone;

  /// A small two-column table, e.g. the break law's thresholds.
  final List<(String, String)> rules;
  final String? footnote;

  /// The setting's own control.
  final SettingControl? control;

  /// Finer controls, under ADVANCED. Saved together with [control].
  final List<SettingControl> advanced;

  /// Offers an "Applies from" date under ADVANCED: a schedule change can
  /// count from a past date. Every control's save receives the chosen date;
  /// without this it is always today.
  final AppliesFrom? appliesFrom;

  /// For settings that are a screen of their own: the button that opens it.
  final String? openLabel;
  final VoidCallback? onOpen;
}

class AppliesFrom {
  const AppliesFrom({required this.earliest});

  /// The job's start: nothing can apply before the job existed.
  final DateTime earliest;
}

/// The setting's semantic colour, when it has one.
enum SettingTone { plain, breaks, vacation, holiday }

/// The controls a setting can carry inside its sheet. Every save receives
/// the "applies from" date — today unless the sheet offers a choice.
sealed class SettingControl {
  const SettingControl({this.label});

  /// Heads the control; required for advanced ones, which need saying what
  /// they are.
  final String? label;

  /// One line under an advanced control: what it changes.
  String? get hint => null;
}

class ToggleControl extends SettingControl {
  const ToggleControl({required String label, required this.value, required this.onSave})
      : super(label: label);
  final bool value;
  final Future<void> Function(bool value, DateTime from) onSave;
}

class NumberControl extends SettingControl {
  const NumberControl({
    super.label,
    this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.format,
    this.unit,
    required this.onSave,
  });
  final String? description;
  final double value;
  final double min;
  final double max;
  final double step;
  final String Function(double) format;
  final String? unit;
  final Future<void> Function(double value, DateTime from) onSave;

  @override
  String? get hint => description;
}

class WorkDaysControl extends SettingControl {
  const WorkDaysControl({required this.value, required this.onSave});
  final List<int> value;
  final Future<void> Function(List<int> value, DateTime from) onSave;
}

class WorkWindowControl extends SettingControl {
  const WorkWindowControl({required this.start, required this.end, required this.onSave});
  final int start;
  final int end;
  final Future<void> Function(int start, int end, DateTime from) onSave;
}

class BoundsControl extends SettingControl {
  const BoundsControl({required this.value, required this.onSave});
  final BalanceBounds value;
  final Future<void> Function(BalanceBounds value, DateTime from) onSave;
}

Future<void> showSettingInfo(BuildContext context, SettingInfo info) {
  return showAppSheet<void>(context: context, builder: (_) => SettingInfoSheet(info: info));
}

final _date = DateFormat('EEE d MMM yyyy');

class SettingInfoSheet extends StatefulWidget {
  const SettingInfoSheet({super.key, required this.info, this.today});

  final SettingInfo info;

  /// Pinned in the render harness; the clock otherwise.
  final DateTime? today;

  @override
  State<SettingInfoSheet> createState() => _SettingInfoSheetState();
}

class _SettingInfoSheetState extends State<SettingInfoSheet> {
  late final List<SettingControl> _controls = [
    if (widget.info.control != null) widget.info.control!,
    ...widget.info.advanced,
  ];
  late final List<Object?> _drafts = [for (final c in _controls) _initial(c)];
  late final DateTime _today = dateOnly(widget.today ?? DateTime.now());
  late DateTime _from = _today;
  bool _saving = false;

  static Object? _initial(SettingControl c) => switch (c) {
        ToggleControl(:final value) => value,
        NumberControl(:final value) => value,
        WorkDaysControl(:final value) => {...value},
        WorkWindowControl(:final start, :final end) => (start, end),
        BoundsControl(:final value) => value,
      };

  static bool _differs(SettingControl c, Object? draft) => switch (c) {
        ToggleControl(:final value) => draft != value,
        NumberControl(:final value) => draft != value,
        WorkDaysControl(:final value) =>
          !((draft! as Set<int>).length == value.length &&
              (draft as Set<int>).containsAll(value)),
        WorkWindowControl(:final start, :final end) => draft != (start, end),
        BoundsControl(:final value) => (draft! as BalanceBounds).floorHours != value.floorHours ||
            (draft as BalanceBounds).capHours != value.capHours ||
            draft.annualReset != value.annualReset,
      };

  bool get _changed => [
        for (final (i, c) in _controls.indexed) _differs(c, _drafts[i]),
      ].any((d) => d);

  bool get _valid => [
        for (final (i, c) in _controls.indexed)
          c is! WorkDaysControl || (_drafts[i]! as Set<int>).isNotEmpty,
      ].every((v) => v);

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      for (final (i, c) in _controls.indexed) {
        if (!_differs(c, _drafts[i])) continue;
        final draft = _drafts[i];
        switch (c) {
          case ToggleControl(:final onSave):
            await onSave(draft! as bool, _from);
          case NumberControl(:final onSave):
            await onSave(draft! as double, _from);
          case WorkDaysControl(:final onSave):
            await onSave((draft! as Set<int>).toList()..sort(), _from);
          case WorkWindowControl(:final onSave):
            final (start, end) = draft! as (int, int);
            await onSave(start, end, _from);
          case BoundsControl(:final onSave):
            await onSave(draft! as BalanceBounds, _from);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showAppDatePicker(context: context, initial: _from, now: _today);
    if (picked == null || !mounted) return;
    final earliest = dateOnly(widget.info.appliesFrom!.earliest);
    final day = dateOnly(picked);
    setState(() => _from = day.isBefore(earliest) ? earliest : day);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final colors = context.colors;
    final (tint, ink) = switch (info.tone) {
      SettingTone.plain => (colors.surface2, colors.text),
      SettingTone.breaks => (colors.breakTint, colors.breakText),
      SettingTone.vacation => (colors.vacationTint, colors.vacationText),
      SettingTone.holiday => (colors.holidayTint, colors.holidayText),
    };

    final actions = <Widget>[
      if (_controls.isNotEmpty) ...[
        SecondaryPill(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryPill(
          label: _changed ? 'Save' : 'Got it',
          onPressed: _saving || !_valid
              ? null
              : (_changed ? _save : () => Navigator.of(context).pop()),
        ),
      ] else ...[
        if (info.onOpen != null)
          SecondaryPill(
            label: info.openLabel ?? 'Open setting',
            onPressed: () {
              Navigator.of(context).pop();
              info.onOpen!();
            },
          ),
        PrimaryPill(label: 'Got it', onPressed: () => Navigator.of(context).pop()),
      ],
    ];

    final hasAdvanced = info.advanced.isNotEmpty || info.appliesFrom != null;
    final mainCount = info.control == null ? 0 : 1;

    return SingleChildScrollView(
      child: AppSheet(
        title: info.name,
        subtitle: '${info.group} · ${info.value}',
        actions: actions,
        children: [
          Row(
            children: [
              Container(
                width: AppSize.touch,
                height: AppSize.touch,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(info.icon, size: AppIconSize.xl, color: ink),
              ),
              const SizedBox(width: AppSpace.s3),
              Text('ABOUT THIS SETTING',
                  style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
            ],
          ),
          Text(info.body, style: AppTextStyles.body.copyWith(color: colors.text)),
          if (info.rules.isNotEmpty) _RulesTable(rules: info.rules),
          if (info.footnote != null)
            Text(info.footnote!, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
          for (var i = 0; i < mainCount; i++) _control(context, i),
          if (hasAdvanced) ...[
            Container(height: AppStroke.hair, color: colors.divider),
            Text('ADVANCED', style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
            for (var i = mainCount; i < _controls.length; i++) _control(context, i),
            if (info.appliesFrom != null) _appliesFrom(context),
          ],
        ],
      ),
    );
  }

  Widget _appliesFrom(BuildContext context) {
    final colors = context.colors;
    final past = _from.isBefore(_today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetField(
          label: 'APPLIES FROM',
          value: _from == _today ? 'Today' : _date.format(_from),
          onTap: _pickFrom,
        ),
        const SizedBox(height: AppSpace.s1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
          child: Text(
            past
                ? 'Every day since ${_date.format(_from)} is recalculated with the new value. '
                    'Days before it keep theirs.'
                : 'A change counts from today. Pick an earlier date if it started before — '
                    'past days are then recalculated.',
            style: AppTextStyles.caption.copyWith(color: past ? colors.text : colors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _control(BuildContext context, int index) {
    final colors = context.colors;
    final control = _controls[index];
    final draft = _drafts[index];
    void set(Object? value) => setState(() => _drafts[index] = value);
    Widget kicker(String text) =>
        Text(text, style: AppTextStyles.kicker.copyWith(color: colors.textMuted));
    Widget labelled(String fallback, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kicker(control.label ?? fallback),
            const SizedBox(height: AppSpace.s2),
            child,
            if (control.hint != null) ...[
              const SizedBox(height: AppSpace.s1),
              Text(control.hint!, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
            ],
          ],
        );

    switch (control) {
      case ToggleControl(:final label):
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label!, style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
              ),
              Switch(value: draft! as bool, onChanged: set),
            ],
          ),
        );
      case NumberControl(:final min, :final max, :final step, :final format, :final unit):
        final value = draft! as double;
        return labelled(
          'VALUE',
          StepperField(
            label: format(value),
            unit: unit,
            onDecrease: value - step < min - 1e-9 ? null : () => set(value - step),
            onIncrease: value + step > max + 1e-9 ? null : () => set(value + step),
          ),
        );
      case WorkDaysControl():
        final days = draft! as Set<int>;
        return labelled(
          days.isEmpty ? 'PICK AT LEAST ONE DAY' : 'WORK DAYS',
          WeekdayToggles(
            selected: days,
            onToggle: (day) {
              final next = {...days};
              if (!next.remove(day)) next.add(day);
              set(next);
            },
          ),
        );
      case WorkWindowControl():
        final (start, end) = draft! as (int, int);
        const step = 30;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kicker('FROM'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: AppFormat.minutesOfDay(start),
              onDecrease: start <= 0 ? null : () => set((start - step, end)),
              onIncrease: start >= end - step ? null : () => set((start + step, end)),
            ),
            const SizedBox(height: AppSpace.s4),
            kicker('UNTIL'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: AppFormat.minutesOfDay(end),
              onDecrease: end <= start + step ? null : () => set((start, end - step)),
              onIncrease: end >= 24 * 60 - step ? null : () => set((start, end + step)),
            ),
          ],
        );
      case BoundsControl():
        final b = draft! as BalanceBounds;
        BalanceBounds with_({Object? floor = _keep, Object? cap = _keep, bool? reset}) =>
            BalanceBounds(
              floorHours: identical(floor, _keep) ? b.floorHours : floor as double?,
              capHours: identical(cap, _keep) ? b.capHours : cap as double?,
              annualReset: reset ?? b.annualReset,
            );
        final floor = b.floorHours;
        final cap = b.capHours;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kicker('FLOOR'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: floor == null ? 'Not set' : AppFormat.hm(floor),
              unit: floor == null ? null : 'h',
              muted: floor == null,
              // Stepping down from "not set" starts at the first sensible
              // floor rather than at zero, which would warn immediately.
              onDecrease: () =>
                  set(with_(floor: floor == null ? -5.0 : (floor - 5).clamp(-200.0, 0.0))),
              onIncrease: floor == null
                  ? null
                  : () => set(with_(floor: floor + 5 > 0 ? null : floor + 5)),
            ),
            const SizedBox(height: AppSpace.s4),
            kicker('CAP'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: cap == null ? 'Not set' : AppFormat.hm(cap, signed: true),
              unit: cap == null ? null : 'h',
              muted: cap == null,
              onDecrease: cap == null ? null : () => set(with_(cap: cap - 5 < 0 ? null : cap - 5)),
              onIncrease: () =>
                  set(with_(cap: cap == null ? 5.0 : (cap + 5).clamp(0.0, 200.0))),
            ),
            const SizedBox(height: AppSpace.s4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Reset each 1 January',
                        style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
                  ),
                  Switch(value: b.annualReset, onChanged: (v) => set(with_(reset: v))),
                ],
              ),
            ),
          ],
        );
    }
  }
}

const Object _keep = Object();

class _RulesTable extends StatelessWidget {
  const _RulesTable({required this.rules});

  final List<(String, String)> rules;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          for (final (i, (left, right)) in rules.indexed) ...[
            if (i > 0) Container(height: AppStroke.hair, color: colors.divider),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: Text(left, style: AppTextStyles.body.copyWith(color: colors.text)),
                  ),
                  Text(right, style: AppTextStyles.bodyStrong.copyWith(color: colors.text)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
