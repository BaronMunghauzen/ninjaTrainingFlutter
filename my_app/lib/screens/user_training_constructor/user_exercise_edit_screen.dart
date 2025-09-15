import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class UserExerciseEditScreen extends StatefulWidget {
  final String exerciseUuid;

  const UserExerciseEditScreen({Key? key, required this.exerciseUuid})
    : super(key: key);

  @override
  State<UserExerciseEditScreen> createState() => _UserExerciseEditScreenState();
}

class _UserExerciseEditScreenState extends State<UserExerciseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _setsCountController = TextEditingController();
  final _repsCountController = TextEditingController();
  final _restTimeController = TextEditingController();

  bool withWeight = false;
  bool _isLoading = false;
  String? exerciseReferenceName;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
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

  Future<void> _loadExerciseData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '/exercises/${widget.exerciseUuid}',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        _captionController.text = data['caption'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _muscleGroupController.text = data['muscle_group'] ?? '';
        _setsCountController.text = (data['sets_count'] ?? 1).toString();
        _repsCountController.text = (data['reps_count'] ?? 1).toString();
        _restTimeController.text = (data['rest_time'] ?? 0).toString();
        withWeight = data['with_weight'] ?? false;
        print('🔄 Loaded withWeight from API: $withWeight');

        // Загружаем данные упражнения из справочника
        final exerciseReferenceUuid = data['exercise_reference_uuid'];
        if (exerciseReferenceUuid != null) {
          await _loadExerciseReferenceData(exerciseReferenceUuid);
        }
      }
    } catch (e) {
      print('Error loading exercise data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExerciseReferenceData(String exerciseReferenceUuid) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/$exerciseReferenceUuid',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          exerciseReferenceName = data['caption'] ?? 'Неизвестное упражнение';
        });
      }
    } catch (e) {
      print('Error loading exercise reference data: $e');
      setState(() {
        exerciseReferenceName = 'Ошибка загрузки';
      });
    }
  }

  Future<void> _updateExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не авторизован')),
        );
        return;
      }

      final exerciseData = {
        'caption': _captionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'muscle_group': _muscleGroupController.text.trim(),
        'sets_count': int.tryParse(_setsCountController.text) ?? 1,
        'reps_count': int.tryParse(_repsCountController.text) ?? 1,
        'rest_time': int.tryParse(_restTimeController.text) ?? 0,
        'with_weight': withWeight,
      };

      final response = await ApiService.put(
        '/exercises/update/${widget.exerciseUuid}',
        body: exerciseData,
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Упражнение обновлено')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении упражнения')),
        );
      }
    } catch (e) {
      print('Error updating exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении упражнения')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактирование упражнения',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Упражнение из справочника (только для чтения)
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText:
                              'Упражнение из справочника (изменить невозможно)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.textSecondary.withOpacity(0.1),
                        ),
                        controller: TextEditingController(
                          text: exerciseReferenceName ?? 'Загрузка...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Название упражнения
                      TextFormField(
                        controller: _captionController,
                        decoration: const InputDecoration(
                          labelText: 'Название упражнения',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название упражнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Описание
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите описание упражнения';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Группа мышц
                      TextFormField(
                        controller: _muscleGroupController,
                        decoration: const InputDecoration(
                          labelText: 'Группа мышц',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите группу мышц';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Количество подходов
                      TextFormField(
                        controller: _setsCountController,
                        decoration: const InputDecoration(
                          labelText: 'Количество подходов',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите количество подходов';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Введите корректное количество подходов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Количество повторений
                      TextFormField(
                        controller: _repsCountController,
                        decoration: const InputDecoration(
                          labelText: 'Количество повторений',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите количество повторений';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Введите корректное количество повторений';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Время отдыха
                      TextFormField(
                        controller: _restTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Время отдыха (секунды)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите время отдыха';
                          }
                          final time = int.tryParse(value);
                          if (time == null || time < 0) {
                            return 'Введите корректное время отдыха';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // С весом или нет
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
                        onPressed: _isLoading ? null : _updateExercise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Сохранить',
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
