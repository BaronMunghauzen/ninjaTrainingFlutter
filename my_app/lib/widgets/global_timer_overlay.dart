import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_overlay_provider.dart';
import '../main.dart';
import 'metal_modal.dart';
import 'metal_button.dart';

class GlobalTimerOverlay extends StatefulWidget {
  const GlobalTimerOverlay({Key? key}) : super(key: key);

  @override
  State<GlobalTimerOverlay> createState() => _GlobalTimerOverlayState();
}

class _GlobalTimerOverlayState extends State<GlobalTimerOverlay> {
  Offset? dragStart;
  Offset? dragPosition;

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerOverlayProvider>(
      builder: (context, timerProvider, child) {
        if (!timerProvider.isVisible ||
            timerProvider.secondsLeft == null ||
            timerProvider.controller == null ||
            timerProvider.isBigTimerOpen) {
          return const SizedBox.shrink();
        }
        final position = dragPosition ?? timerProvider.position;
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanStart: (details) {
              dragStart = details.globalPosition;
              dragPosition = timerProvider.position;
            },
            onPanUpdate: (details) {
              final newOffset = Offset(
                (timerProvider.position.dx + details.delta.dx).clamp(
                  0.0,
                  MediaQuery.of(context).size.width - 110,
                ),
                (timerProvider.position.dy + details.delta.dy).clamp(
                  0.0,
                  MediaQuery.of(context).size.height - 110,
                ),
              );
              setState(() {
                dragPosition = newOffset;
              });
              timerProvider.updatePosition(newOffset);
            },
            onPanEnd: (details) {
              dragStart = null;
              dragPosition = null;
            },
            onTap: () async {
              if (timerProvider.controller == null ||
                  timerProvider.secondsLeft == null)
                return;
              final controller = timerProvider.controller!;
              final total = timerProvider.totalSeconds!;
              timerProvider.setBigTimerOpen(
                true,
              ); // Скрыть маленький таймер (но не уничтожать)
              await MetalModal.show(
                context: navigatorKey.currentState!.context,
                title: 'Таймер отдыха',
                onClose: () {
                  timerProvider.hide();
                },
                children: [
                  _BigRestTimerContent(
                    total: total,
                    controller: controller,
                    onHide: () {
                      timerProvider.setBigTimerOpen(false);
                      Navigator.of(navigatorKey.currentState!.context).pop();
                    },
                  ),
                ],
              );
              // Восстанавливаем состояние после закрытия модалки
              timerProvider.setBigTimerOpen(false);
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Внешний металлический круг
                    Positioned.fill(
                      child: ClipOval(
                        child: Stack(
                          children: [
                            // Основной градиент (металлический)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF5E5E5E), // светлый верх
                                      Color(0xFF3E3E3E),
                                      Color(0xFF272727),
                                      Color(0xFF161616), // тёмный низ
                                    ],
                                    stops: [0.0, 0.4, 0.75, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Текстура графита
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Image.asset(
                                  'assets/textures/graphite_noise.png',
                                  fit: BoxFit.cover,
                                  color: Colors.white.withOpacity(0.08),
                                  colorBlendMode: BlendMode.softLight,
                                  filterQuality: FilterQuality.low,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Кольцо для ползунка (фон metal_modal)
                    Center(child: _MetalTrackRing()),
                    // Неоновый ползунок
                    Center(
                      child: AnimatedBuilder(
                        animation: timerProvider.controller!,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(110, 110),
                            painter: _NeonArcTimerPainter(
                              progress: 1 - timerProvider.controller!.value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Внутренний металлический круг (центр)
                    Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Stack(
                            children: [
                              // Основной градиент (металлический)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF5E5E5E), // светлый верх
                                        Color(0xFF3E3E3E),
                                        Color(0xFF272727),
                                        Color(0xFF161616), // тёмный низ
                                      ],
                                      stops: [0.0, 0.4, 0.75, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Текстура графита
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Image.asset(
                                    'assets/textures/graphite_noise.png',
                                    fit: BoxFit.cover,
                                    color: Colors.white.withOpacity(0.08),
                                    colorBlendMode: BlendMode.softLight,
                                    filterQuality: FilterQuality.low,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Текст в центре
                    Center(
                      child: Text(
                        timerProvider.secondsLeft.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Внешнее металлическое кольцо (граница)
                    Positioned.fill(child: _OuterMetalRing()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Внешнее металлическое кольцо (граница) с фоном как сердцевина
class _OuterMetalRing extends StatelessWidget {
  const _OuterMetalRing();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _OuterRingClipper(innerRadius: 45.0),
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          children: [
            // Основной градиент (металлический)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5E5E5E), // светлый верх
                      Color(0xFF3E3E3E),
                      Color(0xFF272727),
                      Color(0xFF161616), // тёмный низ
                    ],
                    stops: [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            // Текстура графита
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/textures/graphite_noise.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.08),
                  colorBlendMode: BlendMode.softLight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clipper для внешнего кольца (тонкое кольцо по краю)
class _OuterRingClipper extends CustomClipper<Path> {
  final double innerRadius;
  _OuterRingClipper({required this.innerRadius});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // Создаем путь для кольца (внешний круг минус внутренний)
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(_OuterRingClipper oldClipper) =>
      oldClipper.innerRadius != innerRadius;
}

/// Кольцо для ползунка с фоном как metal_modal
class _MetalTrackRing extends StatelessWidget {
  const _MetalTrackRing();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DonutClipper(innerRadius: 37.0),
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          children: [
            // Базовый фон
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF202020)),
              ),
            ),
            // Текстура графита
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/textures/graphite_noise.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.05),
                  colorBlendMode: BlendMode.softLight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            // Вертикальная светотень
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.16),
                        Colors.transparent,
                        Colors.black.withOpacity(0.32),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Горизонтальная светотень
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                        Colors.black.withOpacity(0.60),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Дополнительное затемнение посередине
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.60),
                        Colors.black.withOpacity(0.18),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clipper для создания кольца (donut shape)
class _DonutClipper extends CustomClipper<Path> {
  final double innerRadius;
  _DonutClipper({required this.innerRadius});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // Создаем путь для кольца (внешний круг минус внутренний)
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(_DonutClipper oldClipper) =>
      oldClipper.innerRadius != innerRadius;
}

class _NeonArcTimerPainter extends CustomPainter {
  final double progress; // 0..1
  _NeonArcTimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = 37.0; // Радиус внутреннего круга
    final trackWidth = outerRadius - innerRadius; // Ширина кольца
    final strokeWidth =
        trackWidth * 0.6; // Уменьшаем ширину ползунка до 60% от ширины кольца
    final radius = outerRadius - trackWidth / 2; // Радиус по центру кольца
    final startAngle = -3.14159 / 2; // Начинаем сверху

    if (progress <= 0) return;

    // Определяем, сколько дуг нужно нарисовать
    // Верхняя дуга - верхняя часть (примерно до 50% прогресса)
    // Нижняя дуга - нижняя часть (остальное)

    final topProgress = progress > 0.5 ? 0.5 : progress;
    final bottomProgress = progress > 0.5 ? progress - 0.5 : 0.0;

    const neonColor = Color(0xFFB7BF95); // Неоновый цвет ползунка

    // Рисуем верхнюю неоновую дугу (верхняя часть)
    if (topProgress > 0) {
      final topSweepAngle = 2 * 3.14159 * topProgress;
      final topPaint = Paint()
        ..color = neonColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          4.0,
        ); // Неоновое свечение

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        topSweepAngle,
        false,
        topPaint,
      );

      // Дополнительный слой для более яркого свечения
      final topGlowPaint = Paint()
        ..color = neonColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        topSweepAngle,
        false,
        topGlowPaint,
      );
    }

    // Рисуем нижнюю неоновую дугу (нижняя часть)
    if (bottomProgress > 0) {
      final bottomStartAngle = startAngle + (2 * 3.14159 * 0.5);
      final bottomSweepAngle = 2 * 3.14159 * bottomProgress;
      final bottomPaint = Paint()
        ..color = neonColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          4.0,
        ); // Неоновое свечение

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        bottomStartAngle,
        bottomSweepAngle,
        false,
        bottomPaint,
      );

      // Дополнительный слой для более яркого свечения
      final bottomGlowPaint = Paint()
        ..color = neonColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        bottomStartAngle,
        bottomSweepAngle,
        false,
        bottomGlowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_NeonArcTimerPainter old) => old.progress != progress;
}

/// Содержимое большого таймера отдыха
class _BigRestTimerContent extends StatelessWidget {
  final int total;
  final AnimationController controller;
  final VoidCallback onHide;

  const _BigRestTimerContent({
    required this.total,
    required this.controller,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final secondsLeft = (total - controller.value * total).ceil();
                return Text(
                  secondsLeft.toString(),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            MetalButton(label: 'Скрыть', onPressed: onHide),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
