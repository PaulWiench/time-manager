import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Material 3 theme built from the Milestone 5 design handoff (Nocturne
/// system). [AppColors] carries the semantic roles the handoff defines
/// beyond stock [ColorScheme] slots (break/warning/idle, tint variants) —
/// widgets should reach for `context.colors` rather than `Theme.of(context)
/// .colorScheme` for anything role-based.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accentFill,
        brightness: brightness,
        primary: colors.accentFill,
        surface: colors.surface,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      dividerColor: colors.divider,
      extensions: [colors],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.text,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : colors.surface2,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.accentFill : colors.divider,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
