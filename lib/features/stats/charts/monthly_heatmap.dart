import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/database/database.dart';
import '../../../providers/day_providers.dart';
import 'chart_empty_state.dart';

/// Patterns § 1 — GitHub-style heatmap, calendar-month grid (Mon..Sun
/// columns, one row per week) rather than a continuous rolling window.
/// Deliberately scoped to a single calendar month with its own prev/next
/// selector — independent of Stats' global range chip — since a flattened
/// 6-month/year window doesn't lay out as a legible calendar grid. Matches
/// the precedent set by Leave's own year selector, which also ignores the
/// global range.
class MonthlyHeatmap extends ConsumerStatefulWidget {
  const MonthlyHeatmap({super.key});

  @override
  ConsumerState<MonthlyHeatmap> createState() => _MonthlyHeatmapState();
}

class _MonthlyHeatmapState extends ConsumerState<MonthlyHeatmap> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static final _monthFmt = DateFormat('MMMM yyyy');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final monthEndExclusive = DateTime(_month.year, _month.month + 1);
    final entriesAsync = ref.watch(dayEntriesInRangeProvider(_month, monthEndExclusive));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              child: PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 14, color: colors.textMuted),
            ),
            const SizedBox(width: 8),
            Text(_monthFmt.format(_month), style: AppTextStyles.body.copyWith(color: colors.text)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              child: PhosphorIcon(PhosphorIconsRegular.caretRight, size: 14, color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        entriesAsync.when(
          data: (entries) {
            if (entries.every((e) => e.netWorkedHours <= 0)) return const ChartEmptyState(height: 130);
            final byDate = {for (final e in entries) e.date: e};
            return SizedBox(
              height: 130,
              width: double.infinity,
              child: CustomPaint(
                painter: _HeatmapPainter(
                  month: _month,
                  byDate: byDate,
                  fillColor: colors.accentFill,
                  idleColor: colors.idle.withValues(alpha: 0.25),
                  labelColor: colors.textMuted,
                ),
              ),
            );
          },
          loading: () => const ChartLoading(height: 130),
          error: (_, __) => const ChartEmptyState(height: 130),
        ),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final DateTime month;
  final Map<DateTime, DayEntry> byDate;
  final Color fillColor;
  final Color idleColor;
  final Color labelColor;

  _HeatmapPainter({
    required this.month,
    required this.byDate,
    required this.fillColor,
    required this.idleColor,
    required this.labelColor,
  });

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 7;
    const labelSpace = 14.0;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final rows = ((firstWeekday - 1 + daysInMonth) / cols).ceil();

    final cellW = size.width / cols;
    final cellH = (size.height - labelSpace) / rows;
    const gap = 2.0;
    final now = DateTime.now();

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final index = firstWeekday - 1 + day - 1;
      final row = index ~/ cols;
      final col = index % cols;
      final rect = Rect.fromLTWH(col * cellW + gap / 2, row * cellH + gap / 2, cellW - gap, cellH - gap);

      final entry = byDate[date];
      final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
      Color color;
      if (isFuture) {
        color = Colors.transparent;
      } else if (entry == null || entry.netWorkedHours <= 0) {
        color = idleColor;
      } else {
        final ratio = entry.targetHours > 0 ? (entry.netWorkedHours / entry.targetHours).clamp(0.0, 1.0) : 1.0;
        color = fillColor.withValues(alpha: 0.2 + ratio * 0.8);
      }

      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = color);
    }

    for (var c = 0; c < cols; c++) {
      final tp = TextPainter(
        text: TextSpan(text: _weekdayLabels[c], style: TextStyle(fontSize: 9, color: labelColor)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c * cellW + cellW / 2 - tp.width / 2, size.height - labelSpace + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.month != month || oldDelegate.byDate != byDate;
  }
}
