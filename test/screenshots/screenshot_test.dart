/// Renders real UI to PNG without an emulator.
///
/// The redesign needs a visual check after every change, and booting an
/// emulator next to a Gradle build is what it costs a machine with 15 GB of
/// RAM (see android/gradle.properties). `flutter test --update-goldens` draws
/// the same widget tree offscreen for a fraction of the memory, so this is the
/// default loop; the emulator is reserved for end-to-end checks, run alone.
///
///     flutter test test/screenshots --update-goldens
///
/// Writes to test/screenshots/goldens/. These are reference renders to look
/// at, not assertions to defend — regenerate them whenever the design moves.
///
/// Screens that read the database are deliberately absent for now: driving
/// drift from a widget test leaves timers pending in the fake-async zone, and
/// the fix (overriding each data provider with a fixed value) is the same work
/// as building the state matrix — so it lands with the screens themselves,
/// where every designed state has to be reproduced anyway.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/icons/app_icons.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/core/theme/app_text_styles.dart';
import 'package:time_manager/core/theme/app_theme.dart';
import 'package:time_manager/features/onboarding/onboarding_screen.dart';

/// The real device this app runs on, so renders are directly comparable to the
/// design's (which were drawn at 393x851 dp).
const _size = Size(1080, 2340);
const _dpr = 2.625;

void main() {
  setUpAll(_loadFonts);

  for (final brightness in [Brightness.light, Brightness.dark]) {
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('tokens ($suffix)', (tester) async {
      await _pump(tester, brightness, const _TokenSpecimen());
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/tokens--$suffix.png'));
    });

    testWidgets('onboarding step 1 ($suffix)', (tester) async {
      await _pump(tester, brightness, OnboardingScreen(onDone: () {}));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/onboarding-1--$suffix.png'));
    });
  }
}

Future<void> _pump(WidgetTester tester, Brightness brightness, Widget screen) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

/// Every colour role and every type role on one page, per theme — the sheet to
/// check a token change against before any screen is rebuilt.
class _TokenSpecimen extends StatelessWidget {
  const _TokenSpecimen();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget swatch(String name, Color fill, {Color? ink}) => Container(
          width: 104,
          height: 56,
          padding: const EdgeInsets.all(AppSpace.s1),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: c.divider),
          ),
          child: Text(name, style: AppTextStyles.micro.copyWith(color: ink ?? c.text)),
        );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.gutterSparse),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Golden Hour', style: AppTextStyles.title.copyWith(color: c.text)),
              const SizedBox(height: AppSpace.s2),
              Text('Token specimen', style: AppTextStyles.body.copyWith(color: c.textMuted)),
              const SizedBox(height: AppSpace.s6),

              // The slab is the one surface that does not invert between themes.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.s5),
                decoration: BoxDecoration(
                  color: c.slab,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: c.slabRim == null ? null : Border.all(color: c.slabRim!),
                  boxShadow: c.shadowSlab,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BALANCE', style: AppTextStyles.kicker.copyWith(color: c.onSlabMuted)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('−15:58', style: AppTextStyles.hero.copyWith(color: c.onSlab)),
                        const SizedBox(width: AppSpace.s1),
                        Text('h', style: AppTextStyles.statSm.copyWith(color: c.onSlabMuted)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s2),
                    Row(
                      children: [
                        Icon(AppIcons.sun, size: AppIconSize.xs, color: c.accentFill),
                        const SizedBox(width: AppSpace.s1),
                        Text('TRACKING', style: AppTextStyles.kicker.copyWith(color: c.accentFill)),
                        const SizedBox(width: AppSpace.s4),
                        Icon(AppIcons.coffee, size: AppIconSize.xs, color: c.breakFill),
                        const SizedBox(width: AppSpace.s1),
                        Text('ON BREAK', style: AppTextStyles.kicker.copyWith(color: c.breakFill)),
                        const SizedBox(width: AppSpace.s4),
                        Icon(AppIcons.moon, size: AppIconSize.xs, color: c.onSlabMuted),
                        const SizedBox(width: AppSpace.s1),
                        Text('CHECKED OUT', style: AppTextStyles.kicker.copyWith(color: c.onSlabMuted)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s3),
                    Text('1:46:12', style: AppTextStyles.timer.copyWith(color: c.onSlab)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s6),

              Text('SURFACES', style: AppTextStyles.kicker.copyWith(color: c.textMuted)),
              const SizedBox(height: AppSpace.s2),
              Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                swatch('background', c.background),
                swatch('surface', c.surface),
                swatch('surface2', c.surface2),
                swatch('track', c.track),
                swatch('selected', c.selected, ink: c.onSelected),
                swatch('idle', c.idle, ink: c.onAccent),
              ]),
              const SizedBox(height: AppSpace.s5),

              Text('SEMANTIC FILLS', style: AppTextStyles.kicker.copyWith(color: c.textMuted)),
              const SizedBox(height: AppSpace.s2),
              Wrap(spacing: AppSpace.s2, runSpacing: AppSpace.s2, children: [
                swatch('accent', c.accentFill, ink: c.onAccent),
                swatch('break', c.breakFill, ink: c.onAccent),
                swatch('warning', c.warningFill, ink: c.onAccent),
                swatch('holiday', c.holidayFill, ink: c.onAccent),
                swatch('vacation', c.vacationFill, ink: c.onAccent),
                swatch('sick', c.sickFill, ink: c.onAccent),
              ]),
              const SizedBox(height: AppSpace.s5),

              Text('HEATMAP RAMP', style: AppTextStyles.kicker.copyWith(color: c.textMuted)),
              const SizedBox(height: AppSpace.s2),
              Row(
                children: [c.heat0, c.heat1, c.heat2, c.heat3, c.heat4, c.heat5]
                    .map((h) => Container(
                          width: 56,
                          height: 40,
                          margin: const EdgeInsets.only(right: AppSpace.s1),
                          decoration: BoxDecoration(
                            color: h,
                            borderRadius: BorderRadius.circular(AppRadius.cellLg),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpace.s5),

              Text('TYPE', style: AppTextStyles.kicker.copyWith(color: c.textMuted)),
              const SizedBox(height: AppSpace.s2),
              ...[
                ('hero 56/800', AppTextStyles.hero),
                ('timer 40/800', AppTextStyles.timer),
                ('title 30/800', AppTextStyles.title),
                ('stat 28/800', AppTextStyles.stat),
                ('headline 18/700', AppTextStyles.headline),
                ('bodyLg 16/600', AppTextStyles.bodyLg),
                ('body 14/500', AppTextStyles.body),
                ('label 15/800', AppTextStyles.label),
                ('caption 12/600', AppTextStyles.caption),
              ].map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s1),
                    child: Text(s.$1, style: s.$2.copyWith(color: c.text)),
                  )),
              const SizedBox(height: AppSpace.s5),

              Text('WARNING TREATMENT', style: AppTextStyles.kicker.copyWith(color: c.textMuted)),
              const SizedBox(height: AppSpace.s2),
              Row(children: [
                Container(
                  color: c.warningTint,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
                  child: Text('−20:41', style: AppTextStyles.stat.copyWith(color: c.warningText)),
                ),
                const SizedBox(width: AppSpace.s4),
                Switch(value: true, onChanged: (_) {}),
                Switch(value: false, onChanged: (_) {}),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bundled fonts are not loaded into the test binding automatically; without
/// this every render comes out in the placeholder font and tells you nothing
/// about the type scale.
Future<void> _loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const families = {
    'Manrope': 'assets/fonts/Manrope-Variable.ttf',
    'PhosphorBold': 'assets/fonts/Phosphor-Bold.ttf',
    'PhosphorFill': 'assets/fonts/Phosphor-Fill.ttf',
  };
  for (final entry in families.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}
