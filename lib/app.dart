import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'providers/settings_providers.dart';
import 'widgets/app_bottom_nav.dart';

class TimeManagerApp extends StatelessWidget {
  const TimeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeManager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _RootGate(),
    );
  }
}

/// Routes to Onboarding until the first Settings row exists, then to the
/// bottom-nav shell — the app's single top-level fork. `latestSettingsProvider`
/// is a DB watch stream, so once onboarding writes its Settings row this
/// rebuilds into the shell on its own; Onboarding's `onDone` needs no
/// explicit navigation.
class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(latestSettingsProvider);

    return settings.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Something went wrong: $err'))),
      data: (setting) {
        if (setting == null) {
          return OnboardingScreen(onDone: () {});
        }
        return const _AppShell();
      },
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  AppTab _tab = AppTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: AppTab.values.indexOf(_tab),
        children: [
          HomeScreen(onOpenSettings: () => setState(() => _tab = AppTab.settings)),
          const HistoryScreen(),
          const StatsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(active: _tab, onSelect: (t) => setState(() => _tab = t)),
    );
  }
}
