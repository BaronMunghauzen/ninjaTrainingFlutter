import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../models/user_achievement_type_model.dart';
import '../services/user_achievement_service.dart';
import '../main.dart';
import '../screens/free_workout/free_workout_screen.dart';
import '../screens/system_training/active_system_training_screen.dart';
import '../widgets/metal_card.dart';
import '../design/ninja_typography.dart';
import '../design/ninja_colors.dart';

/// Обработчик фоновых сообщений FCM
/// Должен быть функцией верхнего уровня (не в классе!)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 FCM Background: Получено фоновое сообщение');
  print('🔥 FCM Background: Title: ${message.notification?.title}');
  print('🔥 FCM Background: Body: ${message.notification?.body}');
  print('🔥 FCM Background: Data: ${message.data}');

  // Инициализируем плагин уведомлений для фонового режима
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Проверяем тип уведомления
  if (message.data.containsKey('type')) {
    final type = message.data['type'] as String;

    if (type == 'workout_cancelled') {
      // Закрываем постоянное уведомление о тренировке
      print(
        '🔥 FCM Background: Получено сообщение о завершении тренировки, закрываем уведомление',
      );
      await notificationsPlugin.cancel(
        NotificationService.workoutNotificationId,
      );
      return; // Не показываем никаких других уведомлений
    }

    if (type == 'workout_navigation' || type == 'workout_active') {
      // Показываем постоянное уведомление для тренировки
      final title = message.notification?.title ?? 'Тренировка';
      final body = message.notification?.body ?? 'Тренировка активна';
      final userTrainingUuid =
          message.data['user_training_uuid'] as String? ?? '';
      final trainingUuid = message.data['training_uuid'] as String? ?? '';
      final trainingType = message.data['training_type'] as String? ?? '';
      final payload =
          'workout_navigation:$userTrainingUuid:$trainingUuid:$trainingType';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'workout_channel',
            'Workout Notifications',
            channelDescription: 'Уведомления о активных тренировках',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            showWhen: false,
            playSound: false,
            enableVibration: false,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
          );

      final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: false, // Не показывать alert на iOS
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive, // Пассивное уведомление
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await notificationsPlugin.show(
        NotificationService.workoutNotificationId,
        title,
        body,
        details,
        payload: payload,
      );
      return;
    }
  }

  // Для остальных уведомлений показываем обычное уведомление
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

      // ВАЖНО: Сначала проверяем тип уведомления, чтобы не показывать ненужные уведомления
      if (message.data.containsKey('type')) {
        final type = message.data['type'] as String;

        if (type == 'workout_cancelled') {
          // Закрываем постоянное уведомление о тренировке
          print(
            '🔥 FCM: Получено сообщение о завершении тренировки, закрываем уведомление',
          );
          await NotificationService.cancelWorkoutNotification();
          return; // Не показываем никаких других уведомлений
        }

        if (type == 'workout_navigation' || type == 'workout_active') {
          // Показываем постоянное уведомление для тренировки
          final title = message.notification?.title ?? '';
          final body = message.notification?.body ?? '';
          final workoutTitle = title.isNotEmpty ? title : 'Тренировка';
          final workoutBody = body.isNotEmpty ? body : 'Тренировка активна';
          final userTrainingUuid =
              message.data['user_training_uuid'] as String? ?? '';
          final trainingUuid = message.data['training_uuid'] as String? ?? '';
          final trainingType = message.data['training_type'] as String? ?? '';
          final payload =
              'workout_navigation:$userTrainingUuid:$trainingUuid:$trainingType';

          await NotificationService.showWorkoutNotification(
            title: workoutTitle,
            body: workoutBody,
            payload: payload,
          );
          return;
        }
      }

      // Получаем title и body из сообщения (только для остальных типов уведомлений)
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      // Генерируем уникальный ID для уведомления
      // Для достижений используем achievement_uuid, для других - timestamp
      int? notificationId;
      if (message.data.containsKey('achievement_uuid')) {
        // Используем хэш от UUID достижения для уникального ID
        notificationId =
            message.data['achievement_uuid'].toString().hashCode.abs() %
            2147483647;
      } else {
        // Для других уведомлений используем timestamp
        notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      }

      // Извлекаем achievement_uuid если есть
      final achievementUuid = message.data.containsKey('achievement_uuid')
          ? message.data['achievement_uuid'] as String?
          : null;

      // Для всех остальных уведомлений показываем локальное уведомление с правильным текстом из FCM
      // FCM не показывает уведомления в foreground автоматически
      // ВАЖНО: Не показываем уведомление, если title и body пустые (чтобы не показывать дефолтное "Время отдыха закончилось")
      if (title.isNotEmpty || body.isNotEmpty) {
        await NotificationService.showFCMNotification(
          title: title,
          body: body,
          notificationId: notificationId,
          achievementUuid: achievementUuid,
        );
      } else {
        print(
          '🔥 FCM Foreground: Пропущено уведомление с пустыми title и body',
        );
      }
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
      final achievements = await UserAchievementService.getUserAchievements(
        userUuid,
      );
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

    // Проверяем тип уведомления
    if (data.containsKey('type')) {
      final type = data['type'] as String;

      if (type == 'workout_cancelled') {
        // Закрываем постоянное уведомление о тренировке
        print(
          '🔥 FCM: Получено сообщение о завершении тренировки, закрываем уведомление',
        );
        await NotificationService.cancelWorkoutNotification();
        return; // Не выполняем навигацию
      }

      if (type == 'workout_navigation' || type == 'workout_active') {
        // Навигация на экран тренировки
        await _handleWorkoutNavigation(data);
        return;
      }

      if (type == 'workout_timer') {
        // Обработка таймера тренировки (если понадобится)
        return;
      }
    }

    // Проверяем, есть ли achievement_uuid в данных
    if (data.containsKey('achievement_uuid')) {
      final achievementUuid = data['achievement_uuid'] as String;
      await handleAchievementTap(achievementUuid);
    }
  }

  /// Обработка навигации на тренировку (публичный метод для NotificationService)
  static Future<void> handleWorkoutNavigationTap({
    required String userTrainingUuid,
    required String trainingUuid,
    String? trainingType,
  }) async {
    print(
      '🔥 FCM: handleWorkoutNavigationTap вызван: userTrainingUuid=$userTrainingUuid, trainingUuid=$trainingUuid, trainingType=$trainingType',
    );

    // Ждем, пока приложение будет готово
    await Future.delayed(const Duration(milliseconds: 100));

    final data = {
      'user_training_uuid': userTrainingUuid,
      'training_uuid': trainingUuid,
      'training_type': trainingType,
    };
    await _handleWorkoutNavigation(data);
  }

  /// Обработка навигации на тренировку
  static Future<void> _handleWorkoutNavigation(
    Map<String, dynamic> data,
  ) async {
    final userTrainingUuid = data['user_training_uuid'] as String?;
    final trainingUuid = data['training_uuid'] as String?;
    final trainingType = data['training_type'] as String?;

    print(
      '🔥 FCM: _handleWorkoutNavigation: userTrainingUuid=$userTrainingUuid, trainingUuid=$trainingUuid, trainingType=$trainingType',
    );

    if (userTrainingUuid == null || trainingUuid == null) {
      print('🔥 FCM: ⚠️ Отсутствуют необходимые UUID для навигации');
      return;
    }

    // Пытаемся получить context несколько раз, если он не готов
    BuildContext? context;
    for (int i = 0; i < 20; i++) {
      context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        print('🔥 FCM: Context получен на попытке ${i + 1}');
        break;
      }
      print('🔥 FCM: Попытка ${i + 1}/20 получить context...');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (context == null || !context.mounted) {
      print('🔥 FCM: ⚠️ Context недоступен для навигации после ожидания');
      print('🔥 FCM: navigatorKey.currentState: ${navigatorKey.currentState}');
      return;
    }

    print('🔥 FCM: Context получен, выполняем навигацию...');

    // Определяем тип тренировки и переходим на нужный экран
    if (trainingType == 'userFree') {
      // Свободная тренировка
      print('🔥 FCM: Навигация на FreeWorkoutScreen');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FreeWorkoutScreen(
            userTrainingUuid: userTrainingUuid,
            trainingUuid: trainingUuid,
          ),
        ),
      );
      print('🔥 FCM: Навигация на FreeWorkoutScreen выполнена');
    } else {
      // Обычная тренировка - загружаем данные userTraining
      print(
        '🔥 FCM: Навигация на ActiveSystemTrainingScreen, загружаем данные...',
      );
      try {
        final response = await ApiService.get(
          '/user_trainings/$userTrainingUuid',
        );

        if (response.statusCode == 200) {
          final userTraining = ApiService.decodeJson(response.body);
          print(
            '🔥 FCM: Данные userTraining загружены, выполняем навигацию...',
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ActiveSystemTrainingScreen(userTraining: userTraining),
            ),
          );
          print('🔥 FCM: Навигация на ActiveSystemTrainingScreen выполнена');
        } else {
          print(
            '🔥 FCM: ⚠️ Ошибка загрузки userTraining: статус ${response.statusCode}',
          );
        }
      } catch (e) {
        print('🔥 FCM: ❌ Ошибка загрузки userTraining: $e');
      }
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
      isScrollControlled: false,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          child: _buildAchievementDetailModal(context, achievement),
        ),
      ),
    );
  }

  /// Построить модальное окно с деталями достижения
  static Widget _buildAchievementDetailModal(
    BuildContext context,
    UserAchievementType achievement,
  ) {
    final isEarned = achievement.isEarned;

    return MetalCard(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Картинка или знак вопроса
          if (isEarned &&
              achievement.imageUuid != null &&
              achievement.imageUuid!.isNotEmpty)
            FutureBuilder<ImageProvider?>(
              future: ApiService.getImageProvider(achievement.imageUuid!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildQuestionMark(size: 70);
                        },
                      ),
                    ),
                  );
                }
                return _buildQuestionMark(size: 70);
              },
            )
          else
            _buildQuestionMark(size: 70),
          const SizedBox(height: 12),
          // Название
          Center(
            child: Text(
              achievement.name,
              style: NinjaText.title.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Описание
          Center(
            child: Text(
              achievement.description,
              style: NinjaText.body.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // Очки
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NinjaColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: NinjaColors.accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+ ${achievement.points}',
                    style: NinjaText.section.copyWith(
                      color: NinjaColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      child: Icon(Icons.help_outline, size: size * 0.6, color: Colors.grey),
    );
  }
}
