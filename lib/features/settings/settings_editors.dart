/// The editors behind Settings' rows.
///
/// All of them are the same shape — a dialog, one control, Cancel and Save —
/// and all of them return a value rather than writing it, so the screen stays
/// the only place that knows how a setting is persisted. That matters here more
/// than usual: `app_settings` rows are versioned, and a save writes a whole new
/// row, so every write has to go through the one carry-forward path.
library;

import 'package:flutter/material.dart' show Switch;
import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/buttons.dart';
import '../../widgets/stepper_field.dart';

/// A number adjusted in fixed steps. Returns null if cancelled.
Future<double?> editNumber(
  BuildContext context, {
  required String title,
  required double initial,
  required double min,
  required double max,
  required double step,
  required String Function(double) format,
  String? unit,
}) {
  var value = initial;

  return showAppDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AppDialog(
        title: title,
        actions: [
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          PrimaryPill(
            label: 'Save',
            expand: false,
            height: AppSize.touch,
            onPressed: () => Navigator.pop(context, value),
          ),
        ],
        child: StepperField(
          label: format(value),
          unit: unit,
          onDecrease: value <= min
              ? null
              : () => setState(() => value = (value - step).clamp(min, max)),
          onIncrease: value >= max
              ? null
              : () => setState(() => value = (value + step).clamp(min, max)),
        ),
      ),
    ),
  );
}

/// Which weekdays are worked. Returns null if cancelled.
Future<List<int>?> editWorkDays(BuildContext context, List<int> initial) {
  final selected = initial.toSet();

  return showAppDialog<List<int>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AppDialog(
        title: 'Work days',
        actions: [
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
          PrimaryPill(
            label: 'Save',
            expand: false,
            height: AppSize.touch,
            onPressed: () => Navigator.pop(context, selected.toList()..sort()),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekdayToggles(
              selected: selected,
              onToggle: (day) => setState(() {
                if (!selected.remove(day)) selected.add(day);
              }),
            ),
            const SizedBox(height: AppSpace.s3),
            Text(
              '${selected.length} day${selected.length == 1 ? '' : 's'} selected',
              style: AppTextStyles.caption.copyWith(color: context.colors.textMuted),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Normal working hours, as minutes since midnight.
///
/// Not a constraint on anything — nothing is refused for falling outside it.
/// It is how the balance tells "gone home" from "stepped out": an idle hour at
/// 14:00 is a long lunch, the same hour at 19:00 means the day is over.
class WorkWindow {
  const WorkWindow({required this.startMinutes, required this.endMinutes});

  final int startMinutes;
  final int endMinutes;
}

/// Half-hour steps: the window is a rough boundary, and minute precision would
/// imply it decides more than it does.
Future<WorkWindow?> editWorkWindow(
  BuildContext context, {
  required int startMinutes,
  required int endMinutes,
}) {
  var start = startMinutes;
  var end = endMinutes;
  const step = 30;

  return showAppDialog<WorkWindow>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final colors = context.colors;

        return AppDialog(
          title: 'Work hours',
          subtitle: 'Outside these, an idle hour means the day is done.',
          actions: [
            AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
            PrimaryPill(
              label: 'Save',
              expand: false,
              height: AppSize.touch,
              onPressed: () => Navigator.pop(
                context,
                WorkWindow(startMinutes: start, endMinutes: end),
              ),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FROM', style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s2),
              StepperField(
                label: AppFormat.minutesOfDay(start),
                // The two bounds are kept a step apart rather than allowed to
                // cross: a window that ends before it starts reads as wrapping
                // past midnight, which is a different setting entirely.
                onDecrease: start <= 0 ? null : () => setState(() => start -= step),
                onIncrease:
                    start >= end - step ? null : () => setState(() => start += step),
              ),
              const SizedBox(height: AppSpace.s5),
              Text('UNTIL', style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s2),
              StepperField(
                label: AppFormat.minutesOfDay(end),
                onDecrease:
                    end <= start + step ? null : () => setState(() => end -= step),
                onIncrease: end >= 24 * 60 - step ? null : () => setState(() => end += step),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// The two optional balance bounds and whether they reset each year.
class BalanceBounds {
  const BalanceBounds({this.floorHours, this.capHours, required this.annualReset});

  /// Null means not configured, which is not the same as zero: an unset bound
  /// never fires the warning treatment, and a zero one would fire on every
  /// negative day.
  final double? floorHours;
  final double? capHours;

  final bool annualReset;
}

Future<BalanceBounds?> editBalanceBounds(
  BuildContext context, {
  double? floorHours,
  double? capHours,
  required bool annualReset,
}) {
  var floor = floorHours;
  var cap = capHours;
  var reset = annualReset;

  return showAppDialog<BalanceBounds>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final colors = context.colors;

        return AppDialog(
          title: 'Floor / cap',
          subtitle: 'Warn when the balance passes a bound you set.',
          actions: [
            AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
            PrimaryPill(
              label: 'Save',
              expand: false,
              height: AppSize.touch,
              onPressed: () => Navigator.pop(
                context,
                BalanceBounds(floorHours: floor, capHours: cap, annualReset: reset),
              ),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FLOOR', style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s2),
              StepperField(
                label: floor == null ? 'Not set' : AppFormat.hm(floor!),
                unit: floor == null ? null : 'h',
                muted: floor == null,
                // Stepping down from "not set" starts at the first sensible
                // floor rather than at zero, which would warn immediately.
                onDecrease: () => setState(() {
                  floor = floor == null ? -5 : (floor! - 5).clamp(-200.0, 0.0);
                }),
                onIncrease: () => setState(() {
                  if (floor == null) return;
                  final next = floor! + 5;
                  floor = next > 0 ? null : next;
                }),
              ),
              const SizedBox(height: AppSpace.s5),
              Text('CAP', style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s2),
              StepperField(
                label: cap == null ? 'Not set' : AppFormat.hm(cap!, signed: true),
                unit: cap == null ? null : 'h',
                muted: cap == null,
                onDecrease: () => setState(() {
                  if (cap == null) return;
                  final next = cap! - 5;
                  cap = next < 0 ? null : next;
                }),
                onIncrease: () => setState(() {
                  cap = cap == null ? 5 : (cap! + 5).clamp(0.0, 200.0);
                }),
              ),
              const SizedBox(height: AppSpace.s5),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Annual reset',
                            style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
                        Text('Start each year back at zero',
                            style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(value: reset, onChanged: (on) => setState(() => reset = on)),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
