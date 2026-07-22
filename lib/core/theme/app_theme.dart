import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Temas claro y oscuro (Material 3) con estética onírica:
/// superficies suaves, esquinas muy redondeadas y colores brumosos.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      // Densifica controles según la plataforma/pantalla.
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.nightDark : AppColors.mistLight,
      textTheme: AppTypography.textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        // Transparente para fundirse con el degradado de fondo.
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: (isDark ? AppColors.nightDark : Colors.white)
            .withValues(alpha: 0.85),
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: scheme.surface.withValues(alpha: isDark ? 0.55 : 0.75),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.fab),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface.withValues(alpha: isDark ? 0.5 : 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.input),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.dialog),
        ),
      ),
    );
  }
}
