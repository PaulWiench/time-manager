/// Marking a day as leave — the one thing the app could already store, count
/// and colour in, but never edit.
///
/// `LeaveRepository.addLeave` / `deleteLeave` have existed since the data layer
/// was built and had no caller in `lib/` at all, so every leave entry on a real
/// install came from the import and stayed there forever. This is the sheet
/// that closes that.
///
/// Hours are never typed. A leave entry is always a fraction of *that date's*
/// own target, so a half day on a half public holiday resolves correctly and
/// Stats can always divide back out to a clean quarter of a day. Free-form
/// hours are what made the leave count read 15.8 instead of 16.
library;

import 'package:flutter/widgets.dart';

import '../core/format.dart';
import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../data/database/database.dart';
import '../data/database/enums.dart';
import 'app_bottom_sheet.dart';
import 'buttons.dart';
import 'press_scale.dart';
import 'segmented_control.dart';

/// The four sizes a leave day comes in. Paul's rule: full days, or in theory a
/// half and a quarter — never an arbitrary number of hours.
enum LeaveFraction {
  full(1.0, 'Full day'),
  threeQuarter(0.75, '¾ day'),
  half(0.5, '½ day'),
  quarter(0.25, '¼ day');

  const LeaveFraction(this.value, this.label);

  final double value;
  final String label;

  /// The closest fraction to an entry already on file, so reopening the sheet
  /// shows what is stored rather than resetting to a full day.
  static LeaveFraction nearest(double hours, double targetHours) {
    if (targetHours <= 0) return LeaveFraction.full;
    final ratio = hours / targetHours;
    var best = LeaveFraction.full;
    for (final f in LeaveFraction.values) {
      if ((f.value - ratio).abs() < (best.value - ratio).abs()) best = f;
    }
    return best;
  }
}

/// What the sheet was closed with. `null` from [showLeaveSheet] means the user
/// backed out and nothing should change.
class LeaveEdit {
  const LeaveEdit.set({required LeaveType this.type, required double this.hours})
      : cleared = false;

  const LeaveEdit.cleared()
      : type = null,
        hours = null,
        cleared = true;

  final LeaveType? type;
  final double? hours;

  /// Remove whatever leave the day already had, and add nothing.
  final bool cleared;
}

Future<LeaveEdit?> showLeaveSheet({
  required BuildContext context,
  required DateTime date,
  required double targetHours,
  required List<LeaveEntry> existing,
}) {
  final first = existing.isEmpty ? null : existing.first;
  var type = first?.type ?? LeaveType.vacation;
  var fraction = first == null
      ? LeaveFraction.full
      : LeaveFraction.nearest(first.hours, targetHours);

  return showAppSheet<LeaveEdit>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => LeaveSheetView(
        date: date,
        targetHours: targetHours,
        type: type,
        fraction: fraction,
        hasExisting: existing.isNotEmpty,
        onType: (value) => setState(() => type = value),
        onFraction: (value) => setState(() => fraction = value),
        onClear: () => Navigator.of(context).pop(const LeaveEdit.cleared()),
        onSave: targetHours <= 0
            ? null
            : () => Navigator.of(context).pop(
                  LeaveEdit.set(type: type, hours: targetHours * fraction.value),
                ),
      ),
    ),
  );
}

/// The presentational half, so the sheet can be rendered to a golden without a
/// database or a navigator — the same split every other screen got in Phase 3.
class LeaveSheetView extends StatelessWidget {
  const LeaveSheetView({
    super.key,
    required this.date,
    required this.targetHours,
    required this.type,
    required this.fraction,
    required this.hasExisting,
    this.onType,
    this.onFraction,
    this.onClear,
    this.onSave,
  });

  final DateTime date;

  /// That date's own target. Zero on a weekend or a whole public holiday,
  /// which is the one case where leave cannot be recorded at all.
  final double targetHours;

  final LeaveType type;
  final LeaveFraction fraction;
  final bool hasExisting;

  final ValueChanged<LeaveType>? onType;
  final ValueChanged<LeaveFraction>? onFraction;
  final VoidCallback? onClear;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final restDay = targetHours <= 0;

    return AppSheet(
      title: hasExisting ? 'Edit leave' : 'Mark as leave',
      subtitle: AppFormat.dayRow(date),
      actions: [
        if (hasExisting)
          SecondaryPill(label: 'Remove', onPressed: onClear)
        else
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        PrimaryPill(label: 'Save', onPressed: onSave),
      ],
      children: [
        SegmentedControl<LeaveType>(
          segments: const [
            (LeaveType.vacation, 'Vacation'),
            (LeaveType.sick, 'Sick day'),
            (LeaveType.flexDay, 'Flex day'),
          ],
          selected: type,
          onSelect: onType ?? (_) {},
        ),
        if (restDay)
          _Notice(
            text: 'Nothing is scheduled on ${AppFormat.dayRow(date)}, '
                'so there are no hours to take off.',
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in LeaveFraction.values)
                _FractionRow(
                  label: option.label,
                  hours: AppFormat.hm(targetHours * option.value),
                  selected: option == fraction,
                  ink: _inkFor(type, colors),
                  onTap: onFraction == null ? null : () => onFraction!(option),
                ),
            ],
          ),
      ],
    );
  }
}

Color _inkFor(LeaveType type, AppColors colors) => switch (type) {
      LeaveType.vacation => colors.vacationFill,
      LeaveType.sick => colors.sickFill,
      LeaveType.flexDay => colors.accentFill,
    };

class _FractionRow extends StatelessWidget {
  const _FractionRow({
    required this.label,
    required this.hours,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final String hours;
  final bool selected;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PressScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: SizedBox(
          height: AppSize.touch,
          child: Row(
            children: [
              Container(
                width: AppSize.swatch + 8,
                height: AppSize.swatch + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ink : colors.divider,
                    width: AppStroke.focus,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: selected ? AppSize.swatch - 2 : 0,
                    height: selected ? AppSize.swatch - 2 : 0,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: selected ? colors.text : colors.textMuted,
                  ),
                ),
              ),
              Text(
                hours,
                style: AppTextStyles.statSm.copyWith(
                  color: selected ? colors.text : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.moon, size: AppIconSize.lg, color: colors.textMuted),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
