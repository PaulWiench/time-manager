import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/motion.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'providers/repository_providers.dart';
import 'providers/rollover_providers.dart';
import 'widgets/pill_nav.dart';
import 'providers/job_providers.dart';

class TimeManagerApp extends StatelessWidget {
  const TimeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stamped',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _RootGate(),
    );
  }
}

/// Routes to Onboarding until the first job exists, then to the bottom-nav
/// shell — the app's single top-level fork. `jobsProvider` is a DB watch
/// stream, so once onboarding creates the job this rebuilds into the shell on
/// its own; Onboarding's `onDone` needs no explicit navigation.
///
/// It waits on the jobs list itself rather than on the selected job's
/// settings: those read as null while the list is still loading, which would
/// flash onboarding at every launch.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);

    return jobs.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Something went wrong: $err'))),
      data: (all) {
        if (all.isEmpty) {
          return OnboardingScreen(onDone: () {});
        }
        // Fire-and-forget: idempotent, and the shell doesn't need to block on
        // them — see holidaySeedProvider and dayRolloverProvider.
        ref.watch(holidaySeedProvider);
        ref.watch(dayRolloverProvider);
        return const AppShell();
      },
    );
  }
}

/// The one Scaffold in the app.
///
/// The tabs are an [IndexedStack] so scroll positions survive switching, with
/// the floating nav stacked over them rather than sitting in
/// `bottomNavigationBar` — the nav is meant to float clear of the content, and
/// content scrolls under it.
///
/// Each inactive tab is wrapped in a [TickerMode] that is off, so Home's pulsing
/// knob and ticking timer stop costing frames the moment you look at Stats.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  AppTab _tab = AppTab.home;

  /// 1 = the current tab is fully shown. A tab switch dips this to 0 and back,
  /// which is a fade-through: the outgoing view leaves before the incoming one
  /// arrives. A crossfade would blend two different screens into a third thing
  /// that is neither, and `AnimatedSwitcher` would rebuild the subtree and lose
  /// exactly the scroll positions the IndexedStack exists to keep.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 1),
  );

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _select(AppTab tab) async {
    if (tab == _tab) return;
    final motion = AppMotion.of(context);

    if (!motion.enabled) {
      setState(() => _tab = tab);
      return;
    }

    _fade.duration = motion.tabOut;
    await _fade.reverse();
    if (!mounted) return;
    setState(() => _tab = tab);
    _fade.duration = motion.tabIn;
    await _fade.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = AppTab.values.indexOf(_tab);

    final tabs = [
      HomeScreen(onOpenSettings: () => _select(AppTab.settings)),
      const HistoryScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fade,
              builder: (context, child) => Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  // Incoming content settles the last 2 % into place, so the
                  // switch reads as arriving rather than as blinking.
                  scale: kTabInScale + (1 - kTabInScale) * _fade.value,
                  child: child,
                ),
              ),
              child: IndexedStack(
                index: index,
                children: [
                  for (final (i, tab) in tabs.indexed)
                    TickerMode(enabled: i == index, child: tab),
                ],
              ),
            ),
          ),
          Positioned(
            left: kNavInset,
            right: kNavInset,
            bottom: kNavInset + MediaQuery.viewPaddingOf(context).bottom,
            child: PillNav(active: _tab, onSelect: _select),
          ),
        ],
      ),
    );
  }
}
