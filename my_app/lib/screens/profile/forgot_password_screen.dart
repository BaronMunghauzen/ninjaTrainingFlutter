import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isTokenSent = false;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetToken() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else if (mounted) {
        setState(() {
          _isTokenSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Инструкции по сбросу пароля отправлены на ваш email',
            ),
            backgroundColor: AppColors.success,
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

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароли не совпадают'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.resetPassword(
        _emailController.text.trim(),
        _tokenController.text.trim(),
        _newPasswordController.text,
      );

      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пароль успешно изменен'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сброс пароля'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Stack(
        children: [
          // Фоновый градиент
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),

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
                        const SizedBox(height: 40),

                        // Иконка
                        const Icon(
                          Icons.lock_reset,
                          size: 80,
                          color: AppColors.textPrimary,
                        ),

                        const SizedBox(height: 24),

                        Text(
                          _isTokenSent
                              ? 'Введите код и новый пароль'
                              : 'Восстановление пароля',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _isTokenSent
                              ? 'Введите код из письма и новый пароль'
                              : 'Введите email для получения инструкций по сбросу пароля',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        if (!_isTokenSent) ...[
                          // Поле email
                          CustomTextField(
                            label: 'Email',
                            hint: 'Введите ваш email',
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
                        ] else ...[
                          // Поле кода
                          CustomTextField(
                            label: 'Код',
                            hint: 'Введите код из письма',
                            controller: _tokenController,
                            keyboardType: TextInputType.text,
                            prefixIcon: const Icon(
                              Icons.vpn_key_outlined,
                              color: AppColors.textSecondary,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите код из письма';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Поле нового пароля
                          CustomTextField(
                            label: 'Новый пароль',
                            hint: 'Введите новый пароль',
                            controller: _newPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите новый пароль';
                              }
                              if (!Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).isValidPassword(value)) {
                                return 'Пароль должен содержать минимум 6 символов';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Поле подтверждения пароля
                          CustomTextField(
                            label: 'Подтвердите пароль',
                            hint: 'Повторите новый пароль',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Подтвердите пароль';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Кнопка
                        CustomButton(
                          text: _isTokenSent
                              ? 'Сбросить пароль'
                              : 'Отправить код',
                          onPressed: _isTokenSent
                              ? _resetPassword
                              : _sendResetToken,
                          isLoading: _isLoading,
                          icon: _isTokenSent ? Icons.lock_reset : Icons.send,
                          height: 64,
                        ),

                        const SizedBox(height: 24),

                        // Кнопка "Назад"
                        TextButton(
                          onPressed: () {
                            if (_isTokenSent) {
                              setState(() {
                                _isTokenSent = false;
                                _tokenController.clear();
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                              });
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            _isTokenSent ? 'Назад' : 'Отмена',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
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
