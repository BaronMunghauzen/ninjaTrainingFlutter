import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stopwatch_overlay_provider.dart';
import '../constants/app_colors.dart';
import '../main.dart';

class GlobalStopwatchOverlay extends StatefulWidget {
  const GlobalStopwatchOverlay({Key? key}) : super(key: key);

  @override
  State<GlobalStopwatchOverlay> createState() => _GlobalStopwatchOverlayState();
}

class _GlobalStopwatchOverlayState extends State<GlobalStopwatchOverlay> {
  Offset? dragStart;
  Offset? dragPosition;

  @override
  Widget build(BuildContext context) {
    return Consumer<StopwatchOverlayProvider>(
      builder: (context, stopwatchProvider, child) {
        if (!stopwatchProvider.isVisible ||
            stopwatchProvider.isBigStopwatchOpen) {
          return const SizedBox.shrink();
        }
        final position = dragPosition ?? stopwatchProvider.position;
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanStart: (details) {
              dragStart = details.globalPosition;
              dragPosition = position;
            },
            onPanUpdate: (details) {
              final delta = details.globalPosition - dragStart!;
              final newPosition = Offset(
                (dragPosition!.dx + delta.dx).clamp(
                  0.0,
                  MediaQuery.of(context).size.width - 110,
                ),
                (dragPosition!.dy + delta.dy).clamp(
                  0.0,
                  MediaQuery.of(context).size.height - 110,
                ),
              );
              setState(() {
                dragPosition = newPosition;
                dragStart = details.globalPosition;
              });
            },
            onPanEnd: (details) {
              if (dragPosition != null) {
                stopwatchProvider.updatePosition(dragPosition!);
              }
              setState(() {
                dragPosition = null;
                dragStart = null;
              });
            },
            onTap: () {
              stopwatchProvider.setBigStopwatchOpen(true);
              _showBigStopwatch(context, stopwatchProvider);
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
                    CustomPaint(
                      size: const Size(94, 94),
                      painter: _ArcStopwatchPainter(
                        progress: 1.0,
                        color: AppColors.accent,
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: Stream.periodic(
                        const Duration(seconds: 1),
                        (_) => stopwatchProvider.elapsedSeconds,
                      ),
                      builder: (context, snapshot) {
                        return Text(
                          stopwatchProvider.formattedTime,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        );
                      },
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

  void _showBigStopwatch(
    BuildContext context,
    StopwatchOverlayProvider stopwatchProvider,
  ) {
    showDialog(
      context: navigatorKey.currentState!.context,
      barrierDismissible: true,
      builder: (context) =>
          _BigStopwatchModal(stopwatchProvider: stopwatchProvider),
    ).then((_) {
      stopwatchProvider.setBigStopwatchOpen(false);
    });
  }
}

class _ArcStopwatchPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcStopwatchPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_ArcStopwatchPainter oldDelegate) => false;
}

class _BigStopwatchModal extends StatefulWidget {
  final StopwatchOverlayProvider stopwatchProvider;

  const _BigStopwatchModal({Key? key, required this.stopwatchProvider})
    : super(key: key);

  @override
  State<_BigStopwatchModal> createState() => _BigStopwatchModalState();
}

class _BigStopwatchModalState extends State<_BigStopwatchModal> {
  bool _isPaused = false;

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
                    onPressed: () {
                      widget.stopwatchProvider.hide();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<int>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (_) => widget.stopwatchProvider.elapsedSeconds,
                ),
                builder: (context, snapshot) {
                  return Text(
                    widget.stopwatchProvider.formattedTime,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      size: 48,
                      color: AppColors.accent,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPaused = !_isPaused;
                        if (_isPaused) {
                          widget.stopwatchProvider.pause();
                        } else {
                          widget.stopwatchProvider.resume();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      size: 48,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      widget.stopwatchProvider.reset();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  widget.stopwatchProvider.setBigStopwatchOpen(false);
                  Navigator.of(context).pop();
                },
                child: const Text('Скрыть', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
