import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../design/ninja_colors.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_spacing.dart';

class GlassCapsuleProgress extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final String label; // "Калории", "Белки", "Жиры", "Углеводы"
  final double current;
  final double target;
  final Color liquidColor;
  final bool
  isDecimal; // true для белков, жиров, углеводов (1 знак), false для калорий (0 знаков)

  const GlassCapsuleProgress({
    super.key,
    required this.progress,
    required this.label,
    required this.current,
    required this.target,
    required this.liquidColor,
    this.isDecimal = false,
  });

  @override
  State<GlassCapsuleProgress> createState() => _GlassCapsuleProgressState();
}

class _GlassCapsuleProgressState extends State<GlassCapsuleProgress>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _bubbleController;
  late AnimationController _waveController;
  late Animation<double> _fillAnimation;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _waveAnimation;

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _fillController, curve: Curves.easeOut));

    _bubbleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.linear));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _previousProgress = widget.progress;
    _fillController.value = widget.progress;

    // TODO: Добавить подписку на акселерометр для наклона (требует sensors_plus)
    // Пока используем статичные значения
  }

  @override
  void didUpdateWidget(GlassCapsuleProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _fillAnimation =
          Tween<double>(begin: _previousProgress, end: widget.progress).animate(
            CurvedAnimation(parent: _fillController, curve: Curves.easeOut),
          );
      _fillController.forward(from: 0.0);
      _previousProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _bubbleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Капсула
        SizedBox(
          width: 80,
          height: 200,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fillAnimation,
              _bubbleAnimation,
              _waveAnimation,
            ]),
            builder: (context, child) {
              return SizedBox(
                width: 80,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Фон капсулы (PNG изображение)
                    // ВАЖНО: Добавьте PNG изображение стеклянной капсулы в assets/images/glass_capsule.png
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/glass_capsule.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Если изображение не найдено, показываем контейнер-заглушку
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Жидкость
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: CustomPaint(
                          size: const Size(80, 200),
                          painter: LiquidPainter(
                            progress: _fillAnimation.value,
                            liquidColor: widget.liquidColor,
                            tiltX: _tiltX,
                            tiltY: _tiltY,
                            bubbleProgress: _bubbleAnimation.value,
                            waveProgress: _waveAnimation.value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: NinjaSpacing.sm),
        // Название и значения
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: NinjaText.caption.copyWith(
                color: NinjaColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.current.toStringAsFixed(widget.isDecimal ? 1 : 0)} / ${widget.target.toStringAsFixed(widget.isDecimal ? 1 : 0)}',
              style: NinjaText.body.copyWith(
                fontSize: 11,
                color: NinjaColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double progress;
  final Color liquidColor;
  final double tiltX;
  final double tiltY;
  final double bubbleProgress;
  final double waveProgress;

  LiquidPainter({
    required this.progress,
    required this.liquidColor,
    required this.tiltX,
    required this.tiltY,
    required this.bubbleProgress,
    required this.waveProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    // Высота жидкости с учетом наклона
    final baseHeight = size.height * progress;
    final tiltOffset = tiltX * 5; // Небольшой эффект наклона
    final liquidHeight = baseHeight + tiltOffset;

    // Нижняя часть капсулы (округлая)
    final bottomRadius = size.width / 2;
    final bottomCenter = Offset(size.width / 2, size.height - bottomRadius);

    // Верхняя часть жидкости
    final topRadius = size.width / 2;

    // Рисуем жидкость с учетом формы капсулы
    final path = Path();

    // Если жидкость не достигла верхней части капсулы
    if (liquidHeight < size.height - topRadius) {
      // Нижняя округлая часть
      path.addOval(Rect.fromCircle(center: bottomCenter, radius: bottomRadius));

      // Прямоугольная часть
      if (liquidHeight > bottomRadius) {
        path.addRect(
          Rect.fromLTWH(
            0,
            size.height - liquidHeight,
            size.width,
            liquidHeight - bottomRadius,
          ),
        );
      }
    } else {
      // Жидкость заполнила всю капсулу
      // Нижняя округлая часть
      path.addOval(Rect.fromCircle(center: bottomCenter, radius: bottomRadius));

      // Прямоугольная часть
      path.addRect(
        Rect.fromLTWH(0, topRadius, size.width, size.height - (topRadius * 2)),
      );

      // Верхняя округлая часть
      final topCenter = Offset(size.width / 2, topRadius);
      path.addOval(Rect.fromCircle(center: topCenter, radius: topRadius));
    }

    canvas.drawPath(path, paint);

    // Добавляем волны на поверхности
    if (progress > 0.1) {
      final wavePaint = Paint()
        ..color = liquidColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final waveY = size.height - liquidHeight;
      final wavePath = Path();
      for (int i = 0; i < 3; i++) {
        final waveOffset = (waveProgress * 2 * math.pi) + (i * math.pi / 2);
        final waveAmplitude = 2.0;
        final waveFrequency = 0.1;

        wavePath.reset();
        for (double x = 0; x < size.width; x += 1) {
          final y =
              waveY +
              (math.sin((x * waveFrequency) + waveOffset) * waveAmplitude);
          if (x == 0) {
            wavePath.moveTo(x, y);
          } else {
            wavePath.lineTo(x, y);
          }
        }
        canvas.drawPath(wavePath, wavePaint);
      }
    }

    // Добавляем пузырьки
    if (progress > 0.1) {
      final bubblePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final random = math.Random(42); // Фиксированный seed для стабильности
      for (int i = 0; i < 5; i++) {
        final bubbleX = random.nextDouble() * size.width;
        final bubbleY =
            size.height -
            (liquidHeight * (0.2 + random.nextDouble() * 0.6)) +
            (bubbleProgress * 10 * (random.nextDouble() - 0.5));
        final bubbleSize = 2 + random.nextDouble() * 3;

        if (bubbleY > size.height - liquidHeight &&
            bubbleY < size.height - 10) {
          canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleSize, bubblePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(LiquidPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY ||
        oldDelegate.bubbleProgress != bubbleProgress ||
        oldDelegate.waveProgress != waveProgress;
  }
}
