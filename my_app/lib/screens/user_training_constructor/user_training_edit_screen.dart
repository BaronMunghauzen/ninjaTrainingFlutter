import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../services/user_training_service.dart';

class UserTrainingEditScreen extends StatefulWidget {
  final Training training;

  const UserTrainingEditScreen({super.key, required this.training});

  @override
  State<UserTrainingEditScreen> createState() => _UserTrainingEditScreenState();
}

class _UserTrainingEditScreenState extends State<UserTrainingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _captionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _muscleGroupController;
  late int _difficultyLevel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры с текущими значениями
    _captionController = TextEditingController(text: widget.training.caption);
    _descriptionController = TextEditingController(
      text: widget.training.description,
    );
    _muscleGroupController = TextEditingController(
      text: widget.training.muscleGroup,
    );
    // Ensure difficulty level is within valid range (1-3)
    _difficultyLevel = widget.training.difficultyLevel.clamp(1, 3);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  Future<void> _updateTraining() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Сохраняем контекст в переменные до асинхронных операций
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await UserTrainingService.updateUserTraining(
        trainingUuid: widget.training.uuid,
        caption: _captionController.text,
        description: _descriptionController.text,
        difficultyLevel: _difficultyLevel,
        muscleGroup: _muscleGroupController.text,
      );

      if (result != null) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Тренировка обновлена')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении тренировки')),
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
          'Редактировать тренировку',
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
                    labelText: 'Название тренировки',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите название тренировки';
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
                      return 'Пожалуйста, введите описание тренировки';
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
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _difficultyLevel,
                  decoration: const InputDecoration(
                    labelText: 'Уровень сложности',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                  items: [
                    DropdownMenuItem(value: 1, child: Text('Начинающий')),
                    DropdownMenuItem(value: 2, child: Text('Средний')),
                    DropdownMenuItem(value: 3, child: Text('Продвинутый')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _difficultyLevel = value!;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateTraining,
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
