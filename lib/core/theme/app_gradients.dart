import 'package:flutter/material.dart';

/// Degradados oníricos de fondo.
abstract final class AppGradients {
  /// Amanecer brumoso: lavanda → rosa pálido → azul niebla.
  static const LinearGradient light = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEDE7FA),
      Color(0xFFFBEFF5),
      Color(0xFFE7EFFA),
    ],
  );

  /// Noche de sueño: violeta profundo → azul medianoche.
  static const LinearGradient dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1F1838),
      Color(0xFF17132A),
      Color(0xFF141B33),
    ],
  );
}

/// Fondo degradado reutilizable para las pantallas principales.
/// Uso: `body: DreamyBackground(child: ...)`.
class DreamyBackground extends StatelessWidget {
  const DreamyBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.dark : AppGradients.light,
      ),
      child: child,
    );
  }
}
