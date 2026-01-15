import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';
import 'forgot_password_screen.dart';
import '../main_screen_wrapper.dart';
import '../../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _loginOrEmailController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _loginOrEmailError;
  String? _emailError;
  String? _loginError;
  String? _passwordError;
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
    _loginOrEmailController.dispose();
    _emailController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _submitForm() async {
    // Валидация
    setState(() {
      _loginOrEmailError = null;
      _emailError = null;
      _loginError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool hasError = false;

    if (_isLogin) {
      if (_loginOrEmailController.text.trim().isEmpty) {
        setState(() {
          _loginOrEmailError = 'Введите логин или email';
          hasError = true;
        });
      }
      if (_passwordController.text.isEmpty) {
        setState(() {
          _passwordError = 'Введите пароль';
          hasError = true;
        });
      }
    } else {
      if (_emailController.text.trim().isEmpty) {
        setState(() {
          _emailError = 'Введите email';
          hasError = true;
        });
      } else if (!authProvider.isValidEmail(_emailController.text.trim())) {
        setState(() {
          _emailError = 'Введите корректный email';
          hasError = true;
        });
      }
      if (_loginController.text.trim().isEmpty) {
        setState(() {
          _loginError = 'Введите логин';
          hasError = true;
        });
      } else if (!authProvider.isValidLogin(_loginController.text.trim())) {
        setState(() {
          _loginError = 'Логин должен содержать минимум 3 символа';
          hasError = true;
        });
      }
      if (_passwordController.text.isEmpty) {
        setState(() {
          _passwordError = 'Введите пароль';
          hasError = true;
        });
      } else if (!authProvider.isValidPassword(_passwordController.text)) {
        setState(() {
          _passwordError = 'Пароль должен содержать минимум 6 символов';
          hasError = true;
        });
      }
      if (_confirmPasswordController.text.isEmpty) {
        setState(() {
          _confirmPasswordError = 'Подтвердите пароль';
          hasError = true;
        });
      } else if (_confirmPasswordController.text != _passwordController.text) {
        setState(() {
          _confirmPasswordError = 'Пароли не совпадают';
          hasError = true;
        });
      }
    }

    if (hasError) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      String? error;
      if (_isLogin) {
        error = await authProvider.signIn(
          _loginOrEmailController.text.trim(),
          _passwordController.text,
        );
      } else {
        error = await authProvider.signUp(
          _emailController.text.trim(),
          _loginController.text.trim(),
          _passwordController.text,
          _confirmPasswordController.text,
        );
      }
      if (error != null && mounted) {
        MetalMessage.show(
          context: context,
          message: error,
          type: MetalMessageType.error,
        );
      } else if (error == null && mounted) {
        // Если нет ошибки, значит авторизация/регистрация прошла успешно
        // AuthProvider автоматически обновит состояние и перенаправит пользователя

        // Принудительно обновляем UI
        if (mounted) {
          setState(() {});
        }

        // Дополнительная задержка для обновления UI
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {});
          }
        });

        // Принудительно обновляем главный экран через Navigator
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Принудительно перезагружаем главный экран
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainScreenWrapper(),
              ),
            );
          }
        });
      }
    } on NetworkException catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: e.message,
          type: MetalMessageType.error,
          duration: const Duration(seconds: 5),
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

  @override
  Widget build(BuildContext context) {
    return TexturedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Основной контент
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 120),

                        // Логотип "Ninja Training"
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 40),

                        Text(
                          _isLogin
                              ? 'Войдите в свой аккаунт'
                              : 'Заполните форму для регистрации',
                          style: NinjaText.body.copyWith(
                            color: NinjaColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Поле логина/email (для входа) или email (для регистрации)
                        if (_isLogin) ...[
                          Text('Логин или Email', style: NinjaText.section),
                          const SizedBox(height: 8),
                          MetalTextField(
                            controller: _loginOrEmailController,
                            hint: 'Введите логин или email',
                            keyboardType: TextInputType.text,
                          ),
                          if (_loginOrEmailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _loginOrEmailError!,
                                style: NinjaText.caption.copyWith(
                                  color: NinjaColors.error,
                                ),
                              ),
                            ),
                        ] else ...[
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

                          const SizedBox(height: 20),

                          // Поле логина (только для регистрации)
                          Text('Логин', style: NinjaText.section),
                          const SizedBox(height: 8),
                          MetalTextField(
                            controller: _loginController,
                            hint: 'Введите логин',
                            keyboardType: TextInputType.text,
                          ),
                          if (_loginError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _loginError!,
                                style: NinjaText.caption.copyWith(
                                  color: NinjaColors.error,
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 20),

                        // Поле пароля
                        Text('Пароль', style: NinjaText.section),
                        const SizedBox(height: 8),
                        MetalTextField(
                          controller: _passwordController,
                          hint: 'Введите пароль',
                          isPassword: true,
                        ),
                        if (_passwordError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _passwordError!,
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.error,
                              ),
                            ),
                          ),

                        // Поле подтверждения пароля (только для регистрации)
                        if (!_isLogin) ...[
                          const SizedBox(height: 20),
                          Text('Подтвердите пароль', style: NinjaText.section),
                          const SizedBox(height: 8),
                          MetalTextField(
                            controller: _confirmPasswordController,
                            hint: 'Повторите пароль',
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

                        // Кнопка входа/регистрации
                        MetalButton(
                          label: _isLogin ? 'Войти' : 'Зарегистрироваться',
                          icon: _isLogin ? Icons.login : Icons.person_add,
                          onPressed: _submitForm,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Кнопка "Забыли пароль?" (только для режима входа)
                        if (_isLogin) ...[
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Забыли пароль?',
                                style: NinjaText.body.copyWith(
                                  color: NinjaColors.textSecondary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Переключение режима
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Нет аккаунта? '
                                  : 'Уже есть аккаунт? ',
                              style: NinjaText.body.copyWith(
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin ? 'Зарегистрироваться' : 'Войти',
                                style: NinjaText.body.copyWith(
                                  color: NinjaColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
