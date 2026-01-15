import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'wave_painter.dart';
import 'bubble_painter.dart';
import '../../../../design/ninja_colors.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_spacing.dart';

// Painter для градиента жидкости
class LiquidGradientPainter extends CustomPainter {
  final Color color;
  final double progress;

  LiquidGradientPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final gradient = ui.Gradient.linear(
      Offset(0, size.height), // Начало снизу
      Offset(0, 0), // Конец сверху
      [
        // Более темный и насыщенный внизу
        color.withOpacity(0.95),
        color.withOpacity(0.88),
        color.withOpacity(0.80),
        color.withOpacity(0.72),
        // Более светлый и прозрачный вверху
        color.withOpacity(0.65),
        color.withOpacity(0.55),
      ],
      [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidGradientPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class CapsuleFill extends StatefulWidget {
  final double percent; // 0.0 – 1.0
  final Color liquidColor;
  final double width;
  final double height;
  final String label;
  final double current;
  final double target;
  final bool isDecimal;

  const CapsuleFill({
    super.key,
    required this.percent,
    required this.liquidColor,
    this.width = 80,
    this.height = 200,
    required this.label,
    required this.current,
    required this.target,
    this.isDecimal = false,
  });

  @override
  State<CapsuleFill> createState() => _CapsuleFillState();
}

class _CapsuleFillState extends State<CapsuleFill>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late AnimationController _fxController;
  late Animation<double> _fillAnim;

  double _currentPercent = 0;

  @override
  void initState() {
    super.initState();

    _currentPercent = widget.percent;

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fillAnim = Tween<double>(
      begin: 0,
      end: _currentPercent,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    ));

    _fillController.forward();
  }

  @override
  void didUpdateWidget(covariant CapsuleFill oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.percent != widget.percent) {
      _fillAnim = Tween<double>(
        begin: _currentPercent,
        end: widget.percent,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));

      _currentPercent = widget.percent;
      _fillController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _fxController.dispose();
    super.dispose();
  }

  Widget _buildLiquidLayer() {
    return AnimatedBuilder(
      animation: Listenable.merge([_fillAnim, _fxController]),
      builder: (context, child) {
        // Используем отступ для точной обрезки, чтобы жидкость не выходила за границы капсулы
        const padding = 4.0; // Отступ от краев капсулы
        
        return ClipRRect(
          borderRadius: BorderRadius.circular((widget.width - padding * 2) / 2),
          child: SizedBox(
            width: widget.width - padding * 2,
            height: widget.height - padding * 2,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Улучшенный плавный градиент жидкости
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    width: widget.width - padding * 2,
                    height: (widget.height - padding * 2) * _fillAnim.value.clamp(0.0, 1.0),
                    child: Stack(
                      children: [
                        // Плавный многоступенчатый градиент (Container как фон)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  // Более темный и насыщенный внизу
                                  widget.liquidColor.withOpacity(0.95),
                                  widget.liquidColor.withOpacity(0.88),
                                  widget.liquidColor.withOpacity(0.80),
                                  widget.liquidColor.withOpacity(0.72),
                                  // Более светлый и прозрачный вверху
                                  widget.liquidColor.withOpacity(0.65),
                                  widget.liquidColor.withOpacity(0.55),
                                ],
                                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Пузырьки (поверх градиента, но под волнами)
                        CustomPaint(
                          painter: BubblePainter(progress: _fillAnim.value),
                        ),
                        // Волны на поверхности (сверху жидкости) с градиентом
                        Align(
                          alignment: Alignment.topCenter,
                          child: CustomPaint(
                            size: Size(widget.width - padding * 2, 20), // Высота волн
                            painter: WavePainter(
                              color: widget.liquidColor,
                              progress: _fillAnim.value,
                              phase: _fxController.value * 2 * math.pi,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Жидкость (обрезана точно по форме с отступом)
              Center(
                child: _buildLiquidLayer(),
              ),
              // PNG капсула поверх (с точным выравниванием)
              Image.asset(
                'assets/images/glass_capsule.png',
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(widget.width / 2),
                      border: Border.all(
                        color: Colors.grey.shade600,
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
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

