import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_text_styles.dart';

/// Material 3 theme built from the Golden Hour handoff.
///
/// [AppColors] carries every semantic role the design names beyond stock
/// [ColorScheme] slots (the slab, break/warning/leave hues, the heatmap ramp),
/// so widgets reach for `context.colors` rather than `Theme.of(context)
/// .colorScheme`. What lives here is only what Material itself draws:
/// dialogs, sheets, switches, pickers.
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
        onPrimary: colors.onAccent,
        surface: colors.surface,
        onSurface: colors.text,
      ),
      dividerColor: colors.divider,
      extensions: [colors],
    );

    return base.copyWith(
      textTheme: _manrope(base.textTheme, colors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colors.text,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.onAccent : colors.idle,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colors.accentFill : colors.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : colors.textMuted,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(AppStroke.dash),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.slab,
        contentTextStyle: AppTextStyles.body.copyWith(color: colors.onSlab),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  /// Manrope ships as one variable font, so a weight has to be set twice: as
  /// a [FontWeight] for font matching and fallback, and as a `wght`
  /// [FontVariation] for the axis that actually moves. `TextTheme.apply`
  /// cannot carry variations, hence the explicit walk.
  static TextTheme _manrope(TextTheme base, Color color) {
    TextStyle? f(TextStyle? s) {
      if (s == null) return null;
      final weight = s.fontWeight ?? FontWeight.w400;
      return s.copyWith(
        fontFamily: AppTextStyles.family,
        color: color,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
      );
    }

    return TextTheme(
      displayLarge: f(base.displayLarge),
      displayMedium: f(base.displayMedium),
      displaySmall: f(base.displaySmall),
      headlineLarge: f(base.headlineLarge),
      headlineMedium: f(base.headlineMedium),
      headlineSmall: f(base.headlineSmall),
      titleLarge: f(base.titleLarge),
      titleMedium: f(base.titleMedium),
      titleSmall: f(base.titleSmall),
      bodyLarge: f(base.bodyLarge),
      bodyMedium: f(base.bodyMedium),
      bodySmall: f(base.bodySmall),
      labelLarge: f(base.labelLarge),
      labelMedium: f(base.labelMedium),
      labelSmall: f(base.labelSmall),
    );
  }
}
