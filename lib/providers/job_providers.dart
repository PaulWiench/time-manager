import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../domain/date_only.dart';
import '../domain/tracking_state.dart' show kBreakWindow;
import '../domain/vacation_proration.dart';
import 'database_providers.dart';
import 'repository_providers.dart';

/// Every job, active ones by start date first, then ended ones newest first.
final jobsProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobRepositoryProvider).watchAll();
});

final _selectedPreference = StreamProvider<String?>((ref) {
  return ref.watch(appDatabaseProvider).jobDao.watchPreference('selectedJobId');
});

/// The job Home, History and Stats are showing — one app-wide choice.
///
/// Null only before onboarding has created a job. Falls back to the first
/// active job when nothing was chosen yet, or the choice no longer exists.
final selectedJobIdProvider = Provider<int?>((ref) {
  final jobs = ref.watch(jobsProvider).valueOrNull ?? const <Job>[];
  if (jobs.isEmpty) return null;
  final chosen = int.tryParse(ref.watch(_selectedPreference).valueOrNull ?? '');
  if (chosen != null && jobs.any((j) => j.id == chosen)) return chosen;
  return (jobs.firstWhere((j) => j.endDate == null, orElse: () => jobs.first)).id;
});

final selectedJobProvider = Provider<Job?>((ref) {
  final id = ref.watch(selectedJobIdProvider);
  final jobs = ref.watch(jobsProvider).valueOrNull ?? const <Job>[];
  for (final job in jobs) {
    if (job.id == id) return job;
  }
  return null;
});

/// More than one job exists, active or ended — the switcher shows only then.
final hasSeveralJobsProvider = Provider<bool>((ref) {
  return (ref.watch(jobsProvider).valueOrNull?.length ?? 0) > 1;
});

/// The selected job has ended: Home shows its final balance, check-in is off.
final selectedJobEndedProvider = Provider<bool>((ref) {
  return ref.watch(selectedJobProvider)?.endDate != null;
});

/// The selected job's vacation entitlement for [year]: its standing yearly
/// quota, pro-rated to the months the job covers, plus rollover.
class VacationEntitlement {
  const VacationEntitlement({
    required this.yearlyQuota,
    required this.prorated,
    required this.rolloverDays,
  });

  final double yearlyQuota;
  final ProratedVacation prorated;
  final double rolloverDays;

  double get totalDays => prorated.days + rolloverDays;
}

final vacationEntitlementProvider =
    Provider.autoDispose.family<VacationEntitlement?, int>((ref, year) {
  final job = ref.watch(selectedJobProvider);
  if (job == null) return null;
  final standing = ref
      .watch(_standingQuota((jobId: job.id, year: year)))
      .valueOrNull;
  final exactYear = standing != null && standing.year == year ? standing : null;
  final quota = standing?.totalDays ?? 30;
  return VacationEntitlement(
    yearlyQuota: quota,
    prorated: proratedVacationDays(
      yearlyQuota: quota,
      jobStart: dateOnly(job.startDate),
      jobEnd: job.endDate,
      year: year,
    ),
    rolloverDays: exactYear?.rolloverDays ?? 0,
  );
});

final _standingQuota = StreamProvider.autoDispose
    .family<VacationQuota?, ({int jobId, int year})>((ref, key) {
  return ref.watch(vacationQuotaRepositoryProvider).watchStandingFor(key.jobId, key.year);
});

/// What the switcher and the jobs list say about one job: its schedule, the
/// session running on it, and its balance.
class JobSummary {
  const JobSummary({
    required this.job,
    required this.settings,
    required this.active,
    required this.balance,
  });

  final Job job;
  final AppSetting? settings;
  final WorkSession? active;

  /// The settled balance — through yesterday, or through the last working
  /// day for an ended job.
  final double balance;

  bool get ended => job.endDate != null;
}

final _jobSettings = StreamProvider.autoDispose.family<AppSetting?, int>((ref, jobId) {
  return ref.watch(appDatabaseProvider).settingsDao.watchLatest(jobId);
});

final _jobActive = StreamProvider.autoDispose.family<WorkSession?, int>((ref, jobId) {
  return ref.watch(appDatabaseProvider).workSessionDao.watchActive(jobId);
});

final _jobBalance =
    StreamProvider.autoDispose.family<BalanceSnapshot?, ({int jobId, DateTime before})>(
        (ref, key) {
  return ref.watch(appDatabaseProvider).balanceSnapshotDao.watchLatestBefore(key.jobId, key.before);
});

final jobSummaryProvider = Provider.autoDispose.family<JobSummary?, int>((ref, jobId) {
  final jobs = ref.watch(jobsProvider).valueOrNull ?? const <Job>[];
  Job? job;
  for (final j in jobs) {
    if (j.id == jobId) job = j;
  }
  if (job == null) return null;
  final today = dateOnly(DateTime.now());
  final before = job.endDate == null ? today : shiftDays(dateOnly(job.endDate!), 1);
  final settled = ref.watch(_jobBalance((jobId: jobId, before: before))).valueOrNull;
  return JobSummary(
    job: job,
    settings: ref.watch(_jobSettings(jobId)).valueOrNull,
    active: ref.watch(_jobActive(jobId)).valueOrNull,
    balance: settled?.balance ?? job.startingBalanceHours,
  );
});

/// How long after checking out the day still reads as "on break" (default
/// 2 h, `kBreakWindow`). One preference for every job — it describes how
/// the person takes breaks, not a contract. The widget reads the same key.
const kBreakWindowKey = 'breakWindowMinutes';

final breakWindowProvider = StreamProvider<Duration>((ref) {
  return ref
      .watch(appDatabaseProvider)
      .jobDao
      .watchPreference(kBreakWindowKey)
      .map((value) => Duration(minutes: int.tryParse(value ?? '') ?? kBreakWindow.inMinutes));
});
