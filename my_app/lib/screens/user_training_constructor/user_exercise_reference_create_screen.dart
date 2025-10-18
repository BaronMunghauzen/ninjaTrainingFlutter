import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';

class UserExerciseReferenceCreateScreen extends StatefulWidget {
  const UserExerciseReferenceCreateScreen({Key? key}) : super(key: key);

  @override
  State<UserExerciseReferenceCreateScreen> createState() =>
      _UserExerciseReferenceCreateScreenState();
}

class _UserExerciseReferenceCreateScreenState
    extends State<UserExerciseReferenceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _equipmentNameController = TextEditingController();
  bool _isLoading = false;
  bool _hasEquipment = false;

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    _equipmentNameController.dispose();
    super.dispose();
  }

  Future<void> _createExercise() async {
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

      final result = await UserTrainingService.createUserExercise(
        userUuid: userUuid,
        caption: _captionController.text,
        description: _descriptionController.text,
        muscleGroup: _muscleGroupController.text,
        equipmentName: _hasEquipment ? _equipmentNameController.text : null,
      );

      if (result != null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Упражнение создано')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при создании упражнения')),
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
          'Создать упражнение',
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
                  labelText: 'Название упражнения',
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
              // Оборудование
              Row(
                children: [
                  const Text('Используется оборудование:'),
                  const SizedBox(width: 16),
                  Switch(
                    value: _hasEquipment,
                    onChanged: (value) {
                      setState(() {
                        _hasEquipment = value;
                        if (!value) {
                          _equipmentNameController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_hasEquipment) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _equipmentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Название оборудования',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_hasEquipment && (value == null || value.isEmpty)) {
                      return 'Пожалуйста, введите название оборудования';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Создать упражнение',
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
