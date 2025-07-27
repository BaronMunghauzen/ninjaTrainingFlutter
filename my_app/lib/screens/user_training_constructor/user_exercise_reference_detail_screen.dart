import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';

class UserExerciseReferenceDetailScreen extends StatefulWidget {
  final ExerciseReference exercise;

  const UserExerciseReferenceDetailScreen({Key? key, required this.exercise})
    : super(key: key);

  @override
  State<UserExerciseReferenceDetailScreen> createState() =>
      _UserExerciseReferenceDetailScreenState();
}

class _UserExerciseReferenceDetailScreenState
    extends State<UserExerciseReferenceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exercise.caption,
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
                final success =
                    await UserTrainingService.deleteExerciseReference(
                      widget.exercise.uuid,
                    );
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Упражнение удалено')),
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
            // Название упражнения
            Text(
              widget.exercise.caption,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Описание
            Text(
              'Описание:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.exercise.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Группа мышц
            Text(
              'Группа мышц:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.exercise.muscleGroup,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Тип упражнения
            Text(
              'Тип упражнения:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.exercise.exerciseType,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
