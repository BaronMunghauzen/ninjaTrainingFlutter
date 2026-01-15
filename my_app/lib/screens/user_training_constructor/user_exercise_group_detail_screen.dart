import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/video_player_widget.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';
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
  dynamic exerciseReferenceVideo;

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
          exerciseReferenceVideo = data['video_uuid'] ?? data['video'];
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


  Widget? _buildMediaWidget() {
    // Приоритет: сначала видео, затем гифка, затем картинка
    String? videoUuid;
    String? gifUuid;
    String? imageUuid;

    // Извлекаем UUID видео
    if (exerciseReferenceVideo != null) {
      if (exerciseReferenceVideo is String &&
          exerciseReferenceVideo.isNotEmpty) {
        videoUuid = exerciseReferenceVideo;
      } else if (exerciseReferenceVideo is Map<String, dynamic>) {
        videoUuid = exerciseReferenceVideo['uuid'] as String?;
      }
    }

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

    // Если есть видео, показываем плеер с превью
    if (videoUuid != null && videoUuid.isNotEmpty) {
      return VideoPlayerWidget(
        videoUuid: videoUuid,
        imageUuid: imageUuid,
        height: 250,
        width: double.infinity,
        showControls: true,
        autoInitialize: true,
      );
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

  Future<void> _deleteExercise() async {
    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Удаление упражнения',
      children: [
        Text(
          'Вы уверены, что хотите удалить это упражнение?',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(false),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Удалить',
                onPressed: () => Navigator.of(context).pop(true),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
              ),
            ),
          ],
        ),
      ],
    );

    if (confirmed != true) return;

    // Удаляем только группу упражнений
    final groupSuccess = await UserTrainingService.deleteExerciseGroup(
      widget.exerciseGroup.uuid,
    );
    if (groupSuccess) {
      // Вызываем callback для обновления данных на родительской странице
      widget.onDataChanged?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
        MetalMessage.show(
          context: context,
          message: 'Упражнение удалено',
          type: MetalMessageType.success,
        );
      }
    } else {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка при удалении упражнения',
          type: MetalMessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхний раздел с кнопками
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const Spacer(),
                    MetalBackButton(
                      icon: Icons.edit,
                      onTap: () async {
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
                    const SizedBox(width: NinjaSpacing.md),
                    MetalBackButton(
                      icon: Icons.delete,
                      onTap: _deleteExercise,
                    ),
                  ],
                ),
              ),
              // Основной контент
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Название упражнения по центру
                            Text(
                              exerciseName,
                              style: NinjaText.title,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: NinjaSpacing.xl),
                            // Медиа (гифка или картинка) из справочника
                            Builder(
                              builder: (context) {
                                final mediaWidget = _buildMediaWidget();
                                if (mediaWidget != null) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (exerciseReferenceName != null)
                                        const SizedBox(height: NinjaSpacing.lg),
                                      MetalCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Демонстрация',
                                              style: NinjaText.caption.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            mediaWidget,
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Информация о тренировке
                            MetalCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Подходы', setsCount?.toString() ?? '3'),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Повторения', repsCount?.toString() ?? '12'),
                                  const SizedBox(height: 16),
                                  _buildInfoRow('Время отдыха', '${restTime ?? 60}с'),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Группа мышц',
                                    widget.exerciseGroup.muscleGroup,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Вес',
                                    (withWeight ?? true) ? 'С весом' : 'Без веса',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NinjaText.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: NinjaText.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
