import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_switch.dart';
import '../../widgets/avatar_modal.dart';
import 'edit_profile_screen.dart';
import 'contact_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    // Загружаем профиль при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Профиль',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoadingProfile) {
            return const Center(
              child: CircularProgressIndicator(color: const Color(0xFF1F2121)),
            );
          }

          final userProfile = authProvider.userProfile;
          if (userProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Не удалось загрузить профиль',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Попробовать снова',
                    onPressed: () {
                      authProvider.fetchUserProfile();
                    },
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Обновляем профиль при pull-to-refresh
              await authProvider.fetchUserProfile();
            },
            color: const Color(0xFF1F2121),
            backgroundColor: const Color(0xFF2A2A2A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Аватар
                  GestureDetector(
                    onTap: () => _showAvatarModal(
                      context,
                      userProfile.avatarUuid != null,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[600],
                      ),
                      child: userProfile.avatarUuid != null
                          ? ClipOval(
                              child: Image.network(
                                'http://10.0.2.2:8000/files/file/${userProfile.avatarUuid}',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Имя пользователя
                  Text(
                    userProfile.firstName != null &&
                            userProfile.lastName != null
                        ? '${userProfile.firstName} ${userProfile.lastName}'
                        : userProfile.login,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Text(
                    userProfile.email,
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                  const SizedBox(height: 32),

                  // Подписка
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Подписка',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildSubscriptionStatus(
                              userProfile.subscriptionStatus,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (userProfile.subscriptionUntil != null) ...[
                          Text(
                            'Истекает: ${_formatDate(userProfile.subscriptionUntil!)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildSubscriptionButton(
                          userProfile.subscriptionStatus,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Кнопка "Мой профиль"
                  CustomButton(
                    text: 'Мой профиль',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Настройки
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Уведомления
                        CustomSwitch(
                          label: 'Уведомления',
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Тема
                        CustomSwitch(
                          label: 'Тема',
                          leftText: 'Светлая',
                          rightText: 'Темная',
                          value: _isDarkTheme,
                          onChanged: (value) {
                            setState(() {
                              _isDarkTheme = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Дополнительные опции
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          'Связаться с нами',
                          Icons.contact_support,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ContactScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuItem(
                          'Конфиденциальность',
                          Icons.security,
                          () {
                            // Замоканная функция
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функция в разработке'),
                                backgroundColor: Color(0xFF1F2121),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMenuItem(
                          'Политика конфиденциальности',
                          Icons.privacy_tip,
                          () {
                            // Замоканная функция
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Функция в разработке'),
                                backgroundColor: Color(0xFF1F2121),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Кнопка выхода
                  CustomButton(
                    text: 'Выйти',
                    onPressed: () async {
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      }
                    },
                    isSecondary: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Метод для отображения статуса подписки
  Widget _buildSubscriptionStatus(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'active':
        color = const Color(0xFF1F2121);
        text = 'Активна';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Ожидает';
        icon = Icons.pending;
        break;
      case 'expired':
        color = Colors.red;
        text = 'Истекла';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Неизвестно';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Метод для форматирования даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Метод для создания кнопки подписки
  Widget _buildSubscriptionButton(String status) {
    String buttonText;
    VoidCallback? onPressed;

    switch (status) {
      case 'pending':
        buttonText = 'Активировать';
        onPressed = () {
          // Замоканная функция
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функция активации подписки в разработке'),
              backgroundColor: Color(0xFF1F2121),
            ),
          );
        };
        break;
      case 'active':
      case 'expired':
        buttonText = 'Продлить';
        onPressed = () {
          // Замоканная функция
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функция продления подписки в разработке'),
              backgroundColor: Color(0xFF1F2121),
            ),
          );
        };
        break;
      default:
        buttonText = 'Подписаться';
        onPressed = () {
          // Замоканная функция
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функция подписки в разработке'),
              backgroundColor: Color(0xFF1F2121),
            ),
          );
        };
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(text: buttonText, onPressed: onPressed),
    );
  }

  // Метод для создания элементов меню
  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  // Метод для показа модального окна аватара
  void _showAvatarModal(BuildContext context, bool hasAvatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AvatarModal(
        hasAvatar: hasAvatar,
        onUploadPhoto: () async {
          // Сохраняем ссылку на AuthProvider до начала асинхронной операции
          final authProvider = context.read<AuthProvider>();

          final result = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 100,
          );
          if (result != null) {
            final fileBytes = await result.readAsBytes();
            final fileName = result.name;
            final error = await authProvider.uploadAvatar(fileBytes, fileName);
            if (mounted) {
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Фото успешно загружено',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    backgroundColor: Color(0xFF1F2121),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              }
            }
          } else {
            // Пользователь отменил выбор файла
          }
        },
        onDeletePhoto: hasAvatar
            ? () async {
                // Сохраняем ссылку на AuthProvider до начала асинхронной операции
                final authProvider = context.read<AuthProvider>();
                final error = await authProvider.deleteAvatar();

                if (mounted) {
                  if (error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Аватар успешно удален',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        backgroundColor: Color(0xFF1F2121),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }
}
