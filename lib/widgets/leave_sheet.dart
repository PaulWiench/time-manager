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
///
/// Carries a [fraction] rather than resolved hours. It used to hand back
/// `targetHours * fraction`, which is only meaningful for one date — across a
/// range those hours have to be worked out per day, because a half-day public
/// holiday in the middle is worth half as much as its neighbours.
class LeaveEdit {
  const LeaveEdit.set({
    required LeaveType this.type,
    required LeaveFraction this.fraction,
    this.name,
  }) : cleared = false;

  const LeaveEdit.cleared()
      : type = null,
        fraction = null,
        name = null,
        cleared = true;

  final LeaveType? type;
  final LeaveFraction? fraction;

  /// The vacation's name, as typed; vacation only, empty means unnamed.
  final String? name;

  /// Remove whatever leave those days already had, and add nothing.
  final bool cleared;

  /// What this edit is worth on a date whose own target is [targetHours].
  double hoursFor(double targetHours) => targetHours * fraction!.value;
}

/// [dates] must be sorted and non-empty. One date is the ordinary
/// long-press-a-day case; more is a booked range.
Future<LeaveEdit?> showLeaveSheet({
  required BuildContext context,
  required List<DateTime> dates,
  required double Function(DateTime) targetFor,
  List<LeaveEntry> existing = const [],
}) {
  final targets = [for (final date in dates) targetFor(date)];
  // The labels need one number to quote. Every day in a normal range carries
  // the same target; a range containing a half-day holiday does not, and says
  // so rather than quoting a figure that is wrong for one of its days.
  final headline = targets.first;
  final mixed = targets.any((t) => (t - headline).abs() > 1 / 60);

  final first = existing.isEmpty ? null : existing.first;
  var type = first?.type ?? LeaveType.vacation;
  var fraction = first == null
      ? LeaveFraction.full
      : LeaveFraction.nearest(first.hours, headline);

  final bookable = targets.any((t) => t > 0);

  return showAppSheet<LeaveEdit>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => LeaveSheetView(
        subtitle: _subtitleFor(dates),
        targetHours: headline,
        mixedTargets: mixed,
        type: type,
        fraction: fraction,
        hasExisting: existing.isNotEmpty,
        onType: (value) => setState(() => type = value),
        onFraction: (value) => setState(() => fraction = value),
        onClear: () => Navigator.of(context).pop(const LeaveEdit.cleared()),
        onSave: !bookable
            ? null
            : () => Navigator.of(context)
                .pop(LeaveEdit.set(type: type, fraction: fraction)),
      ),
    ),
  );
}

String _subtitleFor(List<DateTime> dates) {
  if (dates.length == 1) return AppFormat.dayRow(dates.first);
  return '${AppFormat.dayRow(dates.first)} – ${AppFormat.dayRow(dates.last)}'
      ' · ${dates.length} days';
}

/// The presentational half, so the sheet can be rendered to a golden without a
/// database or a navigator — the same split every other screen got in Phase 3.
class LeaveSheetView extends StatelessWidget {
  const LeaveSheetView({
    super.key,
    required this.subtitle,
    required this.targetHours,
    required this.type,
    required this.fraction,
    required this.hasExisting,
    this.mixedTargets = false,
    this.onType,
    this.onFraction,
    this.onClear,
    this.onSave,
  });

  /// `Mon 28 Sep`, or `Mon 12 Oct – Fri 23 Oct · 9 days`.
  final String subtitle;

  /// The target the hour labels quote. Zero on a weekend or a whole public
  /// holiday, which is the one case where leave cannot be recorded at all.
  final double targetHours;

  /// Set when the days in this booking do not all carry the same target, so
  /// the quoted hours are right for most of them and not for all.
  final bool mixedTargets;

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
      subtitle: subtitle,
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
            text: 'Nothing is scheduled on $subtitle, '
                'so there are no hours to take off.',
          )
        else ...[
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
          if (mixedTargets)
            _Notice(
              text: 'Some of these days are shorter than the rest. '
                  'Each one takes off its own hours.',
            ),
        ],
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
