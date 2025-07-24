import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import '../utils/global_ticker_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerOverlayProvider extends ChangeNotifier {
  bool _isVisible = false;
  Offset _position = const Offset(24, 220); // Стартовая позиция
  int? _secondsLeft;
  int? _totalSeconds;
  AnimationController? _controller;
  Timer? _timer; // Added for Timer
  bool _isBigTimerOpen = false;

  bool get isVisible => _isVisible;
  Offset get position => _position;
  int? get secondsLeft => _secondsLeft;
  int? get totalSeconds => _totalSeconds;
  AnimationController? get controller => _controller;
  bool get isBigTimerOpen => _isBigTimerOpen;

  void show(int seconds, {Offset? startPosition}) {
    // Уничтожаем старые
    _timer?.cancel();
    _timer = null;
    _controller?.dispose();
    _controller = null;

    _isVisible = true;
    _secondsLeft = seconds;
    _totalSeconds = seconds;
    _controller = AnimationController(
      vsync: GlobalTickerProvider(),
      duration: Duration(seconds: seconds),
    )..forward();

    if (startPosition != null) {
      _position = startPosition;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = seconds - _controller!.value * seconds;
      updateSecondsLeft(left.ceil());
      if (left <= 0) {
        timer.cancel();
        _playEndSound();
        hide(); // only call hide, do not dispose controller here
      }
    });
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    _isBigTimerOpen = false;
    _timer?.cancel();
    _timer = null;
    _controller?.dispose();
    _controller = null;
    notifyListeners();
  }

  void updatePosition(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  void updateSecondsLeft(int seconds) {
    _secondsLeft = seconds;
    notifyListeners();
  }

  void setBigTimerOpen(bool value) {
    _isBigTimerOpen = value;
    notifyListeners();
  }

  Future<void> _playEndSound() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/timer_end.mp3'));
    } catch (e) {
      // ignore errors
    }
  }
}
