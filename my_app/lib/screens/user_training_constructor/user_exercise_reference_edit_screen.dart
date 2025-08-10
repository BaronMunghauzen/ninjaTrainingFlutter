import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';

class UserExerciseReferenceEditScreen extends StatefulWidget {
  final ExerciseReference exercise;

  const UserExerciseReferenceEditScreen({super.key, required this.exercise});

  @override
  State<UserExerciseReferenceEditScreen> createState() =>
      _UserExerciseReferenceEditScreenState();
}

class _UserExerciseReferenceEditScreenState
    extends State<UserExerciseReferenceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _captionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _muscleGroupController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры с текущими значениями
    _captionController = TextEditingController(text: widget.exercise.caption);
    _descriptionController = TextEditingController(
      text: widget.exercise.description,
    );
    _muscleGroupController = TextEditingController(
      text: widget.exercise.muscleGroup,
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  Future<void> _updateExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Сохраняем контекст в переменные до асинхронных операций
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Ошибка: не найден userUuid')),
        );
        return;
      }

      final result = await UserTrainingService.updateUserExercise(
        exerciseUuid: widget.exercise.uuid,
        userUuid: userUuid,
        caption: _captionController.text,
        description: _descriptionController.text,
        muscleGroup: _muscleGroupController.text,
      );

      if (result != null) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Упражнение обновлено')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении упражнения')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактировать упражнение',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    labelText: 'Название упражнения',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите название упражнения';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите описание упражнения';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _muscleGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Группа мышц',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите группу мышц';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Сохранить изменения',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
