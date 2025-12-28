import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/avatar_modal.dart';
import '../../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'contact_screen.dart';
import 'auth_screen.dart';
import '../subscription/subscription_plans_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isPaymentVisible;

  const ProfileScreen({super.key, this.isPaymentVisible = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;
  bool _isDeletingProfile = false;

  @override
  void initState() {
    super.initState();
    // Убираем автоматическую загрузку профиля, чтобы избежать проблем с навигацией
    // Профиль будет загружен через Consumer<AuthProvider>
  }

  @override
  void dispose() {
    super.dispose();
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
        actions: [
          PopupMenuButton<_ProfileMenuAction>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2A2A2A),
            onSelected: (action) {
              switch (action) {
                case _ProfileMenuAction.deleteProfile:
                  _confirmDeleteProfile();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ProfileMenuAction.deleteProfile,
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Удалить профиль',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoadingProfile || _isRefreshing) {
            return const Center(
              child: CircularProgressIndicator(color: const Color(0xFF1F2121)),
            );
          }

          final userProfile = authProvider.userProfile;
          if (userProfile == null && !_isRefreshing) {
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
                    onPressed: () async {
                      setState(() {
                        _isRefreshing = true;
                      });

                      try {
                        final success = await authProvider
                            .refreshUserProfileSilently();
                        if (success) {
                          setState(() {});
                        }
                      } catch (e) {
                        print('Error retrying profile load: $e');
                      } finally {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          }

          // Проверяем, что профиль загружен
          if (userProfile == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1F2121)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Обновляем профиль при pull-to-refresh
              setState(() {
                _isRefreshing = true;
              });

              try {
                final success = await authProvider.refreshUserProfileSilently();
                if (success) {
                  // Принудительно обновляем UI
                  setState(() {});
                }
              } catch (e) {
                print('Error refreshing profile: $e');
              } finally {
                setState(() {
                  _isRefreshing = false;
                });
              }
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
                              child: FutureBuilder<Uint8List?>(
                                future: ApiService.getFile(
                                  userProfile.avatarUuid!,
                                  forceRefresh: true, // Принудительно обновляем
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF1F2121),
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError || !snapshot.hasData) {
                                    print(
                                      'Avatar loading error: ${snapshot.error}',
                                    );
                                    return const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    );
                                  }

                                  return Image.memory(
                                    snapshot.data!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    key: ValueKey(
                                      '${userProfile.avatarUuid}_${DateTime.now().millisecondsSinceEpoch}',
                                    ),
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

                  // Подписка (показываем весь блок в зависимости от isPaymentVisible)
                  if (widget.isPaymentVisible)
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

                  // Кнопка "Мой профиль" с увеличенной высотой
                  CustomButton(
                    text: 'Мой профиль',
                    height: 72, // Увеличиваем высоту до 72
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
                        const Divider(color: Color(0xFF3A3A3A), height: 24),
                        _buildMenuItem(
                          'Политика конфиденциальности',
                          Icons.privacy_tip_outlined,
                          () async {
                            final Uri url = Uri.parse(
                              'https://ninjatraining.ru/privacy',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Не удалось открыть ссылку'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Кнопка выхода с увеличенной высотой
                  CustomButton(
                    text: 'Выйти',
                    height: 72, // Увеличиваем высоту до 72
                    onPressed: () async {
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
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
        color = const Color(0xFF4CAF50); // Светло-зеленый
        text = 'Активна';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = const Color(0xFFFF9800); // Светло-оранжевый
        text = 'Ожидает';
        icon = Icons.pending;
        break;
      case 'expired':
        color = const Color(0xFFF44336); // Светло-красный
        text = 'Истекла';
        icon = Icons.cancel;
        break;
      default:
        color = const Color(0xFF9E9E9E); // Светло-серый
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
          // Переход на экран выбора тарифов
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionPlansScreen(),
            ),
          );
        };
        break;
      case 'active':
      case 'expired':
        buttonText = 'Продлить';
        onPressed = () {
          // Переход на экран выбора тарифов
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionPlansScreen(),
            ),
          );
        };
        break;
      default:
        buttonText = 'Подписаться';
        onPressed = () {
          // Переход на экран выбора тарифов
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionPlansScreen(),
            ),
          );
        };
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: buttonText,
        onPressed: onPressed,
        height: 64, // Увеличиваем высоту с 56 до 64
      ),
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

  // Метод для выбора фото с обработкой разрешений
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        // Сохраняем ссылку на AuthProvider до начала асинхронной операции
        final authProvider = context.read<AuthProvider>();

        final fileBytes = await image.readAsBytes();
        final fileName = image.name;
        final error = await authProvider.uploadAvatar(fileBytes, fileName);

        // Проверяем, что виджет все еще активен и контекст доступен
        if (mounted && context.mounted) {
          if (error == null) {
            // Принудительно обновляем UI после успешной загрузки
            setState(() {});

            // Дополнительная проверка перед показом SnackBar
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Фото успешно загружено',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  backgroundColor: Color(0xFF1F2121),
                ),
              );
            }
          } else {
            // Дополнительная проверка перед показом SnackBar
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
    } catch (e) {
      // Обрабатываем ошибки разрешений
      if (mounted && context.mounted) {
        String errorMessage = 'Ошибка при выборе фото';

        if (e.toString().contains('permission') ||
            e.toString().contains('denied') ||
            e.toString().contains('access')) {
          errorMessage =
              'Доступ к галерее не предоставлен. Пожалуйста, разрешите доступ в настройках приложения.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
          await _pickImageFromGallery();
        },
        onDeletePhoto: hasAvatar
            ? () async {
                // Сохраняем ссылку на AuthProvider до начала асинхронной операции
                final authProvider = context.read<AuthProvider>();
                final error = await authProvider.deleteAvatar();

                // Проверяем, что виджет все еще активен и контекст доступен
                if (mounted && context.mounted) {
                  if (error == null) {
                    // Принудительно обновляем UI после успешного удаления
                    setState(() {});

                    // Дополнительная проверка перед показом SnackBar
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Аватар успешно удален',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          backgroundColor: Color(0xFF1F2121),
                        ),
                      );
                    }
                  } else {
                    // Дополнительная проверка перед показом SnackBar
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            : null,
      ),
    );
  }

  Future<void> _confirmDeleteProfile() async {
    if (_isDeletingProfile) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Удалить профиль?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Это действие нельзя отменить. Все данные будут удалены без возможности восстановления.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteProfile();
    }
  }

  Future<void> _deleteProfile() async {
    if (_isDeletingProfile) return;

    setState(() {
      _isDeletingProfile = true;
    });

    try {
      final response = await ApiService.delete('/auth/me/');
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      } else {
        final message =
            _extractErrorMessage(response.body) ??
            'Не удалось удалить профиль. Попробуйте позже.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления профиля: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingProfile = false;
        });
      }
    }
  }

  String? _extractErrorMessage(String body) {
    try {
      final data = ApiService.decodeJson(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {
      // Игнорируем ошибки парсинга
    }
    return null;
  }
}

enum _ProfileMenuAction { deleteProfile }
