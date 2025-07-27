import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';

class UserExerciseGroupDetailScreen extends StatefulWidget {
  final ExerciseGroup exerciseGroup;

  const UserExerciseGroupDetailScreen({Key? key, required this.exerciseGroup})
    : super(key: key);

  @override
  State<UserExerciseGroupDetailScreen> createState() =>
      _UserExerciseGroupDetailScreenState();
}

class _UserExerciseGroupDetailScreenState
    extends State<UserExerciseGroupDetailScreen> {
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
            onPressed: () {
              // TODO: Реализовать редактирование
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удаление группы упражнений'),
                  content: const Text(
                    'Вы уверены, что хотите удалить эту группу упражнений?',
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
                // Удаляем все упражнения в группе
                bool allDeleted = true;
                for (final exercise in widget.exerciseGroup.exercises) {
                  final success = await UserTrainingService.deleteExercise(
                    exercise.uuid,
                  );
                  if (!success) {
                    allDeleted = false;
                  }
                }

                // Удаляем группу упражнений
                if (allDeleted) {
                  final groupSuccess =
                      await UserTrainingService.deleteExerciseGroup(
                        widget.exerciseGroup.uuid,
                      );
                  if (groupSuccess) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Группа упражнений удалена'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка при удалении упражнений'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о группе упражнений
            Text(
              widget.exerciseGroup.caption,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.exerciseGroup.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Группа мышц: ${widget.exerciseGroup.muscleGroup}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Упражнения (${widget.exerciseGroup.exercises.length}):',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Список упражнений
            Expanded(
              child: ListView.builder(
                itemCount: widget.exerciseGroup.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.exerciseGroup.exercises[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.fitness_center,
                        color: AppColors.textPrimary,
                      ),
                      title: Text(
                        exercise.caption,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Подходы: ${exercise.setsCount}, Повторения: ${exercise.repsCount}, Отдых: ${exercise.restTime}с',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (exercise.withWeight) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Вес: ${exercise.weight} кг',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
