import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _hasEmailChanges = false;
  String _originalEmail = '';
  String? _emailError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _animationController.forward();

    // Предзаполняем поле email текущим значением из профиля
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userProfile != null) {
        _originalEmail = authProvider.userProfile!.email;
        _emailController.text = _originalEmail;
        _emailController.addListener(_onEmailChanged);
      }
    });
  }

  void _onEmailChanged() {
    final hasChanges = _emailController.text.trim() != _originalEmail;
    if (hasChanges != _hasEmailChanges) {
      setState(() {
        _hasEmailChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    // Валидация
    setState(() {
      _emailError = null;
    });

    final authProvider = context.read<AuthProvider>();
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = 'Введите email';
      });
      return;
    }

    if (!authProvider.isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = 'Введите корректный email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? error;

      if (_hasEmailChanges) {
        // Если email изменился, отправляем PUT запрос для обновления
        error = await authProvider.updateEmail(_emailController.text.trim());
      } else {
        // Если email не изменился, только обновляем информацию о пользователе
        await authProvider.fetchUserProfile();
      }

      if (error == null && mounted) {
        MetalMessage.show(
          context: context,
          message: _hasEmailChanges
              ? 'Email успешно обновлен. Проверьте почту для подтверждения.'
              : 'Информация о пользователе обновлена.',
          type: MetalMessageType.success,
        );
      } else if (error != null && mounted) {
        MetalMessage.show(
          context: context,
          message: error,
          type: MetalMessageType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка обновления email: $e',
          type: MetalMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final error = await authProvider.resendVerificationEmail(
        _emailController.text.trim(),
      );

      if (error == null && mounted) {
        MetalMessage.show(
          context: context,
          message: 'Письмо с подтверждением отправлено на вашу почту.',
          type: MetalMessageType.success,
        );
      } else if (error != null && mounted) {
        MetalMessage.show(
          context: context,
          message: error,
          type: MetalMessageType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка отправки письма: $e',
          type: MetalMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),

                    // Иконка подтверждения
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: NinjaColors.textPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 60,
                        color: NinjaColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Заголовок
                    Text(
                      'Подтвердите email',
                      style: NinjaText.title.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Описание
                    Text(
                      'Для продолжения работы с приложением необходимо подтвердить ваш email адрес. Проверьте почту и перейдите по ссылке в письме.',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Поле для изменения email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email', style: NinjaText.section),
                        const SizedBox(height: 8),
                        MetalTextField(
                          controller: _emailController,
                          hint: 'Введите новый email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (_emailError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _emailError!,
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.error,
                              ),
                            ),
                          ),
                        if (_hasEmailChanges)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: NinjaColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Email будет обновлен',
                                  style: NinjaText.caption.copyWith(
                                    color: NinjaColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Кнопка обновления email
                    MetalButton(
                      label: _hasEmailChanges
                          ? 'Обновить email'
                          : 'Обновить информацию',
                      icon: _hasEmailChanges ? Icons.email : Icons.refresh,
                      onPressed: _updateEmail,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Кнопка повторной отправки
                    MetalButton(
                      label: 'Отправить письмо повторно',
                      icon: Icons.refresh,
                      onPressed: _resendEmail,
                      isLoading: _isResending,
                    ),

                    const SizedBox(height: 16),

                    // Кнопка разлогина
                    MetalButton(
                      label: 'Выйти из аккаунта',
                      icon: Icons.logout,
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.signOut();
                      },
                    ),

                    const SizedBox(height: 32),

                    // Информация о текущем email
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.userProfile != null) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NinjaColors.metalMid.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: NinjaColors.textSecondary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Текущий email:',
                                  style: NinjaText.caption.copyWith(
                                    color: NinjaColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  authProvider.userProfile!.email,
                                  style: NinjaText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
