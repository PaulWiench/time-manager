/// Shared plumbing for the render tests.
///
/// Renders are reference images to look at, not assertions to defend — the
/// point is to see a designed state without booting an emulator next to a
/// Gradle build. Regenerate them whenever the design moves:
///
///     flutter test test/screenshots --update-goldens
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/app_colors.dart';
import 'package:time_manager/core/theme/app_dimens.dart';
import 'package:time_manager/core/theme/app_text_styles.dart';
import 'package:time_manager/core/theme/app_theme.dart';

/// The real device this app runs on, so screen renders are directly comparable
/// to the design's (which were drawn at 393x851 dp).
const phoneSize = Size(1080, 2340);
const phoneDpr = 2.625;

/// Draws [screen] and writes it to `goldens/<name>--<light|dark>.png`.
///
/// Animations are switched off through [MediaQueryData.disableAnimations], not
/// merely settled: the pulsing knob and the active timeline dot loop forever,
/// and `pumpAndSettle` against a repeating controller never returns.
Future<void> renderGolden(
  WidgetTester tester, {
  required String name,
  required Brightness brightness,
  required Widget child,
  Size size = phoneSize,
  double dpr = phoneDpr,
  Color? background,
  Future<void> Function(WidgetTester)? interact,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: widget!,
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          color: background ?? context.colors.background,
          // Material widgets that the app only ever meets inside a Scaffold —
          // Switch, InkWell — assert without a Material ancestor. A component
          // sheet has no Scaffold, so one transparent Material stands in.
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Some states only exist part-way through an interaction — a date range with
  // both ends placed and one day tapped back off, say. Rendering those from
  // their initial widget would be a reference image of nothing in particular.
  if (interact != null) {
    await interact(tester);
    await tester.pumpAndSettle();
  }

  final suffix = brightness == Brightness.dark ? 'dark' : 'light';
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name--$suffix.png'));
}

/// Bundled fonts are not loaded into the test binding automatically; without
/// this every render comes out in the placeholder font and tells you nothing
/// about the type scale.
Future<void> loadAppFonts() async {
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

/// A titled section of a component sheet, with a caption under each specimen —
/// the same shape as the design's own component boards, so the two can be held
/// side by side.
class SheetSection extends StatelessWidget {
  const SheetSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.headline.copyWith(color: colors.text)),
            const SizedBox(width: AppSpace.s3),
            Expanded(child: Container(height: 1, color: colors.divider)),
          ],
        ),
        const SizedBox(height: AppSpace.s5),
        Wrap(spacing: AppSpace.s6, runSpacing: AppSpace.s6, children: children),
        const SizedBox(height: AppSpace.s8),
      ],
    );
  }
}

/// One specimen and the label that says which state it is.
class Specimen extends StatelessWidget {
  const Specimen({super.key, required this.label, required this.child, this.width});

  final String label;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: AppSpace.s2),
          Text(label, style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}

/// A page of sections, with the same header the design's boards carry.
class ComponentSheet extends StatelessWidget {
  const ComponentSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GOLDEN HOUR', style: AppTextStyles.kicker.copyWith(color: colors.accentText)),
          const SizedBox(height: AppSpace.s2),
          Text(title, style: AppTextStyles.title.copyWith(color: colors.text)),
          const SizedBox(height: AppSpace.s1),
          Text(subtitle, style: AppTextStyles.body.copyWith(color: colors.textMuted)),
          const SizedBox(height: AppSpace.s8),
          ...sections,
        ],
      ),
    );
  }
}
