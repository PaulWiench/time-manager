import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum ChipRole { work, realBreak, syntheticBreak, leave }

/// The filled rounded chip used on Home's timeline and History's expanded
/// day rows to represent a work/break/leave block. Three of the four roles
/// come straight from the handoff (work = accent tint, real break = teal
/// tint, synthetic break = dashed outline with a delete affordance); leave
/// has no color spec in the handoff (only mentioned as needing to be
/// "tellable apart" from the other two) — since the design's semantic
/// palette deliberately caps at accent/break/warning (no fourth hue),
/// leave is given a neutral bordered treatment with a calendar glyph
/// instead of inventing an unspecified color.
class TimelineChip extends StatelessWidget {
  final ChipRole role;
  final String label;
  final VoidCallback? onDelete;

  const TimelineChip({super.key, required this.role, required this.label, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    switch (role) {
      case ChipRole.work:
        return _filled(background: colors.accentTint, textColor: colors.accentText);
      case ChipRole.realBreak:
        return _filled(background: colors.breakTint, textColor: colors.breakText);
      case ChipRole.leave:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surface2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(PhosphorIconsRegular.calendarCheck, size: 12, color: colors.text),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.metaMedium.copyWith(color: colors.text, fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        );
      case ChipRole.syntheticBreak:
        return CustomPaint(
          painter: _DashedRRectPainter(color: colors.divider, radius: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.metaMedium.copyWith(color: colors.textMuted, fontWeight: FontWeight.w500, fontSize: 12)),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: PhosphorIcon(PhosphorIconsRegular.x, size: 12, color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  Widget _filled({required Color background, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: AppTextStyles.metaMedium.copyWith(color: textColor, fontWeight: FontWeight.w500, fontSize: 12)),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 3.5;
    const dashGap = 2.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
