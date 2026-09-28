/// The presentational half of [AuditLogScreen].
///
/// Split out for the same reason every other screen is: a body that takes its
/// entries and its idea of "today" as plain arguments can be rendered to a
/// golden without a database behind it. This screen was rebuilt in the
/// redesign and then never once looked at in a render, which is exactly the
/// gap the split closes.
library;

import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../domain/date_only.dart';
import '../../widgets/screen_scaffold.dart';

class AuditLogBody extends StatelessWidget {
  const AuditLogBody({super.key, required this.entries, required this.now});

  /// Newest first; grouped into days here rather than by the caller, since
  /// the grouping is a presentation choice. `null` means the read has not
  /// finished — the chrome still draws, so the back button exists while the
  /// log is loading and "No activity yet" never flashes on the way in.
  final List<AuditLogEntry>? entries;

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = this.entries;

    return SubScreen(
      title: 'Audit log',
      subtitle: 'Every stored change, newest first. Read only.',
      child: switch (entries) {
        null => const SizedBox.shrink(),
        [] => Center(
            child: Text('No activity yet',
                style: AppTextStyles.body.copyWith(color: colors.textMuted)),
          ),
        _ => _grouped(context, entries),
      },
    );
  }

  Widget _grouped(BuildContext context, List<AuditLogEntry> entries) {
    final byDay = <DateTime, List<AuditLogEntry>>{};
    for (final entry in entries) {
      byDay.putIfAbsent(dateOnly(entry.timestamp), () => []).add(entry);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = dateOnly(now);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutterDense,
        0,
        AppSpace.gutterDense,
        AppSpace.s6 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        for (final (i, day) in days.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.s6),
          _DayGroup(day: day, isToday: day == today, entries: byDay[day]!),
        ],
      ],
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.isToday, required this.entries});

  final DateTime day;
  final bool isToday;
  final List<AuditLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpace.s1),
          child: Text(
            '${isToday ? 'TODAY · ' : ''}${AppFormat.dayRow(day).toUpperCase()}',
            style: AppTextStyles.kicker.copyWith(color: colors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.divider, width: AppStroke.hair),
            boxShadow: colors.shadowSm,
          ),
          child: Column(
            children: [
              for (final (i, entry) in entries.indexed) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
                    child: Container(height: AppStroke.hair, color: colors.divider),
                  ),
                _EntryRow(entry: entry),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final id = entry.entityId;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.action} · ${entry.entityType}',
                    style: AppTextStyles.bodyStrong.copyWith(color: colors.text)),
                if (id != null) ...[
                  const SizedBox(height: 2),
                  // The first eight characters are enough to match a row
                  // against the export, and a full UUID is unreadable.
                  Text('id ${id.length > 8 ? id.substring(0, 8) : id}',
                      style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                ],
              ],
            ),
          ),
          Text(AppFormat.time(entry.timestamp),
              style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}
