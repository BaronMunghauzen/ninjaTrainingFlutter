import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../user_training_constructor/user_exercise_selector_screen.dart';
import 'free_workout_exercise_group_screen.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/workout_timer_widget.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';
// import '../../widgets/video_player_widget.dart';

class FreeWorkoutScreen extends StatefulWidget {
  final String userTrainingUuid;
  final String trainingUuid;

  const FreeWorkoutScreen({
    super.key,
    required this.userTrainingUuid,
    required this.trainingUuid,
  });

  @override
  State<FreeWorkoutScreen> createState() => _FreeWorkoutScreenState();
}

class _FreeWorkoutScreenState extends State<FreeWorkoutScreen> {
  List<Map<String, dynamic>> exerciseGroups = [];
  bool isLoading = true;
  Map<String, Uint8List> imageCache = {};
  Map<String, Map<String, dynamic>> exerciseData = {};
  String trainingCaption = 'Свободная тренировка'; // Значение по умолчанию
  DateTime? _workoutStartTime;

  @override
  void initState() {
    super.initState();
    _loadUserTraining();
    _loadTraining();
    _loadExerciseGroups();
  }

  Future<void> _loadUserTraining() async {
    try {
      final resp = await ApiService.get('/user_trainings/${widget.userTrainingUuid}');
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        _parseWorkoutStartTime(data);
      }
    } catch (e) {
      print('Error loading user training: $e');
    }
  }

  void _parseWorkoutStartTime(Map<String, dynamic> userTraining) {
    try {
      final createdAt = userTraining['created_at'];
      if (createdAt != null) {
        DateTime startTime;
        if (createdAt is String) {
          // Парсим строку в формате ISO 8601 с часовым поясом (например: "2026-01-17T09:50:49.262478+00:00")
          // DateTime.parse автоматически конвертирует в локальное время
          startTime = DateTime.parse(createdAt).toLocal();
        } else if (createdAt is int) {
          // Если это timestamp в секундах
          startTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000).toLocal();
        } else {
          print('⚠️ Неизвестный формат created_at: $createdAt');
          return;
        }
        setState(() {
          _workoutStartTime = startTime;
        });
        print('⏱️ Время начала тренировки: $_workoutStartTime');
      } else {
        print('⚠️ created_at не найден в userTraining');
      }
    } catch (e) {
      print('❌ Ошибка парсинга created_at: $e');
    }
  }

  Future<void> _loadTraining() async {
    try {
      final resp = await ApiService.get('/trainings/${widget.trainingUuid}');
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        setState(() {
          trainingCaption = data['caption'] ?? 'Свободная тренировка';
        });
      }
    } catch (e) {
      print('Error loading training: $e');
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка загрузки тренировки: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  Future<void> _loadExerciseGroups() async {
    setState(() => isLoading = true);
    try {
      // Запрос 3: GET /exercise-groups/
      final response = await ApiService.get(
        '/exercise-groups/',
        queryParams: {'training_uuid': widget.trainingUuid},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final List groups = data ?? [];

        // Загружаем данные для каждой группы упражнений (запросы 4, 5, 6)
        for (var group in groups) {
          final exercises = group['exercises'] as List;
          if (exercises.isNotEmpty) {
            final exerciseUuid = exercises[0];

            // Запрос 4: GET /exercises/{exercise_uuid}
            final exResp = await ApiService.get('/exercises/$exerciseUuid');
            if (exResp.statusCode == 200) {
              final exData = ApiService.decodeJson(exResp.body);
              group['exercise_data'] = exData;

              // Получаем exercise_reference_uuid
              final exerciseReferenceUuid = exData['exercise_reference_uuid'];

              // Запрос 5: GET /exercise_reference/{exercise_reference_uuid}
              if (exerciseReferenceUuid != null) {
                final refResp = await ApiService.get(
                  '/exercise_reference/$exerciseReferenceUuid',
                );
                if (refResp.statusCode == 200) {
                  final refData = ApiService.decodeJson(refResp.body);
                  group['exercise_reference'] = refData;

                  // Сохраняем image_uuid и gif_uuid
                  final imageUuid = refData['image_uuid'];
                  final gifUuid = refData['gif_uuid'];

                  if (imageUuid != null) {
                    await _cacheImage(imageUuid);
                  }
                  if (gifUuid != null) {
                    await _cacheImage(gifUuid);
                  }
                }
              }

              // Запрос 6: GET /user_exercises/
              final userExercisesResp = await ApiService.get(
                '/user_exercises/',
                queryParams: {'exercise_uuid': exerciseUuid},
              );
              if (userExercisesResp.statusCode == 200) {
                final userExData = ApiService.decodeJson(
                  userExercisesResp.body,
                );
                group['user_exercises'] = userExData ?? [];
              }
            }
          }
        }

        setState(() {
          exerciseGroups = List<Map<String, dynamic>>.from(groups);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка загрузки групп упражнений',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      print('Error loading exercise groups: $e');
      setState(() => isLoading = false);
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка загрузки групп упражнений: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  Future<void> _cacheImage(String uuid) async {
    if (imageCache.containsKey(uuid)) return;

    try {
      final bytes = await ApiService.getFile(uuid);
      if (bytes != null) {
        setState(() {
          imageCache[uuid] = bytes;
        });
      }
    } catch (e) {
      print('Error caching image $uuid: $e');
    }
  }

  Widget _buildExerciseMedia(Map<String, dynamic> group) {
    final ref = group['exercise_reference'];
    if (ref == null) {
      // Возвращаем пустой контейнер для сохранения отступа
      return const SizedBox(width: 60, height: 60);
    }

    // Приоритет: гиф -> изображение (видео не показываем на списке)
    final gifUuid = ref['gif_uuid'];
    if (gifUuid != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GifWidget(gifUuid: gifUuid, height: 60, width: 60),
      );
    }

    // Проверяем image_uuid
    final imageUuid = ref['image_uuid'];
    if (imageUuid != null) {
      if (imageCache.containsKey(imageUuid)) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: MemoryImage(imageCache[imageUuid]!),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    // Возвращаем пустой контейнер для сохранения отступа
    return const SizedBox(width: 60, height: 60);
  }

  String _formatUserExercises(List userExercises) {
    if (userExercises.isEmpty) return '';

    final parts = <String>[];
    for (var ex in userExercises) {
      final weight = ex['weight'];
      final reps = ex['reps'] ?? 0;
      // Изменено: проверяем именно != null, чтобы weight=0 тоже отображался
      if (weight != null) {
        parts.add('$reps x ${weight.toStringAsFixed(2)} кг');
      } else {
        parts.add('$reps');
      }
    }
    return parts.join(', ');
  }

  void _showFinishConfirmation() {
    MetalModal.show(
      context: context,
      title: 'Завершить тренировку?',
      children: [
        Text(
          'Вы уверены, что хотите завершить тренировку?',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Завершить',
                onPressed: () {
                  Navigator.of(context).pop();
                  _finishTraining();
                },
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
                topColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _finishTraining() async {
    try {
      // Закрываем постоянное уведомление о тренировке
      await NotificationService.cancelWorkoutNotification();
      
      // POST /user_trainings/{user_training_uuid}/pass
      final response = await ApiService.post(
        '/user_trainings/${widget.userTrainingUuid}/pass',
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop(true); // Возвращаемся назад
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка завершения тренировки',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      print('Error finishing training: $e');
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка завершения тренировки: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  void _addExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserExerciseSelectorScreen(),
      ),
    );

    if (result != null && mounted) {
      // result это ExerciseReference
      final exerciseRef = result;
      await _handleExerciseSelection(exerciseRef);
    }
  }

  Future<void> _handleExerciseSelection(dynamic exerciseRef) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: не найден userUuid',
          type: MetalMessageType.error,
        );
        return;
      }

      // Проверяем, есть ли уже упражнение с таким же exercise_reference_uuid
      final exerciseRefUuid = exerciseRef.uuid;
      final alreadyExists = exerciseGroups.any((group) {
        final exData = group['exercise_data'];
        if (exData != null) {
          return exData['exercise_reference_uuid'] == exerciseRefUuid;
        }
        return false;
      });

      if (alreadyExists) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Упражнение "${exerciseRef.caption}" уже добавлено в тренировку',
            type: MetalMessageType.warning,
          );
        }
        return;
      }

      // Запрос 1: POST /exercises/add/
      final exBody = {
        'exercise_type': 'userFree',
        'user_uuid': userUuid,
        'caption': exerciseRef.caption,
        'difficulty_level': 1,
        'order': 0,
        'muscle_group': exerciseRef.muscleGroup,
        'exercise_reference_uuid': exerciseRef.uuid,
      };

      final exResp = await ApiService.post('/exercises/add/', body: exBody);
      if (exResp.statusCode != 200) {
        throw Exception('Failed to create exercise');
      }

      final exData = ApiService.decodeJson(exResp.body);
      final exerciseUuid = exData['uuid'];

      // Запрос 2: POST /exercise-groups/add/
      final groupBody = {
        'training_uuid': widget.trainingUuid,
        'caption': exerciseRef.caption,
        'description': exerciseRef.description ?? '',
        'exercises': [exerciseUuid],
        'difficulty_level': 1,
        'order': 0,
        'muscle_group': exerciseRef.muscleGroup,
        'stage': 1,
      };

      final groupResp = await ApiService.post(
        '/exercise-groups/add/',
        body: groupBody,
      );
      if (groupResp.statusCode != 200) {
        throw Exception('Failed to create exercise group');
      }

      // Обновляем список
      await _loadExerciseGroups();
    } catch (e) {
      print('Error adding exercise: $e');
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка добавления упражнения: $e',
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
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Верхняя панель с кнопкой назад и названием тренировки
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          const MetalBackButton(),
                          const SizedBox(width: NinjaSpacing.md),
                          Expanded(
                            child: Text(
                              trainingCaption,
                              style: NinjaText.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: NinjaSpacing.md),
                          // Секундомер тренировки
                          if (_workoutStartTime != null)
                            WorkoutTimerWidget(startTime: _workoutStartTime!)
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: exerciseGroups.length + 1, // +1 для кнопки
                        itemBuilder: (context, index) {
                          // Кнопка "Добавить упражнение" после всех упражнений
                          if (index == exerciseGroups.length) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 16,
                              ),
                              child: MetalButton(
                                label: 'Добавить упражнение',
                                icon: Icons.add,
                                onPressed: _addExercise,
                                height: 56,
                                fontSize: 16,
                              ),
                            );
                          }

                          final group = exerciseGroups[index];
                          final userEx = group['user_exercises'] as List? ?? [];
                          final formattedExercises = _formatUserExercises(
                            userEx,
                          );

                          return MetalListItem(
                            leading: _buildExerciseMedia(group),
                            title: Text(
                              group['caption'] ?? '',
                              style: NinjaText.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: formattedExercises.isNotEmpty
                                ? Text(
                                    formattedExercises,
                                    style: NinjaText.caption,
                                  )
                                : null,
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FreeWorkoutExerciseGroupScreen(
                                        exerciseGroupUuid: group['uuid'],
                                        trainingUuid: widget.trainingUuid,
                                        userTrainingUuid:
                                            widget.userTrainingUuid,
                                      ),
                                ),
                              );
                              _loadExerciseGroups(); // Обновляем после возврата
                            },
                            isFirst: index == 0,
                            isLast: index == exerciseGroups.length - 1,
                            removeSpacing: true,
                          );
                        },
                      ),
                    ),
                    // Кнопка "Завершить" внизу
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: MetalButton(
                        label: 'Завершить',
                        onPressed: _showFinishConfirmation,
                        height: 56,
                        fontSize: 16,
                        topColor: Colors.green,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
