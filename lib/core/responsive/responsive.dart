import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Helpers responsivos para teléfonos (RESPONSIVE_PLAN.md, Fase 0).
///
/// Uso:
///   context.w            // ancho de pantalla en dp
///   context.isCompact    // teléfono angosto (< 360 dp)
///   context.scale(150)   // valor que crece con la pantalla, acotado
extension ResponsiveX on BuildContext {
  /// Ancho de la pantalla en dp.
  double get w => MediaQuery.sizeOf(this).width;

  /// Alto de la pantalla en dp.
  double get h => MediaQuery.sizeOf(this).height;

  /// Inset inferior seguro (barra de gestos / navegación).
  double get safeBottom => MediaQuery.viewPaddingOf(this).bottom;

  /// Teléfono angosto: útil para densificar o reducir tamaños.
  bool get isCompact => w < 360;

  /// Escala un valor base de forma proporcional al ancho de pantalla,
  /// tomando 390 dp como referencia y acotando el factor para no
  /// sobre-escalar en pantallas grandes ni encoger de más en chicas.
  ///
  ///   context.scale(150)               // ~128–172 según el equipo
  ///   context.scale(36, max: 1.2)      // tope de crecimiento distinto
  double scale(double base, {double min = 0.85, double max = 1.15}) {
    final factor = (w / 390).clamp(min, max);
    return base * factor;
  }

  /// Como [scale] pero además nunca supera [cap] dp absolutos.
  /// Ideal para ilustraciones que no deben dominar la pantalla.
  double scaleCapped(double base, double cap,
      {double min = 0.85, double max = 1.25}) {
    return math.min(scale(base, min: min, max: max), cap);
  }
}
