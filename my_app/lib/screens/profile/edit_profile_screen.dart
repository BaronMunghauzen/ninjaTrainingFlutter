import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_dropdown.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _loginController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _descriptionController;
  String? _selectedGender;
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _emailError;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final userProfile = context.read<AuthProvider>().userProfile;
    if (userProfile != null) {
      _emailController = TextEditingController(text: userProfile.email);
      _phoneController = TextEditingController(
        text: userProfile.phoneNumber ?? '',
      );
      _loginController = TextEditingController(text: userProfile.login);
      _firstNameController = TextEditingController(
        text: userProfile.firstName ?? '',
      );
      _lastNameController = TextEditingController(
        text: userProfile.lastName ?? '',
      );
      _middleNameController = TextEditingController(
        text: userProfile.middleName ?? '',
      );
      _descriptionController = TextEditingController(
        text: userProfile.description ?? '',
      );
      _selectedGender = userProfile.gender;
    } else {
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _loginController = TextEditingController();
      _firstNameController = TextEditingController();
      _lastNameController = TextEditingController();
      _middleNameController = TextEditingController();
      _descriptionController = TextEditingController();
    }

    // Добавляем слушатели для отслеживания изменений
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _loginController.addListener(_onFieldChanged);
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _middleNameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final userProfile = context.read<AuthProvider>().userProfile;
    if (userProfile != null) {
      final hasChanges =
          _emailController.text != userProfile.email ||
          _phoneController.text != (userProfile.phoneNumber ?? '') ||
          _loginController.text != userProfile.login ||
          _firstNameController.text != (userProfile.firstName ?? '') ||
          _lastNameController.text != (userProfile.lastName ?? '') ||
          _middleNameController.text != (userProfile.middleName ?? '') ||
          _descriptionController.text != (userProfile.description ?? '') ||
          _selectedGender != userProfile.gender;

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    // Валидация
    setState(() {
      _emailError = null;
      _loginError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email обязателен';
      });
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Введите корректный email';
      });
    }

    if (_loginController.text.isEmpty) {
      setState(() {
        _loginError = 'Логин обязателен';
      });
    } else if (_loginController.text.length < 3) {
      setState(() {
        _loginError = 'Логин должен содержать минимум 3 символа';
      });
    }

    if (_emailError != null || _loginError != null) {
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.updateUserProfile(
      username: _loginController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      firstName: _firstNameController.text.trim().isEmpty
          ? null
          : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      gender: _selectedGender,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }

    if (mounted) {
      if (error == null) {
        MetalMessage.show(
          context: context,
          message: 'Профиль успешно обновлен',
          type: MetalMessageType.success,
        );
        Navigator.pop(context);
      } else {
        MetalMessage.show(
          context: context,
          message: error,
          type: MetalMessageType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _loginController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            'Редактировать профиль',
            style: NinjaText.title.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_hasChanges && !_isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: MetalBackButton(
                  icon: Icons.check,
                  onTap: _saveProfile,
                ),
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        NinjaColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final userProfile = authProvider.userProfile;
            if (userProfile == null) {
              return Center(
                child: Text(
                  'Профиль не загружен',
                  style: NinjaText.body.copyWith(color: NinjaColors.error),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email
                  Text('Email', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _emailController,
                    hint: 'Введите email',
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

                  // Логин
                  Text('Логин', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _loginController,
                    hint: 'Введите логин',
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
                  const SizedBox(height: 20),

                  // Телефон
                  Text('Телефон', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _phoneController,
                    hint: 'Введите номер телефона',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Имя
                  Text('Имя', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _firstNameController,
                    hint: 'Введите имя',
                  ),
                  const SizedBox(height: 20),

                  // Фамилия
                  Text('Фамилия', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _lastNameController,
                    hint: 'Введите фамилию',
                  ),
                  const SizedBox(height: 20),

                  // Отчество
                  Text('Отчество', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _middleNameController,
                    hint: 'Введите отчество',
                  ),
                  const SizedBox(height: 20),

                  // Пол
                  Text('Пол', style: NinjaText.section),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: MetalDropdown<String>(
                      value: _selectedGender ?? 'male',
                      items: [
                        MetalDropdownItem(value: 'male', label: 'Мужской'),
                        MetalDropdownItem(value: 'female', label: 'Женский'),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                        _onFieldChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // О себе
                  Text('О себе', style: NinjaText.section),
                  const SizedBox(height: 8),
                  MetalTextField(
                    controller: _descriptionController,
                    hint: 'Расскажите о себе',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
