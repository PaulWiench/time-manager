import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';

/// The small "Remaining today" / "Balance" cards on Home, and the
/// full-width chart-card shell used throughout Stats.
class StatCard extends StatelessWidget {
  final String label;
  final Widget value;

  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.metaMedium.copyWith(color: colors.textMuted, letterSpacing: 0.6),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String kicker;
  final Widget child;

  const ChartCard({super.key, required this.kicker, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker.toUpperCase(), style: AppTextStyles.metaMedium.copyWith(color: colors.textMuted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
