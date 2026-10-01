/// The job switcher (additions handoff §3.1, §3.2): a pill under the title on
/// Home, History and Stats, shown once there is more than one job, and the
/// sheet it opens. The selection is one app-wide choice.
library;

import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/database/database.dart';
import '../../providers/job_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/buttons.dart';
import '../../widgets/press_scale.dart';
import '../settings/settings_view.dart' show workDaysLabel;
import 'jobs_screen.dart';

/// The pill, wired: nothing at all with a single job.
class JobPill extends ConsumerWidget {
  const JobPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasSeveralJobsProvider)) return const SizedBox.shrink();
    final job = ref.watch(selectedJobProvider);
    if (job == null) return const SizedBox.shrink();
    return JobPillView(
      name: job.name,
      ended: job.endDate != null,
      onTap: () => showJobSwitcher(context),
    );
  }
}

class JobPillView extends StatelessWidget {
  const JobPillView({super.key, required this.name, required this.ended, this.onTap});

  final String name;
  final bool ended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Job: $name${ended ? ', ended' : ''}. Switch job',
        excludeSemantics: true,
        child: PressScale(
          onTap: onTap,
          child: SizedBox(
            height: AppSize.touch,
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.briefcase, size: AppIconSize.sm, color: colors.text),
                    const SizedBox(width: AppSpace.s2),
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(color: colors.text)),
                    ),
                    if (ended) ...[
                      const SizedBox(width: AppSpace.s1),
                      Text('· ENDED',
                          style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
                    ],
                    const SizedBox(width: AppSpace.s2),
                    Icon(AppIcons.caretDown, size: AppIconSize.sm, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showJobSwitcher(BuildContext context) {
  return showAppSheet<void>(context: context, builder: (_) => const _JobSwitcher());
}

class _JobSwitcher extends ConsumerWidget {
  const _JobSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider).valueOrNull ?? const <Job>[];
    final selected = ref.watch(selectedJobIdProvider);
    final summaries = [
      for (final job in jobs) ref.watch(jobSummaryProvider(job.id)),
    ].whereType<JobSummary>().toList();

    return JobSwitcherView(
      summaries: summaries,
      selectedId: selected,
      onSelect: (id) {
        ref.read(jobRepositoryProvider).select(id);
        Navigator.of(context).pop();
      },
      onManage: () {
        Navigator.of(context).pop();
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const JobsScreen()));
      },
    );
  }
}

class JobSwitcherView extends StatelessWidget {
  const JobSwitcherView({
    super.key,
    required this.summaries,
    required this.selectedId,
    required this.onSelect,
    this.onManage,
  });

  final List<JobSummary> summaries;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppSheet(
      title: 'Switch job',
      subtitle: 'Home, History and Stats follow this choice',
      actions: [
        if (onManage != null) SecondaryPill(label: 'Manage jobs', onPressed: onManage),
      ],
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.divider, width: AppStroke.hair),
          ),
          child: Column(
            children: [
              for (final (i, s) in summaries.indexed) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 64, right: AppSpace.s4),
                    child: Container(height: AppStroke.hair, color: colors.divider),
                  ),
                JobRow(
                  summary: s,
                  selected: s.job.id == selectedId,
                  onTap: () => onSelect(s.job.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One job: tile, name and what it is, balance. Shared by the switcher and
/// the jobs list (which adds a chevron and drops the selected tile).
class JobRow extends StatelessWidget {
  const JobRow({
    super.key,
    required this.summary,
    this.selected = false,
    this.chevron = false,
    this.onTap,
  });

  final JobSummary summary;
  final bool selected;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = summary;
    final ended = s.ended;
    final active = s.active;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${s.job.name}, ${jobSubtitle(s)}, ${ended ? 'final' : 'balance'} '
          '${AppFormat.hm(s.balance, signed: true)}',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
          child: Row(
            children: [
              Container(
                width: AppSize.iconTile,
                height: AppSize.iconTile,
                decoration: BoxDecoration(
                  color: selected ? colors.accentFill : colors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  AppIcons.briefcase,
                  size: AppIconSize.lg,
                  color: selected ? colors.onAccent : (ended ? colors.textMuted : colors.text),
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.job.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLg
                            .copyWith(color: ended ? colors.textMuted : colors.text)),
                    Row(
                      children: [
                        if (active != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(color: colors.accentFill, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: AppSpace.s1),
                        ],
                        Flexible(
                          child: Text(jobSubtitle(s),
                              style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppFormat.hm(s.balance, signed: true),
                      style: AppTextStyles.statSm
                          .copyWith(color: ended ? colors.textMuted : colors.text)),
                  Text(ended ? 'final' : 'balance',
                      style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
                ],
              ),
              if (chevron) ...[
                const SizedBox(width: AppSpace.s1),
                Icon(AppIcons.caretRight, size: AppIconSize.md, color: colors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final _monthYear = DateFormat('MMM yyyy');
final _dayMonthYear = DateFormat('d MMM yyyy');

/// "Tracking since 08:12", "6 h/wk · Tue, Thu · since 15 Mar 2026", or
/// "Oct 2023 – Dec 2025 · ended".
String jobSubtitle(JobSummary s) {
  if (s.active != null) return 'Tracking since ${AppFormat.time(s.active!.startTime)}';
  if (s.ended) {
    return '${_monthYear.format(s.job.startDate)} – ${_monthYear.format(s.job.endDate!)} · ended';
  }
  return [
    if (s.settings != null) '${AppFormat.hoursLabel(s.settings!.weeklyHours)}/wk',
    if (s.settings != null) workDaysLabel(s.settings!.workDays),
    'since ${_dayMonthYear.format(s.job.startDate)}',
  ].join(' · ');
}
