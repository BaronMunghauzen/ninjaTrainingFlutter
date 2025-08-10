import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../services/user_training_service.dart';
import 'user_exercise_group_create_screen.dart';
import 'user_exercise_group_detail_screen.dart';
import 'user_training_edit_screen.dart';

class UserTrainingDetailScreen extends StatefulWidget {
  final Training training;

  const UserTrainingDetailScreen({super.key, required this.training});

  @override
  State<UserTrainingDetailScreen> createState() =>
      _UserTrainingDetailScreenState();
}

class _UserTrainingDetailScreenState extends State<UserTrainingDetailScreen> {
  late Training _training;
  List<ExerciseGroup> exerciseGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _training = widget.training;
    _loadExerciseGroups();
  }

  Future<void> _loadExerciseGroups() async {
    try {
      final groups = await UserTrainingService.getExerciseGroupsForTraining(
        _training.uuid,
      );
      setState(() {
        exerciseGroups = groups;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading exercise groups: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Обновляет данные тренировки после редактирования
  Future<void> _refreshTrainingData() async {
    try {
      final updatedTraining = await UserTrainingService.getUserTrainingByUuid(
        _training.uuid,
      );

      if (updatedTraining != null) {
        setState(() {
          // Обновляем локальную переменную состояния
          _training = updatedTraining;
        });
      }
    } catch (e) {
      print('Error refreshing training data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _training.caption,
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
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      UserTrainingEditScreen(training: _training),
                ),
              );
              if (result == true) {
                // Обновляем данные тренировки
                await _refreshTrainingData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: exerciseGroups.isEmpty
                ? () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Удаление тренировки'),
                        content: const Text(
                          'Вы уверены, что хотите удалить эту тренировку?',
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
                      final success = await UserTrainingService.deleteTraining(
                        _training.uuid,
                      );
                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Тренировка удалена')),
                        );
                      }
                    }
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о тренировке
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _training.caption,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _training.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Группа мышц: ${_training.muscleGroup}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Уровень сложности: ${_training.difficultyLevel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Список групп упражнений
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                    ),
                  )
                : exerciseGroups.isEmpty
                ? const Center(
                    child: Text(
                      'В этой тренировке пока нет упражнений',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exerciseGroups.length,
                    itemBuilder: (context, index) {
                      final group = exerciseGroups[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.fitness_center,
                            color: AppColors.textPrimary,
                          ),
                          title: Text(
                            group.caption,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Упражнений: ${group.exercises.length}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserExerciseGroupDetailScreen(
                                      exerciseGroup: group,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  UserExerciseGroupCreateScreen(trainingUuid: _training.uuid),
            ),
          );
          if (result == true) {
            _loadExerciseGroups();
          }
        },
        backgroundColor: AppColors.buttonPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
