import 'package:flutter/material.dart';
import 'dart:async';

class StopwatchOverlayProvider extends ChangeNotifier {
  bool _isVisible = false;
  Offset _position = const Offset(24, 220);
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isBigStopwatchOpen = false;

  bool get isVisible => _isVisible;
  Offset get position => _position;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isBigStopwatchOpen => _isBigStopwatchOpen;

  void show({Offset? startPosition}) {
    _isVisible = true;
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
    if (startPosition != null) {
      _position = startPosition;
    }
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    _isBigStopwatchOpen = false;
    _timer?.cancel();
    _timer = null;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void reset() {
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void updatePosition(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  void setBigStopwatchOpen(bool value) {
    _isBigStopwatchOpen = value;
    notifyListeners();
  }

  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
