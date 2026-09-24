/// A number between two round buttons (handoff §4.1 step 1).
///
/// Onboarding sets weekly hours and a starting balance with it, and every
/// numeric editor in Settings reuses it, so the same value is adjusted the same
/// way wherever it is met. Typing is deliberately not offered: every number
/// here moves in fixed steps, and a keyboard would invite `39,5` and `39.50`
/// and a validation message nobody wants to read.
library;

import 'package:flutter/widgets.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'press_scale.dart';

class StepperField extends StatelessWidget {
  const StepperField({
    super.key,
    required this.label,
    this.unit,
    required this.onDecrease,
    required this.onIncrease,
    this.muted = false,
  });

  /// The formatted value — `40`, `0:00`, `Not set`.
  final String label;

  final String? unit;

  /// Null disables that side, e.g. at a clamp.
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  /// For a value that is not configured, so "Not set" does not read as a
  /// number someone chose.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(
          icon: AppIcons.minus,
          semanticLabel: 'Decrease',
          onPressed: onDecrease,
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label,
                style: AppTextStyles.stat
                    .copyWith(color: muted ? colors.textMuted : colors.text),
              ),
              if (unit != null) ...[
                const SizedBox(width: AppSpace.s1),
                Text(unit!,
                    style: AppTextStyles.statSm.copyWith(color: colors.textMuted)),
              ],
            ],
          ),
        ),
        _RoundButton(
          icon: AppIcons.plus,
          semanticLabel: 'Increase',
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PressScale(
      onTap: onPressed,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: semanticLabel,
        child: Container(
          width: AppSpace.s14,
          height: AppSpace.s14,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.surface2, shape: BoxShape.circle),
          child: Icon(
            icon,
            size: AppIconSize.xl,
            color: onPressed == null ? colors.textMuted : colors.text,
          ),
        ),
      ),
    );
  }
}

/// A row of day toggles (handoff §4.1 step 2), shared by onboarding and the
/// Work days editor.
class WeekdayToggles extends StatelessWidget {
  const WeekdayToggles({super.key, required this.selected, required this.onToggle});

  /// ISO weekday numbers, 1 = Monday.
  final Set<int> selected;

  final ValueChanged<int> onToggle;

  static const _labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var day = 1; day <= 7; day++)
          PressScale(
            onTap: () => onToggle(day),
            child: Semantics(
              button: true,
              selected: selected.contains(day),
              child: Container(
                width: 40,
                height: AppSize.touch,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(day) ? colors.accentFill : colors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _labels[day - 1],
                  style: AppTextStyles.label.copyWith(
                    color: selected.contains(day) ? colors.onAccent : colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
