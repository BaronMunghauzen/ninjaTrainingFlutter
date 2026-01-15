import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double phase;

  WavePainter({
    required this.color,
    required this.progress,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path();

    final waveHeight = 6.0;
    final waveLength = size.width;

    // Волны рисуются на поверхности жидкости (вверху)
    final surfaceY = 0.0;

    path.moveTo(0, surfaceY);

    for (double x = 0; x <= size.width; x++) {
      final y = surfaceY + waveHeight * math.sin((x / waveLength * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Градиент для волн - от более темного внизу к светлому вверху
    final gradient = ui.Gradient.linear(
      Offset(0, size.height), // Начало снизу
      Offset(0, 0), // Конец сверху
      [
        color.withOpacity(0.90),
        color.withOpacity(0.80),
        color.withOpacity(0.70),
      ],
      [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.phase != phase || 
           oldDelegate.color != color;
  }
}

