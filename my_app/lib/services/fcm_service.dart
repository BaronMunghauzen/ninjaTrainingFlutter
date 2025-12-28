import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../models/user_achievement_type_model.dart';
import '../services/user_achievement_service.dart';
import '../constants/app_colors.dart';
import '../main.dart';

/// Обработчик фоновых сообщений FCM
/// Должен быть функцией верхнего уровня (не в классе!)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 FCM Background: Получено фоновое сообщение');
  print('🔥 FCM Background: Title: ${message.notification?.title}');
  print('🔥 FCM Background: Body: ${message.notification?.body}');

  // Показываем локальное уведомление
  // await NotificationService.showTimerEndNotification(); // Убираем мгновенное уведомление
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

  /// Проверить и обновить токен при необходимости
  static Future<void> checkAndUpdateToken() async {
    print('🔥 FCM: Проверка токена...');

    try {
      final currentToken = await _messaging?.getToken();

      if (currentToken != _currentToken) {
        print('🔥 FCM: Токен изменился, обновляем...');
        _currentToken = currentToken;
        if (currentToken != null) {
          await _sendTokenToServer(currentToken);
        }
      } else {
        print('🔥 FCM: Токен не изменился');
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка проверки токена: $e');
    }
  }

  /// Принудительно обновить FCM токен (игнорирует кэш)
  static Future<String?> forceRefreshToken() async {
    print('🔥 FCM: Принудительное обновление токена...');
    _currentToken = null; // Сбрасываем кэш
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
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('🔥 FCM Foreground: Получено сообщение');
      print('🔥 FCM Foreground: Title: ${message.notification?.title}');
      print('🔥 FCM Foreground: Body: ${message.notification?.body}');
      print('🔥 FCM Foreground: Data: ${message.data}');

      // Получаем title и body из сообщения
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      // Генерируем уникальный ID для уведомления
      // Для достижений используем achievement_uuid, для других - timestamp
      int? notificationId;
      if (message.data.containsKey('achievement_uuid')) {
        // Используем хэш от UUID достижения для уникального ID
        notificationId = message.data['achievement_uuid'].toString().hashCode.abs() % 2147483647;
      } else {
        // Для других уведомлений используем timestamp
        notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      }

      // Извлекаем achievement_uuid если есть
      final achievementUuid = message.data.containsKey('achievement_uuid')
          ? message.data['achievement_uuid'] as String?
          : null;

      // Для всех уведомлений показываем локальное уведомление с правильным текстом из FCM
      // FCM не показывает уведомления в foreground автоматически
      await NotificationService.showFCMNotification(
        title: title.isNotEmpty ? title : 'Время отдыха закончилось',
        body: body.isNotEmpty ? body : 'Можете приступать к следующему подходу',
        notificationId: notificationId,
        achievementUuid: achievementUuid,
      );
    });

    // Обработчик когда пользователь НАЖАЛ на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔥 FCM: Пользователь открыл приложение через уведомление');
      print('🔥 FCM: Data: ${message.data}');

      _handleNotificationTap(message);
    });

    // Проверяем, было ли приложение открыто через уведомление
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🔥 FCM: Приложение запущено через уведомление');
        print('🔥 FCM: Data: ${message.data}');
        _handleNotificationTap(message);
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

  /// Обработка нажатия на уведомление о достижении (публичный метод для NotificationService)
  static Future<void> handleAchievementTap(String achievementUuid) async {
    print('🔥 FCM: Открытие достижения: $achievementUuid');
    
    // Получаем user_uuid из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userUuid = prefs.getString('user_uuid');
    
    if (userUuid == null || userUuid.isEmpty) {
      print('🔥 FCM: ⚠️ User UUID не найден');
      return;
    }
    
    // Загружаем информацию о достижении
    try {
      final achievements = await UserAchievementService.getUserAchievements(userUuid);
      final achievement = achievements.firstWhere(
        (a) => a.uuid == achievementUuid,
        orElse: () => throw Exception('Achievement not found'),
      );
      
      // Открываем модальное окно с достижением
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        _showAchievementModal(context, achievement);
      }
    } catch (e) {
      print('🔥 FCM: ❌ Ошибка загрузки достижения: $e');
    }
  }

  /// Обработка нажатия на уведомление
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    
    // Проверяем, есть ли achievement_uuid в данных
    if (data.containsKey('achievement_uuid')) {
      final achievementUuid = data['achievement_uuid'] as String;
      await handleAchievementTap(achievementUuid);
    }
  }

  /// Показать модальное окно с достижением
  static void _showAchievementModal(
    BuildContext context,
    UserAchievementType achievement,
  ) {
    // Находим экран достижений или открываем его
    // Сначала пытаемся открыть модальное окно на текущем экране
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAchievementDetailModal(context, achievement),
    );
  }

  /// Построить модальное окно с деталями достижения
  static Widget _buildAchievementDetailModal(
    BuildContext context,
    UserAchievementType achievement,
  ) {
    final isEarned = achievement.isEarned;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Картинка или знак вопроса
          if (isEarned && achievement.imageUuid != null && achievement.imageUuid!.isNotEmpty)
            FutureBuilder<ImageProvider?>(
              future: ApiService.getImageProvider(achievement.imageUuid!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: snapshot.data!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }
                return _buildQuestionMark(size: 100);
              },
            )
          else
            _buildQuestionMark(size: 100),
          const SizedBox(height: 24),
          // Название
          Text(
            achievement.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Описание
          Text(
            achievement.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Очки
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '+ ${achievement.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _buildQuestionMark({double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.help_outline,
        size: size * 0.6,
        color: Colors.grey,
      ),
    );
  }
}
