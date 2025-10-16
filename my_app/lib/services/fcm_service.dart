import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Обработчик фоновых сообщений FCM
/// Должен быть функцией верхнего уровня (не в классе!)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 FCM Background: Получено фоновое сообщение');
  print('🔥 FCM Background: Title: ${message.notification?.title}');
  print('🔥 FCM Background: Body: ${message.notification?.body}');

  // Показываем локальное уведомление
  await NotificationService.showTimerEndNotification();
}

/// Сервис для работы с Firebase Cloud Messaging
class FCMService {
  static FirebaseMessaging? _messaging;
  static String? _currentToken;

  /// Инициализация FCM
  static Future<void> initialize() async {
    print('🔥 FCM: Инициализация...');

    try {
      _messaging = FirebaseMessaging.instance;

      // Запрашиваем разрешение на уведомления
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔥 FCM: Разрешение: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('🔥 FCM: Разрешение получено');

        // Получаем FCM токен
        await _refreshToken();

        // Настраиваем обработчики сообщений
        _setupMessageHandlers();

        // Слушаем обновления токена
        _messaging!.onTokenRefresh.listen((newToken) {
          print('🔥 FCM: Токен обновлен');
          _currentToken = newToken;
          _sendTokenToServer(newToken);
        });
      } else {
        print('🔥 FCM: ⚠️ Разрешение не получено');
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка инициализации: $e');
    }
  }

  /// Получить FCM токен
  static Future<String?> getToken() async {
    if (_currentToken != null) {
      return _currentToken;
    }

    return await _refreshToken();
  }

  /// Обновить FCM токен
  static Future<String?> _refreshToken() async {
    try {
      final token = await _messaging?.getToken();
      print('🔥 FCM: Токен получен: ${token?.substring(0, 20)}...');
      _currentToken = token;

      // Отправляем токен на сервер
      if (token != null) {
        await _sendTokenToServer(token);
      }

      return token;
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка получения токена: $e');
      return null;
    }
  }

  /// Отправить токен на backend
  static Future<void> _sendTokenToServer(
    String token, {
    String? userUuid,
  }) async {
    print('🔥 FCM: Отправка токена на сервер...');

    try {
      // Если userUuid не передан, пытаемся получить из SharedPreferences
      String? uuid = userUuid;
      if (uuid == null) {
        final prefs = await SharedPreferences.getInstance();
        uuid = prefs.getString('user_uuid');
      }

      if (uuid == null || uuid.isEmpty) {
        print('🔥 FCM: ⚠️ User UUID не найден, пропускаем отправку токена');
        return;
      }

      final response = await ApiService.post(
        '/notifications/update-fcm-token',
        body: {'user_uuid': uuid, 'fcm_token': token},
      );

      if (response.statusCode == 200) {
        print('🔥 FCM: ✅ Токен отправлен на сервер');
      } else {
        print('🔥 FCM: ⚠️ Не удалось отправить токен: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка отправки токена на сервер: $e');
    }
  }

  /// Настройка обработчиков сообщений
  static void _setupMessageHandlers() {
    // Обработчик когда приложение ОТКРЫТО (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔥 FCM Foreground: Получено сообщение');
      print('🔥 FCM Foreground: Title: ${message.notification?.title}');
      print('🔥 FCM Foreground: Body: ${message.notification?.body}');

      // Показываем локальное уведомление
      NotificationService.showTimerEndNotification();
    });

    // Обработчик когда пользователь НАЖАЛ на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔥 FCM: Пользователь открыл приложение через уведомление');
      print('🔥 FCM: Data: ${message.data}');

      // Здесь можно добавить навигацию к нужному экрану
      // Например, если в data есть exercise_uuid - открыть это упражнение
    });

    // Проверяем, было ли приложение открыто через уведомление
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🔥 FCM: Приложение запущено через уведомление');
        print('🔥 FCM: Data: ${message.data}');
      }
    });
  }

  /// Запланировать таймер на backend
  static Future<void> scheduleTimerOnBackend({
    required String userUuid,
    required String exerciseUuid,
    required String exerciseName,
    required int durationSeconds,
  }) async {
    print('🔥 FCM: Планирование таймера на backend ($durationSeconds сек)...');

    try {
      final response = await ApiService.post(
        '/notifications/schedule-timer',
        body: {
          'user_uuid': userUuid,
          'exercise_uuid': exerciseUuid,
          'exercise_name': exerciseName,
          'duration_seconds': durationSeconds,
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        print('🔥 FCM: ✅ Таймер запланирован на backend');
        print('🔥 FCM: Job ID: ${data['job_id']}');
        print('🔥 FCM: Scheduled time: ${data['scheduled_time']}');
      } else {
        print('🔥 FCM: ⚠️ Не удалось запланировать: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка планирования таймера: $e');
    }
  }

  /// Отменить таймер на backend
  static Future<void> cancelTimerOnBackend({required String userUuid}) async {
    print('🔥 FCM: Отмена таймера на backend...');

    try {
      final response = await ApiService.post(
        '/notifications/cancel-timer',
        body: {'user_uuid': userUuid},
      );

      if (response.statusCode == 200) {
        print('🔥 FCM: ✅ Таймер отменен на backend');
      } else {
        print('🔥 FCM: ⚠️ Не удалось отменить: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка отмены таймера: $e');
    }
  }

  /// Тестовая отправка уведомления
  static Future<void> sendTestNotification(String userUuid) async {
    print('🔥 FCM: Отправка тестового уведомления...');

    try {
      final response = await ApiService.post(
        '/notifications/test-notification?user_uuid=$userUuid',
      );

      if (response.statusCode == 200) {
        print('🔥 FCM: ✅ Тестовое уведомление отправлено');
      } else {
        print('🔥 FCM: ⚠️ Ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка отправки тестового уведомления: $e');
    }
  }
}
