import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/timer_overlay_provider.dart';
import 'providers/stopwatch_overlay_provider.dart';
import 'providers/achievement_provider.dart';

import 'screens/profile/auth_screen.dart';
import 'screens/main_screen_wrapper.dart';
import 'widgets/global_timer_overlay.dart';
import 'widgets/global_stopwatch_overlay.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'utils/deep_link_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase инициализирован');
  } catch (e) {
    print('❌ Ошибка инициализации Firebase: $e');
  }

  // Регистрируем обработчик фоновых FCM сообщений
  // ВАЖНО: Должен быть зарегистрирован до runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Оптимизация: инициализируем API сервис при старте
  await ApiService.initializeToken();

  // Инициализируем сервис уведомлений
  await NotificationService.initialize();

  // Инициализируем FCM
  try {
    await FCMService.initialize();
    print('✅ FCM сервис инициализирован');

    // Проверяем токен при запуске приложения
    await FCMService.checkAndUpdateToken();
    print('✅ FCM токен проверен');
  } catch (e) {
    print('❌ Ошибка инициализации FCM: $e');
  }

  // Инициализируем обработчик Deep Links
  _initDeepLinks();

  // Регистрируем обработчик 403 ответов
  _registerApiForbiddenHandler();

  runApp(const MyApp());
}

/// Инициализация обработчика Deep Links
void _initDeepLinks() {
  final appLinks = AppLinks();

  // Обработка deep link при запуске приложения (если оно было закрыто)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      DeepLinkHandler.handleDeepLink(uri.toString());
    }
  });

  // Обработка deep links когда приложение открыто
  appLinks.uriLinkStream.listen((uri) {
    DeepLinkHandler.handleDeepLink(uri.toString());
  });
}

void _registerApiForbiddenHandler() {
  ApiService.registerForbiddenHandler(() async {
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
    } catch (e) {
      print('❌ Ошибка автоматического выхода при 403: $e');
    }

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TimerOverlayProvider()),
        ChangeNotifierProvider(create: (_) => StopwatchOverlayProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Fitness App',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const GlobalTimerOverlay(),
              const GlobalStopwatchOverlay(),
            ],
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.textPrimary,
            secondary: AppColors.textPrimary,
            surface: AppColors.surface,
            onPrimary: AppColors.textPrimary,
            onSecondary: AppColors.textPrimary,
            onSurface: AppColors.textPrimary,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.inputFocused,
                width: 2,
              ),
            ),
            hintStyle: const TextStyle(color: AppColors.textHint),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Показываем индикатор загрузки во время инициализации
        if (authProvider.isLoadingProfile && authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated) {
          return const MainScreenWrapper();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
