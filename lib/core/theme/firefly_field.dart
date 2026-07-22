import 'dart:math';

import 'package:flutter/material.dart';

/// Luciérnagas oníricas: pocas partículas con deriva lenta y parpadeo
/// suave, como polvo de hadas. Un solo ticker y RepaintBoundary para
/// no cargar la app.
class FireflyField extends StatefulWidget {
  const FireflyField({super.key, this.count = 14});

  final int count;

  @override
  State<FireflyField> createState() => _FireflyFieldState();
}

class _FireflyFieldState extends State<FireflyField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  )..repeat();

  late final List<_Firefly> _flies = List.generate(
    widget.count,
    (i) => _Firefly.random(Random(i * 31 + 7)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _FireflyPainter(
          flies: _flies,
          animation: _controller,
          isDark: isDark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Firefly {
  _Firefly({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.phase,
    required this.twinkles,
    required this.colorIndex,
  });

  factory _Firefly.random(Random r) => _Firefly(
        x: r.nextDouble(),
        y: r.nextDouble(),
        // Deriva total por ciclo (48 s): lenta, mayormente ascendente.
        vx: (r.nextDouble() - 0.5) * 0.4,
        vy: -(0.2 + r.nextDouble() * 0.5),
        size: 1.6 + r.nextDouble() * 2.2,
        phase: r.nextDouble() * 2 * pi,
        twinkles: 14 + r.nextDouble() * 22,
        colorIndex: r.nextInt(4),
      );

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final double phase;
  final double twinkles;
  final int colorIndex;
}

class _FireflyPainter extends CustomPainter {
  _FireflyPainter({
    required this.flies,
    required this.animation,
    required this.isDark,
  }) : super(repaint: animation);

  final List<_Firefly> flies;
  final Animation<double> animation;
  final bool isDark;

  // Paleta onírica (DESIGN.md): dorado luciérnaga + lila + lavanda + rosa.
  static const _darkColors = [
    Color(0xFFF4D8A0),
    Color(0xFFE8C9F0),
    Color(0xFFA99BE0),
    Color(0xFFF2A6C8),
  ];
  // Tema claro: solo morados y rosados, algo más saturados para que se noten
  // sobre el fondo pálido sin dejar de sentirse al fondo.
  static const _lightColors = [
    Color(0xFF7A5FC0), // violeta
    Color(0xFFB56CE0), // lila fuerte
    Color(0xFFE86AA8), // rosa fuerte
    Color(0xFFD86FD0), // magenta rosado
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final colors = isDark ? _darkColors : _lightColors;
    final maxAlpha = isDark ? 0.55 : 0.40;

    for (final fly in flies) {
      // Posición: deriva + vaivén lateral suave; envuelve los bordes.
      final px = _wrap(fly.x + fly.vx * t + 0.015 * sin(2 * pi * (t * 4) + fly.phase));
      final py = _wrap(fly.y + fly.vy * t);

      // Parpadeo tipo luciérnaga.
      final twinkle = 0.5 + 0.5 * sin(2 * pi * fly.twinkles * t + fly.phase);
      final alpha = maxAlpha * (0.25 + 0.75 * twinkle);

      final center = Offset(px * size.width, py * size.height);
      final color = colors[fly.colorIndex];

      // Halo difuso + núcleo.
      canvas.drawCircle(
        center,
        fly.size * 3,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        center,
        fly.size,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  double _wrap(double v) {
    final r = v % 1.0;
    return r < 0 ? r + 1.0 : r;
  }

  @override
  bool shouldRepaint(_FireflyPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
