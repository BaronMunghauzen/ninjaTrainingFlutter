import 'package:flutter/material.dart';
import 'dart:async';
import '../design/ninja_typography.dart';
import '../design/ninja_colors.dart';

class WorkoutTimerWidget extends StatefulWidget {
  final DateTime startTime;

  const WorkoutTimerWidget({
    super.key,
    required this.startTime,
  });

  @override
  State<WorkoutTimerWidget> createState() => _WorkoutTimerWidgetState();
}

class _WorkoutTimerWidgetState extends State<WorkoutTimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateElapsed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final now = DateTime.now();
    final elapsed = now.difference(widget.startTime);
    if (mounted) {
      setState(() {
        _elapsed = elapsed;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_elapsed),
      style: NinjaText.body.copyWith(
        color: NinjaColors.textSecondary.withOpacity(0.7), // Полупрозрачный тон
      ),
    );
  }
}

