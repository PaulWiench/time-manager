/// Settings → Jobs (additions handoff §3.5): every job, active then ended,
/// each opening its edit screen; Add opens a new one.
library;

import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../providers/job_providers.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/screen_scaffold.dart';
import 'edit_job_screen.dart';
import 'job_pill.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider).valueOrNull ?? const <Job>[];
    final summaries = [for (final job in jobs) ref.watch(jobSummaryProvider(job.id))]
        .whereType<JobSummary>()
        .toList();

    void open(int? id) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => EditJobScreen(jobId: id)),
        );

    return JobsBody(summaries: summaries, onOpen: open, onAdd: () => open(null));
  }
}

class JobsBody extends StatelessWidget {
  const JobsBody({super.key, required this.summaries, this.onOpen, this.onAdd});

  final List<JobSummary> summaries;
  final ValueChanged<int>? onOpen;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = summaries.where((s) => !s.ended).toList();
    final ended = summaries.where((s) => s.ended).toList();

    Widget group(String title, List<JobSummary> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.s1),
              child: Text(title, style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
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
                  for (final (i, s) in items.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 64, right: AppSpace.s4),
                        child: Container(height: AppStroke.hair, color: colors.divider),
                      ),
                    JobRow(
                      summary: s,
                      chevron: true,
                      onTap: onOpen == null ? null : () => onOpen!(s.job.id),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

    return SubScreen(
      title: 'Jobs',
      subtitle: [
        '${active.length} active',
        if (ended.isNotEmpty) '${ended.length} ended',
      ].join(' · '),
      action: AddPill(label: 'Add', semanticLabel: 'Add job', onTap: onAdd),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.gutterDense,
          0,
          AppSpace.gutterDense,
          AppSpace.s8 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          if (active.isNotEmpty) group('ACTIVE', active),
          if (ended.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s6),
            group('ENDED', ended),
          ],
          const SizedBox(height: AppSpace.s4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
            child: Text(
              'Jobs can overlap. Each keeps its own schedule, balance and vacation quota. '
              'Breaks and holidays apply to all jobs.',
              style: AppTextStyles.caption.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dark "+ Add" pill on a sub-screen's back row.
class AddPill extends StatelessWidget {
  const AddPill({super.key, required this.label, required this.semanticLabel, this.onTap});

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PressScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Container(
          height: AppSize.touch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
          decoration: BoxDecoration(
            color: colors.selected,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.plus, size: AppIconSize.md, color: colors.onSelected),
              const SizedBox(width: AppSpace.s2),
              Text(label, style: AppTextStyles.label.copyWith(color: colors.onSelected)),
            ],
          ),
        ),
      ),
    );
  }
}
