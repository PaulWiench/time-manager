/// Home's data half: reads the providers, builds a [HomeView], hands it to
/// [HomeBody]. Everything visual lives in the body; everything live lives here.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../domain/date_only.dart';
import '../../domain/tracking_state.dart';
import '../../providers/balance_providers.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/edit_session_sheet.dart';
import '../../widgets/session_fix_sheet.dart';
import '../../domain/session_fix.dart';
import 'home_body.dart';
import 'home_view.dart';
import '../../providers/job_providers.dart';
import '../jobs/job_pill.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _tick;

  /// The ring's timer counts seconds, so Home rebuilds once a second — but
  /// only while something is actually running. A checked-out day is static and
  /// should cost nothing.
  void _syncTicker({required bool live}) {
    if (live && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!live && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = dateOnly(now);

    final settings = ref.watch(effectiveSettingsForProvider(today)).valueOrNull;
    final dayEntry = ref.watch(dayEntryForDateProvider(today)).valueOrNull;
    final sessions = ref.watch(sessionsForDateProvider(today)).valueOrNull ?? const [];
    final breaks = ref.watch(breaksForDateProvider(today)).valueOrNull ?? const [];
    final leave = ref.watch(leaveForDateProvider(today)).valueOrNull ?? const [];
    // Strictly before today: buildHomeView adds today back live, under the
    // rule that an unfinished day cannot count against you.
    final balance = ref.watch(settledBalanceProvider(today)).valueOrNull;
    final active = ref.watch(activeSessionProvider).valueOrNull;

    if (settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final view = buildHomeView(
      now: now,
      settings: settings,
      dayEntry: dayEntry,
      sessions: sessions,
      breaks: breaks,
      leave: leave,
      balance: balance,
      onEditSession: (session) => EditSessionSheet.show(context, session),
      onFixActive: (fix) => _fixActive(fix, active),
      breakWindow: ref.watch(breakWindowProvider).valueOrNull ?? kBreakWindow,
      onDeleteSyntheticBreak: () {
        final jobId = ref.read(selectedJobIdProvider);
        if (jobId != null) {
          ref.read(workSessionRepositoryProvider).deleteSyntheticBreak(jobId, today);
        }
      },
    );

    // A break ticks too — the ring shows how long it has been running.
    _syncTicker(
      live: view.state == TrackingState.tracking || view.state == TrackingState.onBreak,
    );

    final job = ref.watch(selectedJobProvider);
    final endedSummary = job?.endDate == null ? null : ref.watch(jobSummaryProvider(job!.id));
    return HomeBody(
      jobPill: ref.watch(hasSeveralJobsProvider) ? const JobPill() : null,
      endedJob: endedSummary == null
          ? null
          : EndedJob(
              finalBalance: endedSummary.balance,
              endLabel: DateFormat('d MMM yyyy').format(job!.endDate!),
              spanLabel: '${DateFormat('MMM yyyy').format(job.startDate)} – '
                  '${DateFormat('MMM yyyy').format(job.endDate!)}',
              warning: balanceBeyondBounds(
                endedSummary.balance,
                floorHours: settings.balanceFloorHours,
                capHours: settings.balanceCapHours,
              ),
            ),
      onSwitchJob: () => showJobSwitcher(context),
      view: view,
      onOpenSettings: widget.onOpenSettings,
      onToggleTracking: () => _toggleTracking(active?.id),
      onRemoveLeave: leave.isEmpty ? null : () => _removeLeave(today, leave),
    );
  }

  /// "Started earlier?" while tracking, "Check in at…" while on break.
  void _fixActive(SessionFix fix, WorkSession? active) {
    final jobId = ref.read(selectedJobIdProvider);
    if (jobId == null) return;
    final repo = ref.read(workSessionRepositoryProvider);
    final net = (ref.read(dayEntryForDateProvider(dateOnly(DateTime.now()))).valueOrNull
                ?.netWorkedHours ??
            0) +
        (active == null ? 0 : DateTime.now().difference(active.startTime).inSeconds / 3600.0);
    showSessionFixSheet(
      context: context,
      fix: fix,
      todayNetHours: net,
      onSave: (at) => switch (fix.kind) {
        SessionFixKind.startEarlier =>
          repo.moveActiveStart(sessionId: active!.id, newStart: at),
        SessionFixKind.checkInAt => repo.checkInAt(jobId, at),
      },
    );
  }

  Future<void> _removeLeave(DateTime date, List<LeaveEntry> leave) async {
    final repo = ref.read(leaveRepositoryProvider);
    for (final entry in leave) {
      await repo.deleteLeave(entry.id, date);
    }
  }

  Future<void> _toggleTracking(String? activeSessionId) async {
    final repo = ref.read(workSessionRepositoryProvider);
    final job = ref.read(selectedJobProvider);
    if (activeSessionId != null) {
      await repo.checkOut(sessionId: activeSessionId, at: DateTime.now());
    } else if (job != null && job.endDate == null) {
      await repo.checkIn(job.id, DateTime.now());
    }
  }
}
