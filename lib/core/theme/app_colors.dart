import 'package:flutter/material.dart';

/// Golden Hour's semantic colour roles.
///
/// A [ThemeExtension] rather than a [ColorScheme]: roles like the slab, the
/// break hue, the heatmap ramp and the single warning treatment have no
/// Material 3 slot to live in, and screens should never have to decide which
/// scheme slot approximates what the design named. Reach for these through
/// `context.colors` — no screen reads [ColorScheme] directly.
///
/// Shadows are part of the same contract because light and dark separate
/// surfaces differently: light lifts them with a shadow, dark steps the tone
/// and, on the slab, adds a hairline rim instead.
class AppColors extends ThemeExtension<AppColors> {
  // Neutrals and surfaces.
  final Color background;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color textMuted;
  final Color divider;

  /// The Dusk Slab: the deep-violet hero block behind the balance, the ring,
  /// the floating nav and the widget. Present in BOTH themes — it is the one
  /// surface that does not invert.
  final Color slab;
  final Color onSlab;
  final Color onSlabMuted;
  final Color slabTrack;

  // Semantic hues. Fill paints blocks, Text is the same hue legible on a
  // light surface, Tint is the wash behind it.
  final Color accentFill;
  final Color accentText;
  final Color accentTint;
  final Color accentStrong;
  final Color onAccent;
  final Color breakFill;
  final Color breakText;
  final Color breakTint;
  final Color warningFill;
  final Color warningText;
  final Color warningTint;
  final Color holidayFill;
  final Color holidayText;
  final Color holidayTint;
  final Color vacationFill;
  final Color vacationText;
  final Color vacationTint;
  final Color sickFill;
  final Color sickText;
  final Color sickTint;
  final Color idle;

  // Controls and chart marks.
  final Color track;
  final Color selected;
  final Color onSelected;

  /// Heatmap ramp, darkest-at-target in light and brightest-at-target in
  /// dark, so it also reads in greyscale.
  final Color heat0;
  final Color heat1;
  final Color heat2;
  final Color heat3;
  final Color heat4;
  final Color heat5;

  final Color focus;
  final Color ringLap;
  final Color scrim;

  /// Null in light: the slab has a shadow there and a rim only in dark.
  final Color? slabRim;

  /// Null in light: the ring's arc only glows against a dark ground.
  final Color? glowAccent;

  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowFloat;
  final List<BoxShadow> shadowSlab;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.textMuted,
    required this.divider,
    required this.slab,
    required this.onSlab,
    required this.onSlabMuted,
    required this.slabTrack,
    required this.accentFill,
    required this.accentText,
    required this.accentTint,
    required this.accentStrong,
    required this.onAccent,
    required this.breakFill,
    required this.breakText,
    required this.breakTint,
    required this.warningFill,
    required this.warningText,
    required this.warningTint,
    required this.holidayFill,
    required this.holidayText,
    required this.holidayTint,
    required this.vacationFill,
    required this.vacationText,
    required this.vacationTint,
    required this.sickFill,
    required this.sickText,
    required this.sickTint,
    required this.idle,
    required this.track,
    required this.selected,
    required this.onSelected,
    required this.heat0,
    required this.heat1,
    required this.heat2,
    required this.heat3,
    required this.heat4,
    required this.heat5,
    required this.focus,
    required this.ringLap,
    required this.scrim,
    required this.slabRim,
    required this.glowAccent,
    required this.shadowSm,
    required this.shadowFloat,
    required this.shadowSlab,
  });

  static const light = AppColors(
    background: Color(0xFFFAF5EE),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF3ECE2),
    text: Color(0xFF221A33),
    textMuted: Color(0xFF675D75),
    divider: Color(0xFFE4DACB),
    slab: Color(0xFF2E2447),
    onSlab: Color(0xFFFFF4E6),
    onSlabMuted: Color(0xFFBDB2D1),
    slabTrack: Color(0xFF4B4068),
    accentFill: Color(0xFFF7B27A),
    accentText: Color(0xFFA0480C),
    accentTint: Color(0xFFFDE8D4),
    accentStrong: Color(0xFFD9691C),
    onAccent: Color(0xFF221A33),
    breakFill: Color(0xFFB3A1F5),
    breakText: Color(0xFF5A42B5),
    breakTint: Color(0xFFECE6FD),
    warningFill: Color(0xFFFFD23F),
    warningText: Color(0xFF7A5600),
    warningTint: Color(0xFFFFF0B3),
    holidayFill: Color(0xFF7ED8B2),
    holidayText: Color(0xFF1B6A4B),
    holidayTint: Color(0xFFDCF4E9),
    vacationFill: Color(0xFF7EC3F2),
    vacationText: Color(0xFF1A5D8C),
    vacationTint: Color(0xFFDCEEFB),
    sickFill: Color(0xFFF59CBB),
    sickText: Color(0xFFA0295A),
    sickTint: Color(0xFFFCE2EC),
    idle: Color(0xFF948AA3),
    track: Color(0xFFEEE5D8),
    selected: Color(0xFF2E2447),
    onSelected: Color(0xFFFFF4E6),
    heat0: Color(0xFFF3ECE2),
    heat1: Color(0xFFFDDDBE),
    heat2: Color(0xFFF7B27A),
    heat3: Color(0xFFE8843F),
    heat4: Color(0xFFC4561A),
    heat5: Color(0xFF8A3A12),
    focus: Color(0xFF2E2447),
    ringLap: Color(0xFFC4561A),
    scrim: Color(0x66221A33),
    slabRim: null,
    glowAccent: null,
    shadowSm: [BoxShadow(color: Color(0x0F221A33), blurRadius: 2, offset: Offset(0, 1))],
    shadowFloat: [BoxShadow(color: Color(0x382E2447), blurRadius: 28, offset: Offset(0, 10))],
    shadowSlab: [BoxShadow(color: Color(0x472E2447), blurRadius: 36, offset: Offset(0, 16))],
  );

  static const dark = AppColors(
    background: Color(0xFF14101E),
    surface: Color(0xFF201A2F),
    surface2: Color(0xFF2B243F),
    text: Color(0xFFF6F0E9),
    textMuted: Color(0xFFA89EBB),
    divider: Color(0xFF352D4B),
    slab: Color(0xFF281F3D),
    onSlab: Color(0xFFFFF4E6),
    onSlabMuted: Color(0xFFB3A8C9),
    slabTrack: Color(0xFF3F3560),
    accentFill: Color(0xFFFFB77D),
    accentText: Color(0xFFFFC597),
    accentTint: Color(0xFF3A2830),
    accentStrong: Color(0xFFFFB77D),
    onAccent: Color(0xFF221A33),
    breakFill: Color(0xFFB8A5FF),
    breakText: Color(0xFFCBBEFF),
    breakTint: Color(0xFF2D2652),
    warningFill: Color(0xFFFFD84D),
    warningText: Color(0xFFFFDD6B),
    warningTint: Color(0xFF3A3119),
    holidayFill: Color(0xFF74D6AE),
    holidayText: Color(0xFF93E5C4),
    holidayTint: Color(0xFF1B3230),
    vacationFill: Color(0xFF79C1F2),
    vacationText: Color(0xFF9DD2F7),
    vacationTint: Color(0xFF1A2B42),
    sickFill: Color(0xFFF595B6),
    sickText: Color(0xFFF8B3CB),
    sickTint: Color(0xFF3A1F35),
    idle: Color(0xFF82789C),
    track: Color(0xFF2F2846),
    selected: Color(0xFFF6F0E9),
    onSelected: Color(0xFF221A33),
    heat0: Color(0xFF2B243F),
    heat1: Color(0xFF4A3040),
    heat2: Color(0xFF7E4636),
    heat3: Color(0xFFC2693A),
    heat4: Color(0xFFF59A5B),
    heat5: Color(0xFFFFC896),
    focus: Color(0xFFFFB77D),
    ringLap: Color(0xFFC2693A),
    scrim: Color(0x99000000),
    slabRim: Color(0x0FFFF4E6),
    glowAccent: Color(0x73FFB77D),
    shadowSm: [],
    shadowFloat: [BoxShadow(color: Color(0x8C000000), blurRadius: 28, offset: Offset(0, 10))],
    shadowSlab: [],
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? text,
    Color? textMuted,
    Color? divider,
    Color? slab,
    Color? onSlab,
    Color? onSlabMuted,
    Color? slabTrack,
    Color? accentFill,
    Color? accentText,
    Color? accentTint,
    Color? accentStrong,
    Color? onAccent,
    Color? breakFill,
    Color? breakText,
    Color? breakTint,
    Color? warningFill,
    Color? warningText,
    Color? warningTint,
    Color? holidayFill,
    Color? holidayText,
    Color? holidayTint,
    Color? vacationFill,
    Color? vacationText,
    Color? vacationTint,
    Color? sickFill,
    Color? sickText,
    Color? sickTint,
    Color? idle,
    Color? track,
    Color? selected,
    Color? onSelected,
    Color? heat0,
    Color? heat1,
    Color? heat2,
    Color? heat3,
    Color? heat4,
    Color? heat5,
    Color? focus,
    Color? ringLap,
    Color? scrim,
    Color? slabRim,
    Color? glowAccent,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowFloat,
    List<BoxShadow>? shadowSlab,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      slab: slab ?? this.slab,
      onSlab: onSlab ?? this.onSlab,
      onSlabMuted: onSlabMuted ?? this.onSlabMuted,
      slabTrack: slabTrack ?? this.slabTrack,
      accentFill: accentFill ?? this.accentFill,
      accentText: accentText ?? this.accentText,
      accentTint: accentTint ?? this.accentTint,
      accentStrong: accentStrong ?? this.accentStrong,
      onAccent: onAccent ?? this.onAccent,
      breakFill: breakFill ?? this.breakFill,
      breakText: breakText ?? this.breakText,
      breakTint: breakTint ?? this.breakTint,
      warningFill: warningFill ?? this.warningFill,
      warningText: warningText ?? this.warningText,
      warningTint: warningTint ?? this.warningTint,
      holidayFill: holidayFill ?? this.holidayFill,
      holidayText: holidayText ?? this.holidayText,
      holidayTint: holidayTint ?? this.holidayTint,
      vacationFill: vacationFill ?? this.vacationFill,
      vacationText: vacationText ?? this.vacationText,
      vacationTint: vacationTint ?? this.vacationTint,
      sickFill: sickFill ?? this.sickFill,
      sickText: sickText ?? this.sickText,
      sickTint: sickTint ?? this.sickTint,
      idle: idle ?? this.idle,
      track: track ?? this.track,
      selected: selected ?? this.selected,
      onSelected: onSelected ?? this.onSelected,
      heat0: heat0 ?? this.heat0,
      heat1: heat1 ?? this.heat1,
      heat2: heat2 ?? this.heat2,
      heat3: heat3 ?? this.heat3,
      heat4: heat4 ?? this.heat4,
      heat5: heat5 ?? this.heat5,
      focus: focus ?? this.focus,
      ringLap: ringLap ?? this.ringLap,
      scrim: scrim ?? this.scrim,
      slabRim: slabRim ?? this.slabRim,
      glowAccent: glowAccent ?? this.glowAccent,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowFloat: shadowFloat ?? this.shadowFloat,
      shadowSlab: shadowSlab ?? this.shadowSlab,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      slab: Color.lerp(slab, other.slab, t)!,
      onSlab: Color.lerp(onSlab, other.onSlab, t)!,
      onSlabMuted: Color.lerp(onSlabMuted, other.onSlabMuted, t)!,
      slabTrack: Color.lerp(slabTrack, other.slabTrack, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      breakFill: Color.lerp(breakFill, other.breakFill, t)!,
      breakText: Color.lerp(breakText, other.breakText, t)!,
      breakTint: Color.lerp(breakTint, other.breakTint, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
      holidayFill: Color.lerp(holidayFill, other.holidayFill, t)!,
      holidayText: Color.lerp(holidayText, other.holidayText, t)!,
      holidayTint: Color.lerp(holidayTint, other.holidayTint, t)!,
      vacationFill: Color.lerp(vacationFill, other.vacationFill, t)!,
      vacationText: Color.lerp(vacationText, other.vacationText, t)!,
      vacationTint: Color.lerp(vacationTint, other.vacationTint, t)!,
      sickFill: Color.lerp(sickFill, other.sickFill, t)!,
      sickText: Color.lerp(sickText, other.sickText, t)!,
      sickTint: Color.lerp(sickTint, other.sickTint, t)!,
      idle: Color.lerp(idle, other.idle, t)!,
      track: Color.lerp(track, other.track, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      onSelected: Color.lerp(onSelected, other.onSelected, t)!,
      heat0: Color.lerp(heat0, other.heat0, t)!,
      heat1: Color.lerp(heat1, other.heat1, t)!,
      heat2: Color.lerp(heat2, other.heat2, t)!,
      heat3: Color.lerp(heat3, other.heat3, t)!,
      heat4: Color.lerp(heat4, other.heat4, t)!,
      heat5: Color.lerp(heat5, other.heat5, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      ringLap: Color.lerp(ringLap, other.ringLap, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      slabRim: Color.lerp(slabRim, other.slabRim, t),
      glowAccent: Color.lerp(glowAccent, other.glowAccent, t),
      shadowSm: t < 0.5 ? shadowSm : other.shadowSm,
      shadowFloat: t < 0.5 ? shadowFloat : other.shadowFloat,
      shadowSlab: t < 0.5 ? shadowSlab : other.shadowSlab,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
