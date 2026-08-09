import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shared "not enough data yet" placeholder every chart in Stats falls back
/// to independently, per the design spec § 5.4, rather than rendering a
/// sparse or misleading chart.
class ChartEmptyState extends StatelessWidget {
  final double height;

  const ChartEmptyState({super.key, this.height = 70});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: height,
      child: Center(
        child: Text('Not enough data yet', style: AppTextStyles.meta.copyWith(color: colors.textMuted)),
      ),
    );
  }
}

class ChartLoading extends StatelessWidget {
  final double height;

  const ChartLoading({super.key, this.height = 70});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
  }
}
