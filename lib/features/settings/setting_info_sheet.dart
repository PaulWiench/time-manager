/// "About this setting" (additions handoff §1.3, variant B, Paul's pick): the
/// sheet a settings row's icon opens. It explains the setting and, where the
/// setting is a value rather than a screen, holds its control — so reading
/// what something does and changing it happen in one place.
library;

import 'package:flutter/material.dart' show Switch;
import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/buttons.dart';
import '../../widgets/stepper_field.dart';

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

  /// The setting's own control, edited as a draft and saved together.
  final SettingControl? control;

  /// For settings that are a screen of their own: the button that opens it.
  final String? openLabel;
  final VoidCallback? onOpen;
}

/// The setting's semantic colour, when it has one.
enum SettingTone { plain, breaks, vacation, holiday }

/// The controls a setting can carry inside its sheet.
sealed class SettingControl {
  const SettingControl();
}

class ToggleControl extends SettingControl {
  const ToggleControl({required this.label, required this.value, required this.onSave});
  final String label;
  final bool value;
  final Future<void> Function(bool) onSave;
}

class NumberControl extends SettingControl {
  const NumberControl({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.format,
    this.unit,
    required this.onSave,
  });
  final double value;
  final double min;
  final double max;
  final double step;
  final String Function(double) format;
  final String? unit;
  final Future<void> Function(double) onSave;
}

class WorkDaysControl extends SettingControl {
  const WorkDaysControl({required this.value, required this.onSave});
  final List<int> value;
  final Future<void> Function(List<int>) onSave;
}

class WorkWindowControl extends SettingControl {
  const WorkWindowControl({required this.start, required this.end, required this.onSave});
  final int start;
  final int end;
  final Future<void> Function(int start, int end) onSave;
}

Future<void> showSettingInfo(BuildContext context, SettingInfo info) {
  return showAppSheet<void>(context: context, builder: (_) => SettingInfoSheet(info: info));
}

class SettingInfoSheet extends StatefulWidget {
  const SettingInfoSheet({super.key, required this.info});

  final SettingInfo info;

  @override
  State<SettingInfoSheet> createState() => _SettingInfoSheetState();
}

class _SettingInfoSheetState extends State<SettingInfoSheet> {
  late Object? _draft = switch (widget.info.control) {
    ToggleControl(:final value) => value,
    NumberControl(:final value) => value,
    WorkDaysControl(:final value) => {...value},
    WorkWindowControl(:final start, :final end) => (start, end),
    null => null,
  };
  bool _saving = false;

  bool get _changed => switch (widget.info.control) {
        ToggleControl(:final value) => _draft != value,
        NumberControl(:final value) => _draft != value,
        WorkDaysControl(:final value) =>
          !((_draft as Set<int>).length == value.length && (_draft as Set<int>).containsAll(value)),
        WorkWindowControl(:final start, :final end) => _draft != (start, end),
        null => false,
      };

  bool get _valid => switch (widget.info.control) {
        WorkDaysControl() => (_draft as Set<int>).isNotEmpty,
        _ => true,
      };

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      switch (widget.info.control) {
        case ToggleControl(:final onSave):
          await onSave(_draft! as bool);
        case NumberControl(:final onSave):
          await onSave(_draft! as double);
        case WorkDaysControl(:final onSave):
          await onSave((_draft! as Set<int>).toList()..sort());
        case WorkWindowControl(:final onSave):
          final (start, end) = _draft! as (int, int);
          await onSave(start, end);
        case null:
          break;
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      if (info.control != null) ...[
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
          if (info.rules.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  for (final (i, (left, right)) in info.rules.indexed) ...[
                    if (i > 0) Container(height: AppStroke.hair, color: colors.divider),
                    SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(left,
                                style: AppTextStyles.body.copyWith(color: colors.text)),
                          ),
                          Text(right,
                              style: AppTextStyles.bodyStrong.copyWith(color: colors.text)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (info.footnote != null)
            Text(info.footnote!,
                style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
          if (info.control != null) _control(context, info.control!),
        ],
      ),
    );
  }

  Widget _control(BuildContext context, SettingControl control) {
    final colors = context.colors;
    Widget kicker(String text) =>
        Text(text, style: AppTextStyles.kicker.copyWith(color: colors.textMuted));

    switch (control) {
      case ToggleControl(:final label):
        final on = _draft! as bool;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
              ),
              Switch(value: on, onChanged: (v) => setState(() => _draft = v)),
            ],
          ),
        );
      case NumberControl(:final min, :final max, :final step, :final format, :final unit):
        final value = _draft! as double;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kicker('VALUE'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: format(value),
              unit: unit,
              onDecrease: value - step < min - 1e-9
                  ? null
                  : () => setState(() => _draft = value - step),
              onIncrease: value + step > max + 1e-9
                  ? null
                  : () => setState(() => _draft = value + step),
            ),
          ],
        );
      case WorkDaysControl():
        final days = _draft! as Set<int>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kicker(days.isEmpty ? 'PICK AT LEAST ONE DAY' : 'WORK DAYS'),
            const SizedBox(height: AppSpace.s2),
            WeekdayToggles(
              selected: days,
              onToggle: (day) => setState(() {
                final next = {...days};
                if (!next.remove(day)) next.add(day);
                _draft = next;
              }),
            ),
          ],
        );
      case WorkWindowControl():
        final (start, end) = _draft! as (int, int);
        const step = 30;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kicker('FROM'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: AppFormat.minutesOfDay(start),
              onDecrease: start <= 0 ? null : () => setState(() => _draft = (start - step, end)),
              onIncrease: start >= end - step
                  ? null
                  : () => setState(() => _draft = (start + step, end)),
            ),
            const SizedBox(height: AppSpace.s4),
            kicker('UNTIL'),
            const SizedBox(height: AppSpace.s2),
            StepperField(
              label: AppFormat.minutesOfDay(end),
              onDecrease:
                  end <= start + step ? null : () => setState(() => _draft = (start, end - step)),
              onIncrease: end >= 24 * 60 - step
                  ? null
                  : () => setState(() => _draft = (start, end + step)),
            ),
          ],
        );
    }
  }
}
