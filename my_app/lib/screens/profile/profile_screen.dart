import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../widgets/metal_button.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';
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
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Профиль', style: NinjaText.title.copyWith(fontSize: 24)),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          actions: [
            PopupMenuButton<_ProfileMenuAction>(
              icon: const Icon(Icons.more_vert, color: NinjaColors.textPrimary),
              color: NinjaColors.metalMid,
              onSelected: (action) {
                switch (action) {
                  case _ProfileMenuAction.deleteProfile:
                    _confirmDeleteProfile();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ProfileMenuAction.deleteProfile,
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: NinjaColors.error),
                      const SizedBox(width: 12),
                      Text(
                        'Удалить профиль',
                        style: NinjaText.body.copyWith(
                          color: NinjaColors.error,
                        ),
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
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                ),
              );
            }

            final userProfile = authProvider.userProfile;
            if (userProfile == null && !_isRefreshing) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: NinjaColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Не удалось загрузить профиль',
                      style: NinjaText.title.copyWith(color: NinjaColors.error),
                    ),
                    const SizedBox(height: 16),
                    MetalButton(
                      label: 'Попробовать снова',
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
                          if (mounted) {
                            MetalMessage.show(
                              context: context,
                              message: 'Ошибка загрузки профиля: $e',
                              type: MetalMessageType.error,
                            );
                          }
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
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Обновляем профиль при pull-to-refresh
                setState(() {
                  _isRefreshing = true;
                });

                try {
                  final success = await authProvider
                      .refreshUserProfileSilently();
                  if (success) {
                    // Принудительно обновляем UI
                    setState(() {});
                  }
                } catch (e) {
                  print('Error refreshing profile: $e');
                  if (mounted) {
                    MetalMessage.show(
                      context: context,
                      message: 'Ошибка обновления профиля: $e',
                      type: MetalMessageType.error,
                    );
                  }
                } finally {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              },
              color: NinjaColors.accent,
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
                          color: NinjaColors.metalMid,
                        ),
                        child: userProfile.avatarUuid != null
                            ? ClipOval(
                                child: FutureBuilder<Uint8List?>(
                                  future: ApiService.getFile(
                                    userProfile.avatarUuid!,
                                    forceRefresh:
                                        true, // Принудительно обновляем
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                NinjaColors.accent,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      print(
                                        'Avatar loading error: ${snapshot.error}',
                                      );
                                      return const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: NinjaColors.textPrimary,
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
                                color: NinjaColors.textPrimary,
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
                      style: NinjaText.title.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),

                    // Email
                    Text(
                      userProfile.email,
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Подписка (показываем весь блок в зависимости от isPaymentVisible)
                    if (widget.isPaymentVisible)
                      MetalCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Подписка',
                                  style: NinjaText.section.copyWith(
                                    fontWeight: FontWeight.w600,
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
                                style: NinjaText.caption,
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
                    MetalButton(
                      label: 'Мой профиль',
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
                    MetalCard(
                      padding: const EdgeInsets.all(20),
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
                          const Divider(
                            color: NinjaColors.metalEdgeSoft,
                            height: 24,
                          ),
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
                                  MetalMessage.show(
                                    context: context,
                                    message: 'Не удалось открыть ссылку',
                                    type: MetalMessageType.error,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Кнопка выхода
                    MetalButton(
                      label: 'Выйти',
                      onPressed: () async {
                        await _confirmSignOut();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
        color = NinjaColors.success;
        text = 'Активна';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = NinjaColors.warning;
        text = 'Ожидает';
        icon = Icons.pending;
        break;
      case 'expired':
        color = NinjaColors.error;
        text = 'Истекла';
        icon = Icons.cancel;
        break;
      default:
        color = NinjaColors.textMuted;
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
            style: NinjaText.caption.copyWith(
              color: color,
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
      child: MetalButton(label: buttonText, onPressed: onPressed),
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
            Icon(icon, color: NinjaColors.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: NinjaText.body)),
            Icon(
              Icons.arrow_forward_ios,
              color: NinjaColors.textSecondary,
              size: 16,
            ),
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

            // Дополнительная проверка перед показом сообщения
            if (mounted && context.mounted) {
              MetalMessage.show(
                context: context,
                message: 'Фото успешно загружено',
                type: MetalMessageType.success,
              );
            }
          } else {
            // Дополнительная проверка перед показом сообщения
            if (mounted && context.mounted) {
              MetalMessage.show(
                context: context,
                message: error,
                type: MetalMessageType.error,
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

        MetalMessage.show(
          context: context,
          message: errorMessage,
          type: MetalMessageType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  // Метод для показа модального окна аватара
  void _showAvatarModal(BuildContext context, bool hasAvatar) {
    MetalModal.show(
      context: context,
      title: 'Аватар',
      children: [
        _buildAvatarOption('Загрузить фото', Icons.photo_camera, () async {
          Navigator.of(context).pop();
          await _pickImageFromGallery();
        }),
        if (hasAvatar) ...[
          const SizedBox(height: 8),
          _buildAvatarOption('Удалить фото', Icons.delete, () async {
            Navigator.of(context).pop();
            // Сохраняем ссылку на AuthProvider до начала асинхронной операции
            final authProvider = context.read<AuthProvider>();
            final error = await authProvider.deleteAvatar();

            // Проверяем, что виджет все еще активен и контекст доступен
            if (mounted && context.mounted) {
              if (error == null) {
                // Принудительно обновляем UI после успешного удаления
                setState(() {});

                // Дополнительная проверка перед показом сообщения
                if (mounted && context.mounted) {
                  MetalMessage.show(
                    context: context,
                    message: 'Аватар успешно удален',
                    type: MetalMessageType.success,
                  );
                }
              } else {
                // Дополнительная проверка перед показом сообщения
                if (mounted && context.mounted) {
                  MetalMessage.show(
                    context: context,
                    message: error,
                    type: MetalMessageType.error,
                  );
                }
              }
            }
          }, isDestructive: true),
        ],
      ],
    );
  }

  Widget _buildAvatarOption(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? NinjaColors.error.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? NinjaColors.error
                  : NinjaColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: NinjaText.body.copyWith(
                  color: isDestructive
                      ? NinjaColors.error
                      : NinjaColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await MetalModal.show<bool>(
      context: context,
      title: 'Выйти из аккаунта?',
      children: [
        Text(
          'Вы уверены, что хотите выйти из аккаунта?',
          style: NinjaText.body.copyWith(color: NinjaColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Отмена', style: NinjaText.body),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: NinjaColors.accent),
              child: Text(
                'Выйти',
                style: NinjaText.body.copyWith(
                  color: NinjaColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (shouldSignOut == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  Future<void> _confirmDeleteProfile() async {
    if (_isDeletingProfile) return;

    final shouldDelete = await MetalModal.show<bool>(
      context: context,
      title: 'Удалить профиль?',
      children: [
        Text(
          'Это действие нельзя отменить. Все данные будут удалены без возможности восстановления.',
          style: NinjaText.body.copyWith(color: NinjaColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MetalButton(
              label: 'Отмена',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 16),
            MetalButton(
              label: 'Удалить',
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ],
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
        MetalMessage.show(
          context: context,
          message: message,
          type: MetalMessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      MetalMessage.show(
        context: context,
        message: 'Ошибка удаления профиля: $e',
        type: MetalMessageType.error,
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
