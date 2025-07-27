import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';

class UserTrainingCreateScreen extends StatefulWidget {
  const UserTrainingCreateScreen({Key? key}) : super(key: key);

  @override
  State<UserTrainingCreateScreen> createState() =>
      _UserTrainingCreateScreenState();
}

class _UserTrainingCreateScreenState extends State<UserTrainingCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  int _difficultyLevel = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  Future<void> _createTraining() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: не найден userUuid')),
        );
        return;
      }

      final result = await UserTrainingService.createUserTraining(
        userUuid: userUuid,
        caption: _captionController.text,
        description: _descriptionController.text,
        difficultyLevel: _difficultyLevel,
        muscleGroup: _muscleGroupController.text,
      );

      if (result != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка создана')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при создании тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
          'Создать тренировку',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название';
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
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите описание';
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createTraining,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Создать тренировку',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
