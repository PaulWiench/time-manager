import 'package:flutter/material.dart';

/// Golden Hour's type scale, in Manrope.
///
/// The font is bundled rather than fetched by `google_fonts`: this is a
/// sideloaded personal app, and the first launch after an install must not
/// depend on a network round-trip to render the balance.
///
/// Manrope ships as a single variable font, so every style sets both
/// [FontWeight] and a `wght` [FontVariation] — the weight alone does not move
/// a variable axis, and the axis alone leaves fallback text at the wrong
/// weight. Every style is tabular: the timer must not jitter as digits change.
///
/// Colours are deliberately absent — callers apply an [AppColors] role with
/// `copyWith`, so the scale and the palette stay independent.
class AppTextStyles {
  AppTextStyles._();

  static const String family = 'Manrope';

  static TextStyle _m(
    double size,
    int weight, {
    required double lineHeight,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        height: lineHeight / size,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Home's balance, and nothing else — the largest number in the app.
  static final hero = _m(56, 800, lineHeight: 56, letterSpacing: -2.0);

  /// The ring's running timer and today's total.
  static final timer = _m(40, 800, lineHeight: 44, letterSpacing: -1.2);

  /// Chart headline values, onboarding values, the widget's today figure.
  static final stat = _m(28, 800, lineHeight: 32, letterSpacing: -0.6);

  /// Row deltas, date-block days, and the unit that trails a hero or stat.
  static final statSm = _m(18, 800, lineHeight: 22, letterSpacing: -0.3);

  static final title = _m(30, 800, lineHeight: 36, letterSpacing: -0.8);
  static final headline = _m(18, 700, lineHeight: 24, letterSpacing: -0.2);

  static final bodyLg = _m(16, 600, lineHeight: 22, letterSpacing: -0.1);
  static final body = _m(14, 500, lineHeight: 20);

  /// Buttons, segments, chips, weekday toggles.
  static final label = _m(15, 800, lineHeight: 20);

  static final caption = _m(12, 600, lineHeight: 16);

  /// UPPERCASE labels above numbers and groups. Casing is the caller's job.
  static final kicker = _m(11, 800, lineHeight: 14, letterSpacing: 1.1);

  /// Chart axes and heatmap weekday letters.
  static final micro = _m(10, 700, lineHeight: 12, letterSpacing: 0.3);

  // Weight-only variants, declared so nobody improvises a `copyWith`.
  static final bodyStrong = _m(14, 700, lineHeight: 20);
  static final captionStrong = _m(12, 800, lineHeight: 16);
  static final microStrong = _m(10, 800, lineHeight: 12, letterSpacing: 0.3);

  // ---------------------------------------------------------------------
  // Pre-redesign names, kept only so screens that haven't been rebuilt yet
  // still compile. Each screen drops its own as it is redesigned; these all
  // disappear at the end of the redesign.
  // ---------------------------------------------------------------------

  @Deprecated('Use timer or stat')
  static TextStyle heroNumber(double size) => _m(size, 800, lineHeight: size * 1.1, letterSpacing: -0.6);

  @Deprecated('Use title')
  static final screenTitle = title;

  @Deprecated('Use headline')
  static final sectionTitle = headline;

  @Deprecated('Use bodyLg')
  static final bodyLarge = bodyLg;

  @Deprecated('Use body')
  static final bodyRegular = body;

  @Deprecated('Use caption')
  static final meta = caption;

  @Deprecated('Use caption')
  static final metaMedium = caption;

  @Deprecated('Use kicker')
  static final kickerSm = kicker;

  @Deprecated('Use title')
  static final onboardingTitle = title;
}
