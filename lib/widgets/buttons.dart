/// The four buttons Golden Hour has (handoff §5.12).
///
/// Material's [ElevatedButton] family is not used: its shape, splash, elevation
/// and disabled colours all have to be overridden to reach this design, and
/// what is left underneath is a container with a tap target. These are that
/// container, with the token values spelled out once.
library;

import 'package:flutter/widgets.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import 'press_scale.dart';

/// The apricot pill: check in, save, continue. One per screen at most.
class PrimaryPill extends StatelessWidget {
  const PrimaryPill({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.height = AppSize.pillButton,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Full width by default; intrinsic when it shares a row with another pill.
  final bool expand;

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final foreground = enabled ? colors.onAccent : colors.textMuted;

    return PressScale(
      onTap: onPressed,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: expand ? 0 : AppSpace.s6),
          decoration: BoxDecoration(
            color: enabled ? colors.accentFill : colors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A disabled button drops its icon: the glyph is what makes the
              // action look available.
              if (icon != null && enabled) ...[
                Icon(icon, size: AppIconSize.lg, color: foreground),
                const SizedBox(width: AppSpace.s2),
              ],
              Text(label, style: AppTextStyles.label.copyWith(color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The outlined pill: cancel, and anything that sits beside a primary.
class SecondaryPill extends StatelessWidget {
  const SecondaryPill({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.height = AppSize.pillButton,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;

    return PressScale(
      onTap: onPressed,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: expand ? 0 : AppSpace.s6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: enabled ? colors.textMuted : colors.divider,
              width: AppStroke.dash,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: enabled ? colors.text : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A label with a tap target and no container: Back, Cancel in a dialog.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.emphasis = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// `text` instead of `textMuted`, for the one text button on screen that is
  /// a real choice rather than an escape hatch.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PressScale(
      onTap: onPressed,
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          height: AppSize.touch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: emphasis ? colors.text : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A glyph in a 44 dp target, optionally on a `surface2` disc.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = AppIconSize.xl,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  /// The History date-picker entry, and nothing else so far.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;

    return PressScale(
      onTap: onPressed,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        child: Container(
          width: AppSize.touch,
          height: AppSize.touch,
          alignment: Alignment.center,
          decoration: filled
              ? BoxDecoration(color: colors.surface2, shape: BoxShape.circle)
              : null,
          child: Icon(
            icon,
            size: size,
            color: enabled ? (color ?? colors.text) : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
