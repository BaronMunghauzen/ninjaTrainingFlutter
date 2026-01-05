import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import 'system_program/training_screen.dart';
import 'achievements_and_statistics/achievements_and_statistics_screen.dart';
import 'profile/profile_screen.dart';
import 'food/food_screen.dart';
import '../widgets/network_status_banner.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isPaymentVisible = true;
  bool _isFetchingSettings = false;

  @override
  void initState() {
    super.initState();
    // Загружаем профиль пользователя при инициализации главного экрана только если он еще не загружен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated &&
          authProvider.userProfile == null &&
          !authProvider.isLoadingProfile) {
        authProvider.fetchUserProfile();
      }

      // Запрашиваем разрешения на уведомления при первом запуске главного экрана
      _requestNotificationPermissions();
    });
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await NotificationService.requestPermissions();
    } catch (e) {
      // ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return NetworkStatusBanner(
      child: Scaffold(
        body: _buildCurrentScreen(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, 'assets/images/training.png', ''),
                  _buildNavItem(1, 'assets/images/food.png', ''),
                  _buildNavItem(2, 'assets/images/achivandstat.png', ''),
                  _buildNavItem(3, 'assets/images/profile.png', ''),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 28,
              height: 28,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const TrainingScreen();
      case 1:
        return const FoodScreen();
      case 2:
        return const AchievementsAndStatisticsScreen();
      case 3:
        return ProfileScreen(isPaymentVisible: _isPaymentVisible);
      default:
        return const TrainingScreen();
    }
  }

  Future<void> _onTabSelected(int index) async {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }

    if (index == 3) {
      await _loadAppSettings();
    }
  }

  /// Проверяет, является ли пользователь из России по locale устройства
  bool _isUserFromRussia() {
    final locale = ui.PlatformDispatcher.instance.locale;
    // Проверяем код страны или языка
    return locale.countryCode == 'RU' ||
        locale.languageCode == 'ru' ||
        locale.toString().toLowerCase().contains('ru');
  }

  /// Вычисляет, нужно ли показывать блок оплаты на основе настроек и страны пользователя
  bool _calculatePaymentVisibility({
    required bool isPaymentVisible,
    required bool isPaymentVisibleWorldwide,
  }) {
    // Если isPaymentVisible = false, не показывать
    if (!isPaymentVisible) {
      return false;
    }

    // Если isPaymentVisible = true и isPaymentVisibleWorldwide = true, показывать всем
    if (isPaymentVisible && isPaymentVisibleWorldwide) {
      return true;
    }

    // Если isPaymentVisible = true и isPaymentVisibleWorldwide = false,
    // показывать только для пользователей из России
    if (isPaymentVisible && !isPaymentVisibleWorldwide) {
      return _isUserFromRussia();
    }

    // По умолчанию не показывать
    return false;
  }

  Future<void> _loadAppSettings() async {
    if (_isFetchingSettings) return;

    if (mounted) {
      setState(() {
        _isFetchingSettings = true;
      });
    }

    try {
      final response = await ApiService.get('/service/settings/');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = ApiService.decodeJson(response.body);

        // Извлекаем настройки из ответа
        final appSettings = decoded is Map<String, dynamic>
            ? (decoded['app'] as Map?)
            : null;

        final bool isPaymentVisible = appSettings?['isPaymentVisible'] == true;
        final bool isPaymentVisibleWorldwide =
            appSettings?['isPaymentVisibleWorldwide'] == true;

        // Вычисляем финальное значение видимости с учетом страны пользователя
        final bool finalVisibility = _calculatePaymentVisibility(
          isPaymentVisible: isPaymentVisible,
          isPaymentVisibleWorldwide: isPaymentVisibleWorldwide,
        );

        // Логирование для отладки
        final locale = ui.PlatformDispatcher.instance.locale;
        print('💰 Payment Visibility Settings:');
        print('  isPaymentVisible: $isPaymentVisible');
        print('  isPaymentVisibleWorldwide: $isPaymentVisibleWorldwide');
        print('  User locale: ${locale.toString()}');
        print('  Is user from Russia: ${_isUserFromRussia()}');
        print('  Final visibility: $finalVisibility');

        if (mounted) {
          setState(() {
            _isPaymentVisible = finalVisibility;
            _isFetchingSettings = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isFetchingSettings = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingSettings = false;
      });
    }
  }
}
