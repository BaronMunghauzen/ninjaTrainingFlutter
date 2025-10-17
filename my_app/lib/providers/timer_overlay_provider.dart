import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import '../utils/global_ticker_provider.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';

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

  void show(
    int seconds, {
    Offset? startPosition,
    String? userUuid,
    String? exerciseUuid,
    String? exerciseName,
  }) {
    print('⏱️ TimerOverlayProvider: Запуск таймера на $seconds секунд');

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

    // Планируем уведомление сразу при запуске таймера
    // Оно сработает даже если приложение будет закрыто
    print('⏱️ TimerOverlayProvider: Планирование уведомления...');
    _scheduleNotification(seconds);

    // НОВОЕ: Планируем уведомление на backend через FCM (более надежно!)
    if (userUuid != null && exerciseUuid != null && exerciseName != null) {
      print(
        '⏱️ TimerOverlayProvider: Планирование таймера на backend через FCM...',
      );
      _scheduleNotificationOnBackend(
        userUuid: userUuid,
        exerciseUuid: exerciseUuid,
        exerciseName: exerciseName,
        durationSeconds: seconds,
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = seconds - _controller!.value * seconds;
      updateSecondsLeft(left.ceil());
      if (left <= 0) {
        print('⏱️ TimerOverlayProvider: Таймер завершен!');
        timer.cancel();
        // Убираем мгновенное уведомление - теперь только FCM уведомления
        _hideWithoutCancellingNotification(); // Скрываем таймер БЕЗ отмены уведомления
      }
    });
    notifyListeners();
  }

  void hide({String? userUuid}) {
    print('⏱️ TimerOverlayProvider: Скрытие таймера (с отменой уведомления)');
    _isVisible = false;
    _isBigTimerOpen = false;
    _timer?.cancel();
    _timer = null;
    _controller?.dispose();
    _controller = null;
    // Отменяем запланированное уведомление, если таймер скрыли до завершения
    print('⏱️ TimerOverlayProvider: Отмена запланированного уведомления...');
    _cancelScheduledNotification();

    // Отменяем на backend тоже
    if (userUuid != null && userUuid.isNotEmpty) {
      _cancelNotificationOnBackend(userUuid);
    }

    notifyListeners();
  }

  void _hideWithoutCancellingNotification() {
    print('⏱️ TimerOverlayProvider: Скрытие таймера (БЕЗ отмены уведомления)');
    _isVisible = false;
    _isBigTimerOpen = false;
    _timer?.cancel();
    _timer = null;
    _controller?.dispose();
    _controller = null;
    // НЕ отменяем уведомление - пусть пользователь увидит его!
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

  Future<void> _scheduleNotification(int seconds) async {
    try {
      print(
        '⏱️ TimerOverlayProvider: Вызов scheduleTimerEndNotification($seconds)',
      );
      await NotificationService.scheduleTimerEndNotification(seconds);
      print('⏱️ TimerOverlayProvider: scheduleTimerEndNotification() завершен');
    } catch (e) {
      print('⏱️ TimerOverlayProvider: ОШИБКА при планировании уведомления: $e');
    }
  }

  Future<void> _cancelScheduledNotification() async {
    try {
      print('⏱️ TimerOverlayProvider: Вызов cancelTimerNotification()');
      await NotificationService.cancelTimerNotification();
      print('⏱️ TimerOverlayProvider: cancelTimerNotification() завершен');
    } catch (e) {
      print('⏱️ TimerOverlayProvider: ОШИБКА при отмене уведомления: $e');
    }
  }

  /// Планирование уведомления на backend через FCM
  Future<void> _scheduleNotificationOnBackend({
    required String userUuid,
    required String exerciseUuid,
    required String exerciseName,
    required int durationSeconds,
  }) async {
    try {
      print('⏱️ TimerOverlayProvider: Отправка на backend...');
      await FCMService.scheduleTimerOnBackend(
        userUuid: userUuid,
        exerciseUuid: exerciseUuid,
        exerciseName: exerciseName,
        durationSeconds: durationSeconds,
      );
      print('⏱️ TimerOverlayProvider: ✅ Таймер запланирован на backend');
    } catch (e) {
      print(
        '⏱️ TimerOverlayProvider: ⚠️ Не удалось запланировать на backend: $e',
      );
      // Не критично - локальное уведомление все равно сработает
    }
  }

  /// Отмена уведомления на backend
  Future<void> _cancelNotificationOnBackend(String userUuid) async {
    try {
      print('⏱️ TimerOverlayProvider: Отмена на backend...');
      await FCMService.cancelTimerOnBackend(userUuid: userUuid);
      print('⏱️ TimerOverlayProvider: ✅ Таймер отменен на backend');
    } catch (e) {
      print('⏱️ TimerOverlayProvider: ⚠️ Не удалось отменить на backend: $e');
    }
  }
}
