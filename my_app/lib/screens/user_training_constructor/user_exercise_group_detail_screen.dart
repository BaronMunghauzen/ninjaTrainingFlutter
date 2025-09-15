import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import 'user_exercise_edit_screen.dart';

class UserExerciseGroupDetailScreen extends StatefulWidget {
  final ExerciseGroup exerciseGroup;
  final VoidCallback? onDataChanged;

  const UserExerciseGroupDetailScreen({
    Key? key,
    required this.exerciseGroup,
    this.onDataChanged,
  }) : super(key: key);

  @override
  State<UserExerciseGroupDetailScreen> createState() =>
      _UserExerciseGroupDetailScreenState();
}

class _UserExerciseGroupDetailScreenState
    extends State<UserExerciseGroupDetailScreen> {
  String exerciseName = '';
  int? setsCount;
  int? repsCount;
  int? restTime;
  bool? withWeight;
  bool _isLoading = true;
  String? exerciseReferenceName;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    if (widget.exerciseGroup.exercises.isNotEmpty) {
      try {
        final response = await ApiService.get(
          '/exercises/${widget.exerciseGroup.exercises.first}',
        );
        if (response.statusCode == 200) {
          final data = ApiService.decodeJson(response.body);
          setState(() {
            exerciseName = data['caption'] ?? 'Упражнение';
            setsCount = data['sets_count'];
            repsCount = data['reps_count'];
            restTime = data['rest_time'];
            withWeight = data['with_weight'];
            _isLoading = false;
          });

          // Загружаем данные упражнения из справочника
          final exerciseReferenceUuid = data['exercise_reference_uuid'];
          if (exerciseReferenceUuid != null) {
            await _loadExerciseReferenceData(exerciseReferenceUuid);
          }
        } else {
          setState(() {
            exerciseName = 'Упражнение';
            setsCount = 3;
            repsCount = 12;
            restTime = 60;
            withWeight = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          exerciseName = 'Упражнение';
          setsCount = 3;
          repsCount = 12;
          restTime = 60;
          withWeight = true;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        exerciseName = 'Упражнение';
        setsCount = 3;
        repsCount = 12;
        restTime = 60;
        withWeight = true;
        _isLoading = false;
      });
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exerciseGroup.caption,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (widget.exerciseGroup.exercises.isNotEmpty) {
                final exerciseUuid = widget.exerciseGroup.exercises.first;
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserExerciseEditScreen(exerciseUuid: exerciseUuid),
                  ),
                );
                if (result == true) {
                  // Обновляем данные после редактирования
                  _loadExerciseData();
                  // Вызываем callback для обновления родительской страницы
                  widget.onDataChanged?.call();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удаление упражнения'),
                  content: const Text(
                    'Вы уверены, что хотите удалить это упражнение?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                // Удаляем только группу упражнений
                final groupSuccess =
                    await UserTrainingService.deleteExerciseGroup(
                      widget.exerciseGroup.uuid,
                    );
                if (groupSuccess) {
                  // Вызываем callback для обновления данных на родительской странице
                  widget.onDataChanged?.call();
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Упражнение удалено')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка при удалении упражнения'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название упражнения
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      exerciseName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Упражнение из справочника
                  if (exerciseReferenceName != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Упражнение из справочника',
                      exerciseReferenceName!,
                    ),
                  ],

                  // Информация о тренировке
                  const SizedBox(height: 16),
                  _buildInfoRow('Подходы', setsCount?.toString() ?? '3'),
                  const SizedBox(height: 16),
                  _buildInfoRow('Повторения', repsCount?.toString() ?? '12'),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Группа мышц',
                    widget.exerciseGroup.muscleGroup,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Время отдыха', '${restTime ?? 60}с'),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Вес',
                    (withWeight ?? true) ? 'С весом' : 'Без веса',
                  ),
                ],
              ),
            ),
    );
  }
}
