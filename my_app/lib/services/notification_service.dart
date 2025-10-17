import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int timerNotificationId =
      999; // ID для запланированного уведомления таймера

  static Future<void> initialize() async {
    print('🔔 NotificationService: Инициализация...');

    // Инициализация timezone
    try {
      tz.initializeTimeZones();

      // Определяем локальную таймзону по offset устройства
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetInHours = offset.inHours;

      print(
        '🔔 NotificationService: UTC offset: $offset (UTC${offsetInHours >= 0 ? '+' : ''}$offsetInHours)',
      );

      // Карта российских таймзон по UTC offset
      // Россия имеет 11 часовых поясов от UTC+2 до UTC+12
      String timeZoneName;
      switch (offsetInHours) {
        case 2:
          timeZoneName = 'Europe/Kaliningrad'; // Калининград
          break;
        case 3:
          timeZoneName = 'Europe/Moscow'; // Москва, Санкт-Петербург
          break;
        case 4:
          timeZoneName = 'Europe/Samara'; // Самара, Ижевск
          break;
        case 5:
          timeZoneName = 'Asia/Yekaterinburg'; // Екатеринбург, Пермь
          break;
        case 6:
          timeZoneName = 'Asia/Omsk'; // Омск
          break;
        case 7:
          timeZoneName = 'Asia/Novosibirsk'; // Новосибирск, Красноярск
          break;
        case 8:
          timeZoneName = 'Asia/Irkutsk'; // Иркутск, Улан-Удэ
          break;
        case 9:
          timeZoneName = 'Asia/Yakutsk'; // Якутск, Чита
          break;
        case 10:
          timeZoneName = 'Asia/Vladivostok'; // Владивосток, Хабаровск
          break;
        case 11:
          timeZoneName = 'Asia/Magadan'; // Магадан, Сахалин
          break;
        case 12:
          timeZoneName = 'Asia/Kamchatka'; // Камчатка
          break;
        default:
          // Для других таймзон или если offset не целый час
          timeZoneName = 'UTC';
          print(
            '🔔 NotificationService: ⚠️ Неизвестный offset, используем UTC',
          );
      }

      print('🔔 NotificationService: Определённая таймзона: $timeZoneName');
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      final localTimeZone = tz.local;
      print('🔔 NotificationService: Timezone установлена: $localTimeZone');

      // Дополнительная проверка: сравниваем offset установленной таймзоны с системным
      final systemOffset = DateTime.now().timeZoneOffset.inHours;
      final tzOffset = tz.TZDateTime.now(tz.local).timeZoneOffset.inHours;
      if (systemOffset != tzOffset && systemOffset != 0) {
        print('🔔 NotificationService: ⚠️ ВНИМАНИЕ: Расхождение в offset!');
        print('🔔 NotificationService: Системный offset: UTC+$systemOffset');
        print('🔔 NotificationService: Timezone offset: UTC+$tzOffset');
        print('🔔 NotificationService: На реальном устройстве это не проблема');
      }
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при инициализации timezone: $e');
      print('🔔 NotificationService: Используем таймзону по умолчанию');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    try {
      await _notificationsPlugin.initialize(initializationSettings);
      print('🔔 NotificationService: Инициализация плагина завершена');

      // Создаём notification channel для Android 8.0+ (API 26+)
      await _createNotificationChannel();

      print('🔔 NotificationService: Инициализация завершена успешно');
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при инициализации плагина: $e');
    }
  }

  /// Создание notification channel для Android 8.0+
  static Future<void> _createNotificationChannel() async {
    print('🔔 NotificationService: Создание notification channel...');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'timer_channel', // ID канала (должен совпадать с тем, что используем в уведомлениях)
      'Timer Notifications', // Название канала
      description: 'Уведомления о завершении таймера отдыха',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      print(
        '🔔 NotificationService: Notification channel создан: ${channel.id}',
      );
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при создании channel: $e');
    }
  }

  static Future<void> requestPermissions() async {
    print('🔔 NotificationService: Запрос разрешений...');

    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Запрос разрешения на уведомления
        final notificationPermission = await androidPlugin
            .requestNotificationsPermission();
        print(
          '🔔 NotificationService: Android разрешение на уведомления: $notificationPermission',
        );

        // Запрос разрешения на точные будильники (для Android 12+)
        final exactAlarmPermission = await androidPlugin
            .requestExactAlarmsPermission();
        print(
          '🔔 NotificationService: Android разрешение на точные будильники: $exactAlarmPermission',
        );

        if (exactAlarmPermission != true) {
          print(
            '🔔 NotificationService: ⚠️ ВНИМАНИЕ: Нет разрешения на точные будильники!',
          );
          print(
            '🔔 NotificationService: Запланированные уведомления могут не работать в фоне.',
          );
          print(
            '🔔 NotificationService: Откройте настройки приложения и разрешите "Точные будильники"',
          );
        }
      }

      final iosPermission = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      print('🔔 NotificationService: iOS разрешение: $iosPermission');
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при запросе разрешений: $e');
    }
  }

  /// Показать FCM уведомление (для foreground)
  static Future<void> showFCMNotification({
    required String title,
    required String body,
  }) async {
    print('🔔 NotificationService: Показ FCM уведомления (foreground)');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'timer_channel',
          'Timer Notifications',
          channelDescription: 'Уведомления о завершении таймера отдыха',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.show(
        997, // Уникальный ID для FCM уведомлений
        title,
        body,
        platformChannelSpecifics,
      );
      print('🔔 NotificationService: FCM уведомление показано успешно');
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при показе FCM уведомления: $e');
    }
  }

  /// Запланировать уведомление о завершении таймера
  static Future<void> scheduleTimerEndNotification(int seconds) async {
    print(
      '🔔 NotificationService: Планирование уведомления через $seconds секунд...',
    );

    // Проверяем разрешение на точные будильники (Android 12+)
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final canScheduleExactAlarms = await androidPlugin
            .canScheduleExactNotifications();
        print(
          '🔔 NotificationService: Можно планировать точные уведомления: $canScheduleExactAlarms',
        );

        if (canScheduleExactAlarms != true) {
          print(
            '🔔 NotificationService: ⚠️ НЕТ разрешения на точные будильники!',
          );
          print(
            '🔔 NotificationService: Уведомления в фоне НЕ будут работать.',
          );
        }
      }
    } catch (e) {
      print('🔔 NotificationService: Ошибка проверки разрешений: $e');
    }

    // Отменяем предыдущее уведомление, если оно было
    await cancelTimerNotification();

    try {
      // Используем tz.TZDateTime.now с правильной локальной таймзоной
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(Duration(seconds: seconds));

      print('🔔 NotificationService: Текущее время (${tz.local.name}): $now');
      print('🔔 NotificationService: Запланировано на: $scheduledTime');
      print('🔔 NotificationService: Через секунд: $seconds');

      const AndroidNotificationDetails
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        channelDescription: 'Уведомления о завершении таймера отдыха',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        // Важно: позволяет показывать уведомление даже если приложение закрыто
        fullScreenIntent: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.zonedSchedule(
        timerNotificationId,
        'Время отдыха закончилось!',
        'Можете приступать к следующему подходу',
        scheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print(
        '🔔 NotificationService: Уведомление запланировано успешно (ID: $timerNotificationId)',
      );

      // Проверяем, что уведомление действительно запланировано
      await _verifyScheduledNotifications();
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при планировании уведомления: $e');
      print('🔔 NotificationService: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Проверка запланированных уведомлений (для диагностики)
  static Future<void> _verifyScheduledNotifications() async {
    try {
      final pendingNotifications = await _notificationsPlugin
          .pendingNotificationRequests();
      print(
        '🔔 NotificationService: Количество запланированных уведомлений: ${pendingNotifications.length}',
      );

      for (final notification in pendingNotifications) {
        print(
          '🔔 NotificationService: - ID: ${notification.id}, Title: ${notification.title}',
        );
      }

      if (pendingNotifications.isEmpty) {
        print('🔔 NotificationService: ⚠️ НЕТ запланированных уведомлений!');
        print(
          '🔔 NotificationService: Это означает, что уведомление НЕ было запланировано системой.',
        );
        print('🔔 NotificationService: Возможные причины:');
        print('🔔 NotificationService: 1. Нет разрешения на точные будильники');
        print(
          '🔔 NotificationService: 2. Эмулятор не поддерживает запланированные уведомления',
        );
        print('🔔 NotificationService: 3. Ограничения энергосбережения');
      }
    } catch (e) {
      print(
        '🔔 NotificationService: Ошибка при проверке запланированных уведомлений: $e',
      );
    }
  }

  /// Отменить запланированное уведомление таймера
  static Future<void> cancelTimerNotification() async {
    print(
      '🔔 NotificationService: Отмена уведомления (ID: $timerNotificationId)',
    );
    try {
      await _notificationsPlugin.cancel(timerNotificationId);
      print('🔔 NotificationService: Уведомление отменено успешно');
    } catch (e) {
      print('🔔 NotificationService: ОШИБКА при отмене уведомления: $e');
      rethrow;
    }
  }
}
