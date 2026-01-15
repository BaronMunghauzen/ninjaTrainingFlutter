import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isTokenSent = false;
  String? _emailError;
  String? _tokenError;
  String? _newPasswordError;
  String? _confirmPasswordError;
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
    // Валидация
    setState(() {
      _emailError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
      final error = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (error != null && mounted) {
        MetalMessage.show(
          context: context,
          message: error,
          type: MetalMessageType.error,
        );
      } else if (mounted) {
        setState(() {
          _isTokenSent = true;
        });
        MetalMessage.show(
          context: context,
          message: 'Инструкции по сбросу пароля отправлены на ваш email',
          type: MetalMessageType.success,
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
    // Валидация
    setState(() {
      _tokenError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool hasError = false;

    if (_tokenController.text.trim().isEmpty) {
      setState(() {
        _tokenError = 'Введите код из письма';
        hasError = true;
      });
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _newPasswordError = 'Введите новый пароль';
        hasError = true;
      });
    } else if (!authProvider.isValidPassword(_newPasswordController.text)) {
      setState(() {
        _newPasswordError = 'Пароль должен содержать минимум 6 символов';
        hasError = true;
      });
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Подтвердите пароль';
        hasError = true;
      });
    } else if (_confirmPasswordController.text != _newPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Пароли не совпадают';
        hasError = true;
      });
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final error = await authProvider.resetPassword(
        _emailController.text.trim(),
        _tokenController.text.trim(),
        _newPasswordController.text,
      );

      if (error != null && mounted) {
        MetalMessage.show(
          context: context,
          message: error,
          type: MetalMessageType.error,
        );
      } else if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пароль успешно изменен',
          type: MetalMessageType.success,
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
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const MetalBackButton(),
          title: Text(
            'Сброс пароля',
            style: NinjaText.title.copyWith(fontSize: 20),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
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
                    const SizedBox(height: 40),

                    // Иконка
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: NinjaColors.textPrimary,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _isTokenSent
                          ? 'Введите код и новый пароль'
                          : 'Восстановление пароля',
                      style: NinjaText.title.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      _isTokenSent
                          ? 'Введите код из письма и новый пароль'
                          : 'Введите email для получения инструкций по сбросу пароля',
                      style: NinjaText.body.copyWith(
                        color: NinjaColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    if (!_isTokenSent) ...[
                      // Поле email
                      Text('Email', style: NinjaText.section),
                      const SizedBox(height: 8),
                      MetalTextField(
                        controller: _emailController,
                        hint: 'Введите ваш email',
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
                    ] else ...[
                      // Поле кода
                      Text('Код', style: NinjaText.section),
                      const SizedBox(height: 8),
                      MetalTextField(
                        controller: _tokenController,
                        hint: 'Введите код из письма',
                        keyboardType: TextInputType.text,
                      ),
                      if (_tokenError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _tokenError!,
                            style: NinjaText.caption.copyWith(
                              color: NinjaColors.error,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Поле нового пароля
                      Text('Новый пароль', style: NinjaText.section),
                      const SizedBox(height: 8),
                      MetalTextField(
                        controller: _newPasswordController,
                        hint: 'Введите новый пароль',
                        isPassword: true,
                      ),
                      if (_newPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _newPasswordError!,
                            style: NinjaText.caption.copyWith(
                              color: NinjaColors.error,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Поле подтверждения пароля
                      Text('Подтвердите пароль', style: NinjaText.section),
                      const SizedBox(height: 8),
                      MetalTextField(
                        controller: _confirmPasswordController,
                        hint: 'Повторите новый пароль',
                        isPassword: true,
                      ),
                      if (_confirmPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _confirmPasswordError!,
                            style: NinjaText.caption.copyWith(
                              color: NinjaColors.error,
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 32),

                    // Кнопка
                    MetalButton(
                      label: _isTokenSent
                          ? 'Сбросить пароль'
                          : 'Отправить код',
                      icon: _isTokenSent ? Icons.lock_reset : Icons.send,
                      onPressed: _isTokenSent
                          ? _resetPassword
                          : _sendResetToken,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Кнопка "Назад"/"Отмена"
                    MetalButton(
                      label: _isTokenSent ? 'Назад' : 'Отмена',
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
