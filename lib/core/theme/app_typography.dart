import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía de la app: Quicksand (redondeada, suave) para todo,
/// acorde con la estética onírica. Si quieres otra fuente,
/// solo se cambia aquí.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final quicksand = GoogleFonts.quicksandTextTheme(base);
    return quicksand.copyWith(
      headlineMedium: quicksand.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: quicksand.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: quicksand.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: quicksand.bodyMedium?.copyWith(
        height: 1.45,
      ),
      labelSmall: quicksand.labelSmall?.copyWith(
        letterSpacing: 0.5,
      ),
    );
  }
}
