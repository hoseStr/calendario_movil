import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/agenda_summary.dart';

/// La mascota: un blob tierno con orejitas, dibujado y animado 100% en
/// Flutter (sin assets). Respira, parpadea y cambia según su [mood].
class DreamyPet extends StatefulWidget {
  const DreamyPet({super.key, required this.mood, this.size = 160});

  final PetMood mood;
  final double size;

  @override
  State<DreamyPet> createState() => _DreamyPetState();
}

class _DreamyPetState extends State<DreamyPet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = animate ? _controller.value : 0.3;
        final mood = widget.mood;

        // Respiración y movimiento según mood.
        final breath = 1 + 0.02 * sin(2 * pi * t);
        double dy = 0;
        double dx = 0;
        switch (mood) {
          case PetMood.sleeping:
            dy = 1.5 * sin(2 * pi * t);
          case PetMood.happy:
            dy = 3 * sin(2 * pi * t);
          case PetMood.cheering:
          case PetMood.celebrating:
            dy = -8 * sin(pi * ((t * 2) % 1)).abs();
          case PetMood.hurrying:
            dx = 2.5 * sin(2 * pi * 8 * t);
        }

        // Parpadeo breve cada ~3,7 s (salvo dormida: siempre cerrado).
        final blink = mood == PetMood.sleeping ||
            ((t * 4 + 0.6) % 3.7) < 0.14;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: breath,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _PetPainter(
                mood: mood,
                t: t,
                blink: blink,
                body: isDark
                    ? const Color(0xFFB4A7E5)
                    : const Color(0xFFCEC3F0),
                outline: isDark
                    ? const Color(0xFF6F5FA8)
                    : const Color(0xFF8E7CC3),
                cheek: const Color(0xFFF2A6C8),
                face: isDark
                    ? const Color(0xFF2C2547)
                    : const Color(0xFF4A4363),
                sparkle: scheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.mood,
    required this.t,
    required this.blink,
    required this.body,
    required this.outline,
    required this.cheek,
    required this.face,
    required this.sparkle,
  });

  final PetMood mood;
  final double t;
  final bool blink;
  final Color body;
  final Color outline;
  final Color cheek;
  final Color face;
  final Color sparkle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.58);
    final bodyW = w * 0.72;
    final bodyH = h * 0.6;

    final bodyPaint = Paint()..color = body;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;

    // Orejitas (dos gotas redondeadas).
    final earY = center.dy - bodyH * 0.52;
    for (final side in [-1, 1]) {
      final earPath = Path()
        ..moveTo(center.dx + side * bodyW * 0.16, earY + h * 0.10)
        ..quadraticBezierTo(
          center.dx + side * bodyW * 0.34,
          earY - h * 0.10,
          center.dx + side * bodyW * 0.38,
          earY + h * 0.08,
        )
        ..quadraticBezierTo(
          center.dx + side * bodyW * 0.36,
          earY + h * 0.16,
          center.dx + side * bodyW * 0.16,
          earY + h * 0.14,
        )
        ..close();
      canvas.drawPath(earPath, bodyPaint);
      canvas.drawPath(earPath, outlinePaint);
    }

    // Cuerpo (blob ovalado, ligeramente aplastado abajo).
    final bodyRect =
        Rect.fromCenter(center: center, width: bodyW, height: bodyH);
    final bodyPath = Path()..addRRect(RRect.fromRectAndRadius(
        bodyRect, Radius.elliptical(bodyW * 0.5, bodyH * 0.55)));
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Bracitos animando / celebrando.
    if (mood == PetMood.cheering || mood == PetMood.celebrating) {
      final lift = h * 0.06 * sin(pi * ((t * 2) % 1)).abs();
      for (final side in [-1, 1]) {
        canvas.drawCircle(
          Offset(center.dx + side * bodyW * 0.52,
              center.dy - bodyH * 0.18 - lift),
          w * 0.055,
          bodyPaint,
        );
        canvas.drawCircle(
          Offset(center.dx + side * bodyW * 0.52,
              center.dy - bodyH * 0.18 - lift),
          w * 0.055,
          outlinePaint,
        );
      }
    }

    // Mejillas.
    final cheekPaint = Paint()..color = cheek.withValues(alpha: 0.55);
    canvas.drawCircle(
        Offset(center.dx - bodyW * 0.26, center.dy + bodyH * 0.02),
        w * 0.05, cheekPaint);
    canvas.drawCircle(
        Offset(center.dx + bodyW * 0.26, center.dy + bodyH * 0.02),
        w * 0.05, cheekPaint);

    // Ojos.
    final eyeY = center.dy - bodyH * 0.10;
    final eyeDx = bodyW * 0.17;
    final facePaint = Paint()..color = face;
    final faceStroke = Paint()
      ..color = face
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round;

    if (blink) {
      // Ojitos cerrados: arcos hacia abajo (dormida feliz).
      for (final side in [-1, 1]) {
        final ex = center.dx + side * eyeDx;
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(ex, eyeY), width: w * 0.09, height: w * 0.06),
          pi * 0.15,
          pi * 0.7,
          false,
          faceStroke,
        );
      }
    } else {
      final eyeR =
          mood == PetMood.hurrying ? w * 0.045 : w * 0.036;
      for (final side in [-1, 1]) {
        final ex = center.dx + side * eyeDx;
        canvas.drawCircle(Offset(ex, eyeY), eyeR, facePaint);
        canvas.drawCircle(
          Offset(ex + eyeR * 0.3, eyeY - eyeR * 0.35),
          eyeR * 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }

    // Boquita 'ω' (u "o" si va apurada).
    final mouthY = center.dy + bodyH * 0.08;
    if (mood == PetMood.hurrying) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(center.dx, mouthY),
            width: w * 0.05,
            height: w * 0.06),
        faceStroke,
      );
    } else {
      final m = w * 0.035;
      final mouth = Path()
        ..moveTo(center.dx - m * 2, mouthY - m * 0.3)
        ..quadraticBezierTo(
            center.dx - m, mouthY + m, center.dx, mouthY - m * 0.2)
        ..quadraticBezierTo(
            center.dx + m, mouthY + m, center.dx + m * 2, mouthY - m * 0.3);
      canvas.drawPath(mouth, faceStroke);
    }

    // Extras por mood.
    switch (mood) {
      case PetMood.sleeping:
        _paintZzz(canvas, size, center, bodyW, bodyH);
      case PetMood.celebrating:
        _paintSparkles(canvas, size, center);
      case PetMood.hurrying:
        _paintSweatDrop(canvas, size, center, bodyW, bodyH);
      case PetMood.happy:
      case PetMood.cheering:
        break;
    }
  }

  void _paintZzz(
      Canvas canvas, Size size, Offset center, double bodyW, double bodyH) {
    final rise = (t * 2) % 1;
    final alpha = (1 - rise).clamp(0.0, 1.0) * 0.8;
    final painter = TextPainter(
      text: TextSpan(
        text: 'z z Z',
        style: TextStyle(
          color: face.withValues(alpha: alpha),
          fontSize: size.width * 0.09,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx + bodyW * 0.34,
          center.dy - bodyH * 0.75 - rise * size.height * 0.10),
    );
  }

  void _paintSparkles(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = sparkle.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final angle = 2 * pi * (i / 5) + t * 2 * pi * 0.3;
      final r = size.width * 0.46;
      final p = center + Offset(cos(angle) * r, sin(angle) * r * 0.7);
      final s = size.width * 0.025 *
          (0.6 + 0.4 * sin(2 * pi * (t * 3) + i));
      canvas.drawLine(p - Offset(s, 0), p + Offset(s, 0), paint);
      canvas.drawLine(p - Offset(0, s), p + Offset(0, s), paint);
    }
  }

  void _paintSweatDrop(
      Canvas canvas, Size size, Offset center, double bodyW, double bodyH) {
    final p = Offset(
        center.dx + bodyW * 0.42, center.dy - bodyH * 0.42);
    final r = size.width * 0.03;
    final drop = Path()
      ..moveTo(p.dx, p.dy - r * 1.6)
      ..quadraticBezierTo(p.dx + r * 1.2, p.dy, p.dx, p.dy + r * 0.9)
      ..quadraticBezierTo(p.dx - r * 1.2, p.dy, p.dx, p.dy - r * 1.6)
      ..close();
    canvas.drawPath(
        drop, Paint()..color = const Color(0xFF9EC9F0).withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_PetPainter oldDelegate) => true;
}
