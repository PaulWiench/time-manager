import 'package:flutter/material.dart';

import 'color_space.dart';

/// Semantic color roles from the Milestone 5 design handoff (Nocturne
/// system + break/warning hues at matching lightness/chroma). Exposed as a
/// [ThemeExtension] rather than overloading [ColorScheme] because these
/// roles (break, warning, idle, tint variants) don't map cleanly onto
/// Material 3's scheme slots.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color textMuted;
  final Color divider;

  final Color accentFill;
  final Color accentText;
  final Color accentTint;

  final Color breakFill;
  final Color breakText;
  final Color breakTint;

  final Color warningFill;
  final Color warningText;
  final Color warningTint;

  final Color idle;
  final List<BoxShadow> shadowSm;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.textMuted,
    required this.divider,
    required this.accentFill,
    required this.accentText,
    required this.accentTint,
    required this.breakFill,
    required this.breakText,
    required this.breakTint,
    required this.warningFill,
    required this.warningText,
    required this.warningTint,
    required this.idle,
    required this.shadowSm,
  });

  static final light = AppColors(
    background: const Color(0xFFF3F5FE),
    surface: const Color(0xFFFBFCFF),
    surface2: const Color(0xFFFFFFFF),
    text: const Color(0xFF292B31),
    textMuted: const Color(0xFF292B31).withValues(alpha: 0.55),
    divider: const Color(0xFF292B31).withValues(alpha: 0.12),
    accentFill: const Color(0xFF9184D9),
    accentText: const Color(0xFF5D5294),
    accentTint: const Color(0xFFF5F4FF),
    breakFill: oklch(0.64, 0.10, 168),
    breakText: oklch(0.38, 0.10, 168),
    breakTint: oklch(0.94, 0.03, 168),
    warningFill: oklch(0.70, 0.13, 75),
    warningText: oklch(0.40, 0.11, 75),
    warningTint: oklch(0.95, 0.035, 75),
    idle: const Color(0xFFB2B6CA),
    shadowSm: [BoxShadow(color: const Color(0xFF1E1E2D).withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1))],
  );

  static final dark = AppColors(
    background: const Color(0xFF161826),
    surface: const Color(0xFF232532),
    surface2: const Color(0xFF2B2E3D),
    text: const Color(0xFFE9E9ED),
    textMuted: const Color(0xFFE9E9ED).withValues(alpha: 0.58),
    divider: const Color(0xFFE9E9ED).withValues(alpha: 0.16),
    accentFill: const Color(0xFF9184D9),
    accentText: const Color(0xFFD2CEFD),
    accentTint: const Color(0xFF2B2741),
    breakFill: oklch(0.64, 0.10, 168),
    breakText: oklch(0.82, 0.06, 168),
    breakTint: oklch(0.24, 0.06, 168),
    warningFill: oklch(0.70, 0.13, 75),
    warningText: oklch(0.85, 0.07, 75),
    warningTint: oklch(0.26, 0.07, 75),
    idle: const Color(0xFF595D6C),
    shadowSm: [BoxShadow(color: const Color(0xFF3F424D), spreadRadius: 1)],
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? text,
    Color? textMuted,
    Color? divider,
    Color? accentFill,
    Color? accentText,
    Color? accentTint,
    Color? breakFill,
    Color? breakText,
    Color? breakTint,
    Color? warningFill,
    Color? warningText,
    Color? warningTint,
    Color? idle,
    List<BoxShadow>? shadowSm,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      accentFill: accentFill ?? this.accentFill,
      accentText: accentText ?? this.accentText,
      accentTint: accentTint ?? this.accentTint,
      breakFill: breakFill ?? this.breakFill,
      breakText: breakText ?? this.breakText,
      breakTint: breakTint ?? this.breakTint,
      warningFill: warningFill ?? this.warningFill,
      warningText: warningText ?? this.warningText,
      warningTint: warningTint ?? this.warningTint,
      idle: idle ?? this.idle,
      shadowSm: shadowSm ?? this.shadowSm,
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
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      breakFill: Color.lerp(breakFill, other.breakFill, t)!,
      breakText: Color.lerp(breakText, other.breakText, t)!,
      breakTint: Color.lerp(breakTint, other.breakTint, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
      idle: Color.lerp(idle, other.idle, t)!,
      shadowSm: shadowSm,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
