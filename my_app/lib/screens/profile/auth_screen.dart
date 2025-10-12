import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'forgot_password_screen.dart';
import '../main_screen_wrapper.dart';
import '../../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginOrEmailController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
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
    if (!_formKey.currentState!.validate()) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Поле логина/email (для входа) или email (для регистрации)
                        if (_isLogin) ...[
                          CustomTextField(
                            label: 'Логин или Email',
                            hint: 'Введите логин или email',
                            controller: _loginOrEmailController,
                            keyboardType: TextInputType.text,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.textSecondary,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите логин или email';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
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

                          const SizedBox(height: 20),

                          // Поле логина (только для регистрации)
                          CustomTextField(
                            label: 'Логин',
                            hint: 'Введите логин',
                            controller: _loginController,
                            keyboardType: TextInputType.text,
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.textSecondary,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите логин';
                              }
                              if (!Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              ).isValidLogin(value)) {
                                return 'Логин должен содержать минимум 3 символа';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Поле пароля
                        CustomTextField(
                          label: 'Пароль',
                          hint: 'Введите пароль',
                          controller: _passwordController,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите пароль';
                            }
                            if (!_isLogin &&
                                !Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                ).isValidPassword(value)) {
                              return 'Пароль должен содержать минимум 6 символов';
                            }
                            return null;
                          },
                        ),

                        // Поле подтверждения пароля (только для регистрации)
                        if (!_isLogin) ...[
                          const SizedBox(height: 20),
                          CustomTextField(
                            label: 'Подтвердите пароль',
                            hint: 'Повторите пароль',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Подтвердите пароль';
                              }
                              if (value != _passwordController.text) {
                                return 'Пароли не совпадают';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Кнопка входа/регистрации
                        CustomButton(
                          text: _isLogin ? 'Войти' : 'Зарегистрироваться',
                          onPressed: _submitForm,
                          isLoading: _isLoading,
                          icon: _isLogin ? Icons.login : Icons.person_add,
                          height: 64,
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
                              child: const Text(
                                'Забыли пароль?',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
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
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin ? 'Зарегистрироваться' : 'Войти',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}
