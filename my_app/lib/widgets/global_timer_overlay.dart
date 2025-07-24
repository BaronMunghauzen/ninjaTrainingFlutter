import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_overlay_provider.dart';
import '../../constants/app_colors.dart';
import '../main.dart';

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
              await showDialog(
                context: navigatorKey.currentState!.context,
                barrierDismissible: false,
                builder: (context) => BigRestTimerDialog(
                  total: total,
                  controller: controller,
                  onClose: () {
                    timerProvider.hide();
                    Navigator.of(context).pop();
                  },
                  onHide: () {
                    timerProvider.setBigTimerOpen(false);
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: timerProvider.controller!,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(94, 94),
                          painter: _ArcTimerPainter(
                            progress: 1 - timerProvider.controller!.value,
                            color: AppColors.accent,
                          ),
                        );
                      },
                    ),
                    Text(
                      timerProvider.secondsLeft.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
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

class _ArcTimerPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _ArcTimerPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = 10.0;
    final center = rect.center;
    final radius = (size.width - strokeWidth) / 2;
    final startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcTimerPainter old) =>
      old.progress != progress || old.color != color;
}

class BigRestTimerDialog extends StatelessWidget {
  final int total;
  final AnimationController controller;
  final VoidCallback onClose;
  final VoidCallback onHide;
  const BigRestTimerDialog({
    Key? key,
    required this.total,
    required this.controller,
    required this.onClose,
    required this.onHide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 32),
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final secondsLeft = (total - controller.value * total).ceil();
                  return Text(
                    secondsLeft.toString(),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onHide,
                child: const Text('Скрыть', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
