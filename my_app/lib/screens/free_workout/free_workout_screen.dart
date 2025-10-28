import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../user_training_constructor/user_exercise_selector_screen.dart';
import 'free_workout_exercise_group_screen.dart';
import '../../widgets/gif_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTraining();
    _loadExerciseGroups();
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
      }
    } catch (e) {
      print('Error loading exercise groups: $e');
      setState(() => isLoading = false);
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

    // Проверяем сначала gif_uuid
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить тренировку?'),
        content: const Text('Вы уверены, что хотите завершить тренировку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _finishTraining,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTraining() async {
    Navigator.of(context).pop(); // Закрываем подтверждение
    try {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка завершения тренировки')),
          );
        }
      }
    } catch (e) {
      print('Error finishing training: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка завершения тренировки')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: не найден userUuid')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Упражнение "${exerciseRef.caption}" уже добавлено в тренировку',
              ),
              backgroundColor: Colors.orange,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления упражнения: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          trainingCaption,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exerciseGroups.length + 1, // +1 для кнопки
                    itemBuilder: (context, index) {
                      // Кнопка "Добавить упражнение" после всех упражнений
                      if (index == exerciseGroups.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            onPressed: _addExercise,
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить упражнение'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }

                      final group = exerciseGroups[index];
                      final userEx = group['user_exercises'] as List? ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: _buildExerciseMedia(group),
                          title: Text(
                            group['caption'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _formatUserExercises(userEx),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
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
                                      userTrainingUuid: widget.userTrainingUuid,
                                    ),
                              ),
                            );
                            _loadExerciseGroups(); // Обновляем после возврата
                          },
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showFinishConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Завершить'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
