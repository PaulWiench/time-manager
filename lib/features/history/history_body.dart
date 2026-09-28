/// History, drawn from rows and nothing else.
library;

import 'package:flutter/widgets.dart';

import '../../core/icons/app_icons.dart';
import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/buttons.dart';
import '../../widgets/day_row.dart';
import '../../widgets/event_timeline.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/segmented_control.dart';
import 'history_view.dart';

class HistoryBody extends StatelessWidget {
  const HistoryBody({
    super.key,
    required this.mode,
    required this.stepperLabel,
    required this.rows,
    this.expandedDay,
    this.onModeChanged,
    this.onStep,
    this.onOpenDatePicker,
    this.onTapRow,
  });

  final HistoryMode mode;

  /// `2026`, `September 2026`, or `21–27 Sep 2026`, depending on the mode.
  final String stepperLabel;

  final List<HistoryRow> rows;
  final DateTime? expandedDay;

  final ValueChanged<HistoryMode>? onModeChanged;

  /// −1 or +1 unit of the active mode.
  final ValueChanged<int>? onStep;

  final VoidCallback? onOpenDatePicker;
  final ValueChanged<HistoryRow>? onTapRow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = AppMotion.of(context);

    return TabScreen(
      title: 'History',
      gutter: AppSpace.gutterDense,
      action: AppIconButton(
        icon: AppIcons.calendarDots,
        semanticLabel: 'Jump to date',
        filled: true,
        onPressed: onOpenDatePicker,
      ),
      children: [
        const SizedBox(height: AppSpace.s3),
        Row(
          children: [
            AppIconButton(
              icon: AppIcons.caretLeft,
              semanticLabel: 'Previous',
              onPressed: onStep == null ? null : () => onStep!(-1),
            ),
            Expanded(
              child: Text(
                stepperLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline.copyWith(color: colors.text),
              ),
            ),
            AppIconButton(
              icon: AppIcons.caretRight,
              semanticLabel: 'Next',
              onPressed: onStep == null ? null : () => onStep!(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s3),
        SegmentedControl<HistoryMode>(
          segments: const [
            (HistoryMode.month, 'Month'),
            (HistoryMode.week, 'Week'),
            (HistoryMode.day, 'Day'),
          ],
          selected: mode,
          onSelect: onModeChanged ?? (_) {},
        ),
        const SizedBox(height: AppSpace.s4),
        // A hand-rolled shared-axis Z rather than a page transition: drilling
        // from a month to its weeks is a zoom, and the list should arrive from
        // where the tapped row was, not slide in from the side.
        AnimatedSwitcher(
          duration: motion.drillDown,
          switchInCurve: AppCurves.emphasized,
          switchOutCurve: AppCurves.emphasized,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(mode),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpace.s3),
                _Row(row: row, expanded: row.date == expandedDay, onTap: onTapRow),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.expanded, required this.onTap});

  final HistoryRow row;
  final bool expanded;
  final ValueChanged<HistoryRow>? onTap;

  @override
  Widget build(BuildContext context) {
    final expansion = expanded ? row.expansion : null;

    return DayRow(
      status: row.status,
      blockTop: row.blockTop,
      blockBottom: row.blockBottom,
      line1: row.line1,
      line2: row.line2,
      delta: row.delta,
      deltaWarning: row.deltaWarning,
      trailingIcon: row.trailingIcon,
      chevron: row.chevron,
      expanded: expanded && expansion != null,
      expansion: expansion == null ? null : _Expansion(expansion: expansion),
      onTap: onTap == null || !(row.chevron || row.expandable) ? null : () => onTap!(row),
    );
  }
}

class _Expansion extends StatelessWidget {
  const _Expansion({required this.expansion});

  final HistoryExpansion expansion;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notes = [
      if (expansion.dayNote != null) expansion.dayNote!,
      ...expansion.sessionNotes,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventTimeline(items: expansion.timeline, ground: colors.surface, stagger: true),
        if (expansion.consequence != null) ...[
          const SizedBox(height: AppSpace.s2),
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.s8),
            child: Text(expansion.consequence!,
                style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
          ),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.s3),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expansion.dayNote != null)
                  _NoteLine(
                    icon: AppIcons.note,
                    text: expansion.dayNote!,
                    style: AppTextStyles.body.copyWith(color: colors.text),
                  ),
                for (final note in expansion.sessionNotes) ...[
                  if (expansion.dayNote != null || note != expansion.sessionNotes.first)
                    const SizedBox(height: AppSpace.s2),
                  _NoteLine(
                    icon: AppIcons.pencilSimple,
                    text: note,
                    style: AppTextStyles.caption.copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppIconSize.sm, color: colors.textMuted),
        const SizedBox(width: AppSpace.s2),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
