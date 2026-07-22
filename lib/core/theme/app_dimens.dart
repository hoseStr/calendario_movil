import 'package:flutter/widgets.dart';

/// Tokens de dimensiones de la app (RESPONSIVE_PLAN.md, Fase 0).
///
/// Punto único de verdad para espaciado, radios y márgenes de pantalla.
/// Reemplaza los números mágicos (16/20/24/28…) repartidos por las pantallas
/// para poder ajustar la densidad de forma coherente.

/// Escala de espaciado (gaps y paddings).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 32;
}

/// Radios de esquina (coherentes con DESIGN.md).
abstract final class Radii {
  static const double card = 24;
  static const double input = 16;
  static const double fab = 20;
  static const double dialog = 28;
  static const double chip = 14;
}

/// Márgenes de pantalla.
abstract final class Insets {
  /// Padding horizontal estándar de una pantalla.
  static const double screenH = 16;

  /// Espacio inferior en listas de pantallas con FAB, para que el último
  /// elemento no quede tapado por el botón flotante (FAB 56 + margen).
  static const double fabClearance = 96;

  /// Espacio inferior cómodo en listas sin FAB.
  static const double bottomGap = Gap.xxxl;
}

/// `SizedBox` reutilizables para separar widgets en columnas/filas,
/// evitando `const SizedBox(height: 12)` sueltos.
abstract final class Gaps {
  // Verticales
  static const SizedBox vXs = SizedBox(height: Gap.xs);
  static const SizedBox vSm = SizedBox(height: Gap.sm);
  static const SizedBox vMd = SizedBox(height: Gap.md);
  static const SizedBox vLg = SizedBox(height: Gap.lg);
  static const SizedBox vXl = SizedBox(height: Gap.xl);
  static const SizedBox vXxl = SizedBox(height: Gap.xxl);

  // Horizontales
  static const SizedBox hXs = SizedBox(width: Gap.xs);
  static const SizedBox hSm = SizedBox(width: Gap.sm);
  static const SizedBox hMd = SizedBox(width: Gap.md);
  static const SizedBox hLg = SizedBox(width: Gap.lg);
}
