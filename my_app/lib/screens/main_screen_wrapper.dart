import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';
import 'profile/email_verification_screen.dart';
import 'profile/auth_screen.dart';

class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({Key? key}) : super(key: key);

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Даем время AuthProvider инициализироваться
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      // Если пользователь аутентифицирован, но профиль еще не загружен,
      // загружаем его
      if (authProvider.isAuthenticated &&
          authProvider.userProfile == null &&
          !authProvider.isLoadingProfile) {
        authProvider.fetchUserProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Если пользователь не аутентифицирован, показываем экран авторизации
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // Если профиль еще загружается, показываем индикатор загрузки
        if (authProvider.isLoadingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если профиль загружен, проверяем подтверждение почты
        if (authProvider.userProfile != null) {
          // Если почта не подтверждена, показываем экран подтверждения
          if (!authProvider.isEmailVerified) {
            return const EmailVerificationScreen();
          }
        }

        // Если почта подтверждена или профиль еще не загружен, показываем главный экран
        return const MainScreen();
      },
    );
  }
}
