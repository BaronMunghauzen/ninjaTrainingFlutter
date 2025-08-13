import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/user_training_service.dart';
import '../../widgets/video_player_widget.dart';
import 'user_exercise_reference_edit_screen.dart';

class UserExerciseReferenceDetailScreen extends StatefulWidget {
  final ExerciseReference exercise;

  const UserExerciseReferenceDetailScreen({super.key, required this.exercise});

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
          if (widget.exercise.exerciseType == 'user') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => UserExerciseReferenceEditScreen(
                      exercise: widget.exercise,
                    ),
                  ),
                );

                // Если упражнение было обновлено, обновляем экран
                if (result == true) {
                  setState(() {
                    // Обновляем данные упражнения
                    // В реальном приложении здесь можно загрузить обновленные данные
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Упражнение удалено')),
                    );
                  }
                }
              },
            ),
          ],
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
            const SizedBox(height: 8),
            // Индикатор типа упражнения
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.exercise.exerciseType == 'user'
                    ? AppColors.buttonPrimary
                    : AppColors.textSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.exercise.exerciseType == 'user'
                    ? 'Пользовательская'
                    : 'Системная',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Видеоплеер (только для системных упражнений)
            if (widget.exercise.exerciseType == 'system' &&
                (widget.exercise.videoUuid != null ||
                    widget.exercise.imageUuid != null))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Демонстрация:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  VideoPlayerWidget(
                    imageUuid: widget.exercise.imageUuid,
                    videoUuid: widget.exercise.videoUuid,
                    exerciseReferenceUuid: widget.exercise.uuid,
                    width: double.infinity,
                    height: 250,
                    showControls: true,
                  ),
                  const SizedBox(height: 16),
                ],
              ),

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
