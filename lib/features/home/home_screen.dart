/// Home's data half: reads the providers, builds a [HomeView], hands it to
/// [HomeBody]. Everything visual lives in the body; everything live lives here.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../domain/date_only.dart';
import '../../domain/tracking_state.dart';
import '../../providers/balance_providers.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/edit_session_sheet.dart';
import 'home_body.dart';
import 'home_view.dart';

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
    final balance = ref.watch(latestBalanceProvider).valueOrNull;
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
      onDeleteSyntheticBreak: () =>
          ref.read(workSessionRepositoryProvider).deleteSyntheticBreak(today),
    );

    // A break ticks too — the ring shows how long it has been running.
    _syncTicker(
      live: view.state == TrackingState.tracking || view.state == TrackingState.onBreak,
    );

    return HomeBody(
      view: view,
      onOpenSettings: widget.onOpenSettings,
      onToggleTracking: () => _toggleTracking(active?.id),
      onRemoveLeave: leave.isEmpty ? null : () => _removeLeave(today, leave),
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
    if (activeSessionId != null) {
      await repo.checkOut(sessionId: activeSessionId, at: DateTime.now());
    } else {
      await repo.checkIn(DateTime.now());
    }
  }
}
