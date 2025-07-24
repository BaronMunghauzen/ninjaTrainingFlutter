import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

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

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Профиль успешно обновлен',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: const Color(0xFF1F2121),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактировать профиль',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_hasChanges && !_isSaving)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  color: const Color(0xFF1F2121),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userProfile = authProvider.userProfile;
          if (userProfile == null) {
            return const Center(
              child: Text(
                'Профиль не загружен',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Email',
                    hint: 'Введите email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email обязателен';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Логин',
                    hint: 'Введите логин',
                    controller: _loginController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Логин обязателен';
                      }
                      if (value.length < 3) {
                        return 'Логин должен содержать минимум 3 символа';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Телефон',
                    hint: 'Введите номер телефона',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Имя',
                    hint: 'Введите имя',
                    controller: _firstNameController,
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Фамилия',
                    hint: 'Введите фамилию',
                    controller: _lastNameController,
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Отчество',
                    hint: 'Введите отчество',
                    controller: _middleNameController,
                  ),
                  const SizedBox(height: 20),

                  // Пол
                  const Text(
                    'Пол',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      hint: const Text(
                        'Выберите пол',
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Мужской')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Женский'),
                        ),
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

                  CustomTextField(
                    label: 'О себе',
                    hint: 'Расскажите о себе',
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Кнопка сохранения
                  if (_hasChanges)
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isSaving ? 'Сохранение...' : 'Сохранить',
                        onPressed: _isSaving ? null : _saveProfile,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
