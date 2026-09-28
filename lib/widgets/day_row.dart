/// One row of History, at every zoom level (handoff §5.7).
///
/// A month, a week and a day are all "a block of time with a date stamp, what
/// happened in it, and what it did to the balance", so they are one component.
/// Drilling from year to week to day then feels like zooming rather than like
/// visiting three different screens.
///
/// The three empty statuses are containers, not sentences: a missed workday is
/// dashed (it should have happened and did not), a rest day is flat (nothing was
/// ever expected), a future day is outlined (it is still coming).
library;

import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/motion.dart';
import '../core/painting/dashed_border.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'banded_number.dart';
import 'press_scale.dart';

enum DayRowStatus {
  /// A day that was worked.
  normal,

  /// Today, whatever else it is.
  today,

  /// A scheduled workday with nothing logged.
  missed,

  /// Not a workday.
  rest,

  /// A scheduled workday that has not happened yet.
  future,

  publicHoliday,
  vacation,
  sick,
  flex,
}

class DayRow extends StatelessWidget {
  const DayRow({
    super.key,
    required this.status,
    required this.blockTop,
    required this.blockBottom,
    required this.line1,
    this.line2,
    this.delta,
    this.deltaWarning = false,
    this.trailingIcon,
    this.chevron = false,
    this.onTap,
    this.onLongPress,
    this.expanded = false,
    this.expansion,
  });

  final DayRowStatus status;

  /// The date block's two lines: `MON`/`21`, `2026`/`Aug`, `WK`/`39`.
  final String blockTop;
  final String blockBottom;

  final String line1;
  final String? line2;

  /// The balance delta, or an em dash on a rest day.
  final String? delta;

  /// Set when this day's closing balance is past a configured bound.
  final bool deltaWarning;

  final IconData? trailingIcon;
  final bool chevron;
  final VoidCallback? onTap;

  /// Day rows only: opens the leave editor for that date. Summary rows (a month
  /// or a week) stand for a range, so there is nothing to mark.
  final VoidCallback? onLongPress;

  final bool expanded;

  /// Timeline and notes, revealed when the row is expanded.
  final Widget? expansion;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);
    final style = _RowStyle.of(status, colors);

    final header = Row(
      children: [
        _DateBlock(top: blockTop, bottom: blockBottom, style: style),
        const SizedBox(width: AppSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(line1, style: AppTextStyles.bodyLg.copyWith(color: style.line1)),
              if (line2 != null) ...[
                const SizedBox(height: 2),
                Text(line2!, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
              ],
            ],
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpace.s2),
          Icon(trailingIcon, size: AppIconSize.lg, color: style.line1),
        ],
        if (delta != null) ...[
          const SizedBox(width: AppSpace.s2),
          BandedNumber(
            text: delta!,
            style: AppTextStyles.statSm,
            warning: deltaWarning,
            plainColor: style.delta,
            warningColor: colors.warningText,
            bandColor: colors.warningTint,
          ),
        ],
        if (chevron) ...[
          const SizedBox(width: AppSpace.s2),
          Icon(AppIcons.caretRight, size: AppIconSize.md, color: colors.textMuted),
        ],
      ],
    );

    final body = AnimatedSize(
      duration: expanded ? motion.rowExpand : motion.rowCollapse,
      curve: expanded ? AppCurves.expand : AppCurves.collapse,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (expanded && expansion != null) ...[
            const SizedBox(height: AppSpace.s3),
            Container(height: AppStroke.hair, color: colors.divider),
            const SizedBox(height: AppSpace.s2),
            expansion!,
          ],
        ],
      ),
    );

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.fromLTRB(AppSpace.s3, AppSpace.s2, AppSpace.s4, AppSpace.s2),
        decoration: ShapeDecoration(
          color: style.background,
          shadows: style.shadow ? colors.shadowSm : const [],
          shape: style.shape(colors),
        ),
        child: Center(child: body),
      ),
    );
  }
}

/// The container, date block and ink for one status.
class _RowStyle {
  const _RowStyle({
    required this.background,
    required this.blockFill,
    required this.blockInk,
    required this.line1,
    required this.delta,
    required this.outline,
    required this.dashed,
    required this.outlineWidth,
    required this.shadow,
  });

  final Color? background;
  final Color? blockFill;
  final Color blockInk;
  final Color line1;
  final Color delta;
  final Color? outline;
  final bool dashed;
  final double outlineWidth;
  final bool shadow;

  ShapeBorder shape(AppColors colors) {
    if (dashed) {
      return DashedRoundedBorder(color: outline!, radius: AppRadius.md);
    }
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: outline == null
          ? BorderSide.none
          : BorderSide(color: outline!, width: outlineWidth),
    );
  }

  static _RowStyle of(DayRowStatus status, AppColors c) => switch (status) {
        DayRowStatus.normal => _RowStyle(
            background: c.surface,
            blockFill: c.surface2,
            blockInk: c.text,
            line1: c.text,
            delta: c.text,
            outline: c.divider,
            dashed: false,
            outlineWidth: AppStroke.hair,
            shadow: true,
          ),
        // Today is the only row that gets the accent outline, at every zoom
        // level, so "where am I" is answered before anything is read.
        DayRowStatus.today => _RowStyle(
            background: c.surface,
            blockFill: c.accentFill,
            blockInk: c.onAccent,
            line1: c.text,
            delta: c.text,
            outline: c.accentFill,
            dashed: false,
            outlineWidth: AppStroke.focus,
            shadow: false,
          ),
        DayRowStatus.missed => _RowStyle(
            background: null,
            blockFill: c.surface2,
            blockInk: c.text,
            line1: c.text,
            delta: c.text,
            outline: c.textMuted,
            dashed: true,
            outlineWidth: AppStroke.dash,
            shadow: false,
          ),
        DayRowStatus.rest => _RowStyle(
            background: null,
            blockFill: null,
            blockInk: c.textMuted,
            line1: c.textMuted,
            delta: c.textMuted,
            outline: null,
            dashed: false,
            outlineWidth: 0,
            shadow: false,
          ),
        DayRowStatus.future => _RowStyle(
            background: null,
            blockFill: c.surface2,
            blockInk: c.textMuted,
            line1: c.textMuted,
            delta: c.textMuted,
            outline: c.divider,
            dashed: false,
            outlineWidth: AppStroke.hair,
            shadow: false,
          ),
        DayRowStatus.publicHoliday => _RowStyle(
            background: c.holidayTint,
            blockFill: c.holidayFill,
            blockInk: c.onAccent,
            line1: c.holidayText,
            delta: c.holidayText,
            outline: null,
            dashed: false,
            outlineWidth: 0,
            shadow: false,
          ),
        DayRowStatus.vacation => _RowStyle(
            background: c.vacationTint,
            blockFill: c.vacationFill,
            blockInk: c.onAccent,
            line1: c.vacationText,
            delta: c.vacationText,
            outline: null,
            dashed: false,
            outlineWidth: 0,
            shadow: false,
          ),
        DayRowStatus.sick => _RowStyle(
            background: c.sickTint,
            blockFill: c.sickFill,
            blockInk: c.onAccent,
            line1: c.sickText,
            delta: c.sickText,
            outline: null,
            dashed: false,
            outlineWidth: 0,
            shadow: false,
          ),
        DayRowStatus.flex => _RowStyle(
            background: c.accentTint,
            blockFill: c.accentFill,
            blockInk: c.onAccent,
            line1: c.accentText,
            delta: c.accentText,
            outline: null,
            dashed: false,
            outlineWidth: 0,
            shadow: false,
          ),
      };
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.top, required this.bottom, required this.style});

  final String top;
  final String bottom;
  final _RowStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSize.dateBlock,
      height: AppSize.dateBlock,
      decoration: BoxDecoration(
        color: style.blockFill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(top, style: AppTextStyles.microStrong.copyWith(color: style.blockInk)),
          Text(bottom, style: AppTextStyles.statSm.copyWith(color: style.blockInk)),
        ],
      ),
    );
  }
}
