import 'dart:math' as math;
import 'package:flutter/material.dart';

class Bubble {
  double x;
  double y;
  double radius;
  double speed;

  Bubble(this.x, this.y, this.radius, this.speed);
}

class BubblePainter extends CustomPainter {
  final double progress;
  final List<Bubble> bubbles;
  final math.Random _random = math.Random();

  BubblePainter({required this.progress}) : bubbles = [] {
    // Инициализируем пузырьки в области жидкости
    for (int i = 0; i < 12; i++) {
      bubbles.add(_randomBubble());
    }
  }

  Bubble _randomBubble() {
    // Пузырьки начинаются внизу (y близко к 1.0) и поднимаются вверх
    return Bubble(
      _random.nextDouble(), // x позиция (0.0 - 1.0)
      0.7 + _random.nextDouble() * 0.3, // y позиция (начинаем внизу)
      2 + _random.nextDouble() * 3, // радиус
      0.002 + _random.nextDouble() * 0.003, // скорость подъема
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final liquidTop = size.height * (1 - progress);

    for (final b in bubbles) {
      // Обновляем позицию пузырька
      b.y -= b.speed;

      // Если пузырек вышел за верх жидкости, создаем новый внизу
      if (b.y < 0.05) {
        final nb = _randomBubble();
        b
          ..x = nb.x
          ..y = 0.95 + nb.y * 0.05 // Начинаем внизу жидкости
          ..radius = nb.radius
          ..speed = nb.speed;
      }

      final dx = b.x * size.width;
      final dy = b.y * size.height;

      // Показываем пузырьки только в области жидкости (от низа до верха жидкости)
      if (dy >= liquidTop && dy <= size.height) {
        canvas.drawCircle(Offset(dx, dy), b.radius, paint);
      } else if (dy > size.height) {
        // Если пузырек ниже дна, перемещаем его вниз жидкости
        b.y = 0.95;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

