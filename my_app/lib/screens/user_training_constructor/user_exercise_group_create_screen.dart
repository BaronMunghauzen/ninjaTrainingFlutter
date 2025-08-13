import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import '../admin_training_constructor/widgets.dart';

class UserExerciseGroupCreateScreen extends StatefulWidget {
  final String trainingUuid;

  const UserExerciseGroupCreateScreen({Key? key, required this.trainingUuid})
    : super(key: key);

  @override
  State<UserExerciseGroupCreateScreen> createState() =>
      _UserExerciseGroupCreateScreenState();
}

class _UserExerciseGroupCreateScreenState
    extends State<UserExerciseGroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _setsCountController = TextEditingController();
  final _repsCountController = TextEditingController();
  final _restTimeController = TextEditingController();

  ExerciseReference? selectedExercise;
  bool withWeight = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    _setsCountController.dispose();
    _repsCountController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  Future<void> _createExerciseGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите упражнение')),
      );
      return;
    }

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

      // Создаем упражнение
      final exerciseResult = await UserTrainingService.createExercise(
        userUuid: userUuid,
        caption: _captionController.text,
        description: _descriptionController.text,
        muscleGroup: _muscleGroupController.text,
        setsCount: int.parse(_setsCountController.text),
        repsCount: int.parse(_repsCountController.text),
        restTime: int.parse(_restTimeController.text),
        withWeight: withWeight,
        weight: 0,
        exerciseReferenceUuid: selectedExercise!.uuid,
      );

      if (exerciseResult != null && exerciseResult['uuid'] != null) {
        // Создаем группу упражнений
        final groupResult = await UserTrainingService.createExerciseGroup(
          trainingUuid: widget.trainingUuid,
          caption: _captionController.text,
          description: _descriptionController.text,
          muscleGroup: _muscleGroupController.text,
          exercises: [exerciseResult['uuid']],
        );

        if (groupResult != null) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Группа упражнений создана')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка при создании группы упражнений'),
            ),
          );
        }
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
          'Добавить упражнение',
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Выбор упражнения из справочника
                ExerciseReferenceSelector(
                  onSelected: (exercise) {
                    setState(() {
                      if (exercise != null) {
                        selectedExercise = ExerciseReference(
                          uuid: exercise['uuid'],
                          caption: exercise['caption'],
                          description: exercise['description'],
                          muscleGroup: exercise['muscle_group'] ?? '',
                          exerciseType: exercise['exercise_type'] ?? 'user',
                          createdAt:
                              exercise['created_at'] ??
                              DateTime.now().toIso8601String(),
                          updatedAt:
                              exercise['updated_at'] ??
                              DateTime.now().toIso8601String(),
                        );
                      } else {
                        selectedExercise = null;
                      }
                    });
                  },
                  label: 'Выберите упражнение',
                  endpoint:
                      '/exercise_reference/available/${context.read<AuthProvider>().userUuid}/search/by-caption',
                  buildQueryParams: (search) {
                    return {'caption': search};
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsCountController,
                        decoration: const InputDecoration(
                          labelText: 'Количество подходов',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Обязательно';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Должно быть числом';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _repsCountController,
                        decoration: const InputDecoration(
                          labelText: 'Количество повторений',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Обязательно';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Должно быть числом';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _restTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Время отдыха (секунды)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите время отдыха';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Должно быть числом';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('С весом'),
                  value: withWeight,
                  onChanged: (value) {
                    setState(() {
                      withWeight = value ?? false;
                    });
                  },
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createExerciseGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Добавить упражнение',
                          style: TextStyle(fontSize: 16),
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
