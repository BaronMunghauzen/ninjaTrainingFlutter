import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
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
  dynamic exerciseReferenceGif;
  dynamic exerciseReferenceImage;

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
          exerciseReferenceGif = data['gif_uuid'] ?? data['gif'];
          exerciseReferenceImage = data['image_uuid'] ?? data['image'];
        });
      }
    } catch (e) {
      print('Error loading exercise reference data: $e');
      setState(() {
        exerciseReferenceName = 'Ошибка загрузки';
        exerciseReferenceGif = null;
        exerciseReferenceImage = null;
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

  Widget? _buildMediaWidget() {
    // Приоритет: сначала гифка, потом картинка
    String? gifUuid;
    String? imageUuid;

    // Извлекаем UUID гифки
    if (exerciseReferenceGif != null) {
      if (exerciseReferenceGif is String && exerciseReferenceGif.isNotEmpty) {
        gifUuid = exerciseReferenceGif;
      } else if (exerciseReferenceGif is Map<String, dynamic>) {
        gifUuid = exerciseReferenceGif['uuid'] as String?;
      }
    }

    // Извлекаем UUID картинки
    if (exerciseReferenceImage != null) {
      if (exerciseReferenceImage is String &&
          exerciseReferenceImage.isNotEmpty) {
        imageUuid = exerciseReferenceImage;
      } else if (exerciseReferenceImage is Map<String, dynamic>) {
        imageUuid = exerciseReferenceImage['uuid'] as String?;
      }
    }

    // Если есть гифка, показываем её
    if (gifUuid != null && gifUuid.isNotEmpty) {
      return GifWidget(gifUuid: gifUuid, height: 250, width: double.infinity);
    }

    // Если нет гифки, но есть картинка, показываем её
    if (imageUuid != null && imageUuid.isNotEmpty) {
      return AuthImageWidget(
        imageUuid: imageUuid,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // Если нет ни гифки, ни картинки, не отображаем ничего
    return null;
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

                  // Медиа (гифка или картинка) из справочника
                  Builder(
                    builder: (context) {
                      final mediaWidget = _buildMediaWidget();
                      if (mediaWidget != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Демонстрация:',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            mediaWidget,
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

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
