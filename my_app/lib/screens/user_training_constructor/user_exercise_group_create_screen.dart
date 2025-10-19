import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../models/search_result_model.dart' as search_models;
import 'user_exercise_selector_screen.dart';

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

  Future<void> _selectExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserExerciseSelectorScreen(),
      ),
    );

    if (result != null) {
      // Преобразуем ExerciseReference из search_result_model в ExerciseReference из user_training_service
      final searchExerciseRef = result as search_models.ExerciseReference;
      final userExerciseRef = ExerciseReference(
        uuid: searchExerciseRef.uuid,
        exerciseType: searchExerciseRef.exerciseType,
        caption: searchExerciseRef.caption,
        description: searchExerciseRef.description,
        muscleGroup: searchExerciseRef.muscleGroup,
        userUuid: searchExerciseRef.userId?.toString(),
        imageUuid: searchExerciseRef.image?.toString(),
        videoUuid: searchExerciseRef.video?.toString(),
        createdAt: searchExerciseRef.createdAt.toIso8601String(),
        updatedAt: searchExerciseRef.updatedAt.toIso8601String(),
      );

      setState(() {
        selectedExercise = userExerciseRef;
        // Заполняем поля названия, описания и группы мышц из выбранного упражнения
        _captionController.text = searchExerciseRef.caption;
        _descriptionController.text = searchExerciseRef.description;
        _muscleGroupController.text = searchExerciseRef.muscleGroup;
      });
    }
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
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    border: Border.all(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      selectedExercise != null
                          ? selectedExercise!.caption
                          : 'Выберите упражнение',
                      style: TextStyle(
                        color: selectedExercise != null
                            ? Colors.white
                            : Colors.grey[400],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedExercise != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                selectedExercise = null;
                                // Очищаем поля названия, описания и группы мышц при удалении упражнения
                                _captionController.clear();
                                _descriptionController.clear();
                                _muscleGroupController.clear();
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _selectExercise,
                        ),
                      ],
                    ),
                    onTap: _selectExercise,
                  ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'С весом',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        print('🔄 Custom Switch tapped: ${!withWeight}');
                        setState(() {
                          withWeight = !withWeight;
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          color: withWeight
                              ? AppColors.textSecondary.withOpacity(0.3)
                              : AppColors.buttonPrimary.withOpacity(0.3),
                          border: Border.all(
                            color: withWeight
                                ? AppColors.textSecondary
                                : AppColors.buttonPrimary,
                            width: 2,
                          ),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: withWeight
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: withWeight
                                  ? AppColors.textSecondary
                                  : AppColors.buttonPrimary,
                              border: Border.all(
                                color: withWeight
                                    ? AppColors.buttonPrimary
                                    : AppColors.textSecondary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
