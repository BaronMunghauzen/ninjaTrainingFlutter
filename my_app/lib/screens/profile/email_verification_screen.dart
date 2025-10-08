import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/logo_widget.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _hasEmailChanges = false;
  String _originalEmail = '';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      String? error;

      if (_hasEmailChanges) {
        // Если email изменился, отправляем PUT запрос для обновления
        error = await authProvider.updateEmail(_emailController.text.trim());
      } else {
        // Если email не изменился, только обновляем информацию о пользователе
        await authProvider.fetchUserProfile();
      }

      if (error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasEmailChanges
                  ? 'Email успешно обновлен. Проверьте почту для подтверждения.'
                  : 'Информация о пользователе обновлена.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления email: $e'),
            backgroundColor: AppColors.error,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Письмо с подтверждением отправлено на вашу почту.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки письма: $e'),
            backgroundColor: AppColors.error,
          ),
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
    return Scaffold(
      body: Stack(
        children: [
          // Фоновый градиент
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),

          // Фоновый логотип ниндзя
          const NinjaBackgroundLogo(opacity: 0.15, size: 500),

          // Основной контент
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 80),

                        // Иконка подтверждения
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            size: 60,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Заголовок
                        const Text(
                          'Подтвердите email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Описание
                        const Text(
                          'Для продолжения работы с приложением необходимо подтвердить ваш email адрес. Проверьте почту и перейдите по ссылке в письме.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Поле для изменения email
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              label: 'Email',
                              hint: 'Введите новый email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.textSecondary,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите email';
                                }
                                if (!Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                ).isValidEmail(value)) {
                                  return 'Введите корректный email';
                                }
                                return null;
                              },
                            ),
                            if (_hasEmailChanges)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Email будет обновлен',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Кнопка обновления email
                        CustomButton(
                          text: _hasEmailChanges
                              ? 'Обновить email'
                              : 'Обновить информацию',
                          onPressed: _updateEmail,
                          isLoading: _isLoading,
                          icon: _hasEmailChanges ? Icons.email : Icons.refresh,
                          height: 56,
                        ),

                        const SizedBox(height: 24),

                        // Кнопка повторной отправки
                        CustomButton(
                          text: 'Отправить письмо повторно',
                          onPressed: _resendEmail,
                          isLoading: _isResending,
                          icon: Icons.refresh,
                          height: 56,
                          isSecondary: true,
                        ),

                        const SizedBox(height: 16),

                        // Кнопка разлогина
                        CustomButton(
                          text: 'Выйти из аккаунта',
                          onPressed: () async {
                            final authProvider = context.read<AuthProvider>();
                            await authProvider.signOut();
                          },
                          icon: Icons.logout,
                          height: 56,
                          isSecondary: true,
                        ),

                        const SizedBox(height: 32),

                        // Информация о текущем email
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.userProfile != null) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Текущий email:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      authProvider.userProfile!.email,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
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
        ],
      ),
    );
  }
}
