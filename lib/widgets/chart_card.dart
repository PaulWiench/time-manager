/// The card every Stats chart sits in (handoff §5.6).
///
/// The header is the point: a kicker naming the measure, one large number, and
/// a sentence saying what the number means. A chart you have to read to learn
/// anything is a chart you skip; here the answer is already in words and the
/// plot is the evidence.
library;

import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'banded_number.dart';

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.kicker,
    this.value,
    this.unit,
    this.caption,
    this.trailing,
    this.warning = false,
    this.child,
    this.emptyMessage = 'Not enough data yet',
    this.emptyHint = 'Log a few more days in this range',
  });

  final String kicker;

  /// Null means there is not enough data in this range: the kicker stays, the
  /// number and caption go, and the body becomes the empty block. Decided per
  /// chart, so one thin range does not blank the whole screen.
  final String? value;

  final String? unit;
  final String? caption;

  /// A control that belongs to this chart alone, e.g. the heatmap's month
  /// stepper.
  final Widget? trailing;

  final bool warning;
  final Widget? child;
  final String emptyMessage;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // No body means there is not enough data in this range. A body with no
    // headline number is fine: the Leave breakdown says everything inside its
    // own ring.
    final empty = child == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider, width: AppStroke.hair),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kicker, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
                    if (!empty && value != null) ...[
                      const SizedBox(height: AppSpace.s1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          BandedNumber(
                            text: value!,
                            style: AppTextStyles.stat,
                            warning: warning,
                            plainColor: colors.text,
                            warningColor: colors.warningText,
                            bandColor: colors.warningTint,
                          ),
                          if (unit != null) ...[
                            const SizedBox(width: AppSpace.s1),
                            Text(unit!,
                                style: AppTextStyles.statSm.copyWith(color: colors.textMuted)),
                          ],
                        ],
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: AppSpace.s1),
                        Text(caption!,
                            style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                      ],
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          if (empty)
            ChartEmptyBlock(message: emptyMessage, hint: emptyHint)
          else
            child!,
        ],
      ),
    );
  }
}

class ChartEmptyBlock extends StatelessWidget {
  const ChartEmptyBlock({super.key, required this.message, required this.hint});

  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      height: 136,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.chartLineUp, size: AppIconSize.xl, color: colors.textMuted),
          const SizedBox(height: AppSpace.s2),
          Text(message, style: AppTextStyles.bodyLg.copyWith(color: colors.text)),
          Text(hint, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}

/// A single number on its own card: Stats' "Sick days", and the Leave tab's
/// remaining-days figure.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.kicker,
    required this.value,
    this.unit,
    this.caption,
    this.warning = false,
    this.tone,
  });

  final String kicker;
  final String value;
  final String? unit;
  final String? caption;
  final bool warning;

  /// A leave hue when the number is about leave rather than about work.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider, width: AppStroke.hair),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(kicker, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpace.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              BandedNumber(
                text: value,
                style: AppTextStyles.stat,
                warning: warning,
                plainColor: tone ?? colors.text,
                warningColor: colors.warningText,
                bandColor: colors.warningTint,
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpace.s1),
                Text(unit!, style: AppTextStyles.statSm.copyWith(color: colors.textMuted)),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpace.s1),
            Text(caption!, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
          ],
        ],
      ),
    );
  }
}
