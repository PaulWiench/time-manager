import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';

/// Nocturne's buttons are never filled (design handoff, Onboarding §4) —
/// this is the one primary-action button style used everywhere (onboarding
/// "Continue", empty-state "Check In").
class OutlinedPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OutlinedPrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.accentFill),
          foregroundColor: colors.accentText,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
        child: Text(label, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: colors.accentText)),
      ),
    );
  }
}
