import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stopwatch_overlay_provider.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import 'package:provider/provider.dart';

class FreeWorkoutExerciseGroupScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  final String trainingUuid;
  final String userTrainingUuid;

  const FreeWorkoutExerciseGroupScreen({
    Key? key,
    required this.exerciseGroupUuid,
    required this.trainingUuid,
    required this.userTrainingUuid,
  }) : super(key: key);

  @override
  State<FreeWorkoutExerciseGroupScreen> createState() =>
      _FreeWorkoutExerciseGroupScreenState();
}

class _FreeWorkoutExerciseGroupScreenState
    extends State<FreeWorkoutExerciseGroupScreen> {
  Map<String, dynamic>? exerciseData;
  Map<String, dynamic>? exerciseReference;
  Map<String, dynamic>? groupData;
  List<Map<String, dynamic>> userExercises = [];
  List<Map<String, dynamic>> lastResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    setState(() => isLoading = true);
    try {
      // Загружаем группу упражнений
      final groupResp = await ApiService.get(
        '/exercise-groups/${widget.exerciseGroupUuid}',
      );
      if (groupResp.statusCode == 200) {
        groupData = ApiService.decodeJson(groupResp.body);
        final exerciseUuid = (groupData!['exercises'] as List?)?[0];

        if (exerciseUuid != null) {
          // Загружаем данные упражнения
          final exResp = await ApiService.get('/exercises/$exerciseUuid');
          if (exResp.statusCode == 200) {
            exerciseData = ApiService.decodeJson(exResp.body);
            final refUuid = exerciseData?['exercise_reference_uuid'];

            // Загружаем справочник упражнения
            if (refUuid != null) {
              final refResp = await ApiService.get(
                '/exercise_reference/$refUuid',
              );
              if (refResp.statusCode == 200) {
                exerciseReference = ApiService.decodeJson(refResp.body);
              }
            }

            // Загружаем user_exercises
            final userExResp = await ApiService.get(
              '/user_exercises/',
              queryParams: {'exercise_uuid': exerciseUuid},
            );
            if (userExResp.statusCode == 200) {
              final loaded = List<Map<String, dynamic>>.from(
                ApiService.decodeJson(userExResp.body) ?? [],
              );
              // Сортируем подходы по set_number
              loaded.sort((a, b) {
                final setA = a['set_number'] ?? 0;
                final setB = b['set_number'] ?? 0;
                return setA.compareTo(setB);
              });
              userExercises = loaded;
            }

            // Загружаем предыдущие результаты для каждого подхода
            await _loadAllLastResults(exerciseUuid);
          }
        }
      }
    } catch (e) {
      print('Error loading exercise data: $e');
    }
    setState(() => isLoading = false);
  }

  void _addSet() async {
    final newIndex = userExercises.length;
    setState(() {
      userExercises.add({'reps': 0, 'weight': 0.0, 'completed': false});
    });

    // Загружаем предыдущий результат для нового подхода
    if (exerciseData != null) {
      final exerciseUuid = exerciseData!['uuid'];
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;
      if (userUuid != null) {
        await _loadLastResult(exerciseUuid, userUuid, newIndex + 1);
      }
    }
  }

  void _updateSet(int index, int? reps, double? weight, bool? completed) async {
    if (reps != null) {
      setState(() {
        userExercises[index]['reps'] = reps;
      });
    }
    if (weight != null) {
      setState(() {
        userExercises[index]['weight'] = weight;
      });
    }
    if (completed != null) {
      final ue = userExercises[index];
      // Если пытаемся отметить выполненным и uuid еще нет - создаем user_exercise
      if (completed && ue['uuid'] == null) {
        await _saveSet(index);
      }
      // При снятии отметки ничего не делаем - не удаляем user_exercise
    }
  }

  Future<void> _deleteAllSets() async {
    // Собираем все uuid подходов
    final uuids = userExercises
        .where((ue) => ue['uuid'] != null)
        .map((ue) => ue['uuid'] as String)
        .toList();

    if (uuids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет выполненных подходов для удаления')),
      );
      return;
    }

    // Подтверждение удаления
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(
          'Вы уверены, что хотите удалить все ${uuids.length} подходов?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Удаляем каждый подход
      int deletedCount = 0;
      for (final uuid in uuids) {
        try {
          final response = await ApiService.delete(
            '/user_exercises/delete/$uuid',
          );
          if (response.statusCode == 200) {
            deletedCount++;
          }
        } catch (e) {
          debugPrint('Ошибка удаления подхода $uuid: $e');
        }
      }

      // Обновляем UI
      setState(() {
        for (var ue in userExercises) {
          ue.remove('uuid');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Удалено подходов: $deletedCount')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Future<void> _saveSet(int index) async {
    if (exerciseData == null) return;

    final ue = userExercises[index];
    final exerciseUuid = exerciseData!['uuid'];

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: не найден userUuid')),
        );
        return;
      }

      final reps = ue['reps'] ?? 0;
      final weight = ue['weight'] ?? 0.0;

      // Формируем body для запроса
      final body = <String, dynamic>{
        'training_uuid': widget.trainingUuid,
        'user_uuid': userUuid,
        'exercise_uuid': exerciseUuid,
        'training_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'active',
        'set_number': index + 1,
        'reps': reps,
      };

      // Добавляем weight только если он не 0 и не null
      if (weight != 0 && weight != null) {
        body['weight'] = weight;
      }

      final response = await ApiService.post(
        '/user_exercises/add/',
        body: body,
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          userExercises[index]['uuid'] = data['uuid'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  bool _shouldShowDeleteButton() {
    // Кнопка не показывается, если нет ни одного user_exercise
    final hasUserExercises = userExercises.any((ue) => ue['uuid'] != null);
    if (!hasUserExercises) return false;

    // Кнопка не показывается, если есть хотя бы один подход со статусом PASSED
    final hasPassed = userExercises.any((ue) => ue['status'] == 'passed');
    if (hasPassed) return false;

    return true;
  }

  Future<void> _saveResults() async {
    try {
      // Собираем все UUID user_exercises, которые имеют uuid
      final userExerciseUuids = userExercises
          .where((ue) => ue['uuid'] != null)
          .map((ue) => ue['uuid'] as String)
          .toList();

      if (userExerciseUuids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нет выполненных подходов для сохранения'),
          ),
        );
        return;
      }

      // Отправляем PATCH запрос
      final body = {'user_exercise_uuids': userExerciseUuids};

      final response = await ApiService.patch(
        '/user_exercises/batch_set_passed',
        body: body,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Результаты сохранены')));
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  Future<void> _loadAllLastResults(String exerciseUuid) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;

      if (userUuid == null) return;

      // Загружаем последние результаты для всех подходов
      // Загружаем для каждого подхода отдельно (от 1 до количества подходов)
      for (int i = 0; i < userExercises.length; i++) {
        await _loadLastResult(exerciseUuid, userUuid, i + 1);
      }
    } catch (e) {
      print('Error loading last results: $e');
    }
  }

  Future<void> _loadLastResult(
    String exerciseUuid,
    String userUuid,
    int setNumber,
  ) async {
    try {
      final resp = await ApiService.get(
        '/user_exercises/utils/getLastUserExercises',
        queryParams: {
          'user_uuid': userUuid,
          'exercise_uuid': exerciseUuid,
          'set_number': setNumber.toString(),
          'training_date': DateTime.now().toIso8601String().split('T')[0],
        },
      );

      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        // API может возвращать как объект, так и список
        if (data is List && data.isNotEmpty) {
          setState(() {
            lastResults.add(data[0]);
          });
        } else if (data is Map) {
          setState(() {
            lastResults.add(Map<String, dynamic>.from(data));
          });
        }
      }
    } catch (e) {
      print('Error loading last result for set $setNumber: $e');
    }
  }

  String _getLastResultText(int setNumber) {
    final lastResultsForSet = lastResults
        .where((result) => result['set_number'] == setNumber)
        .toList();

    if (lastResultsForSet.isEmpty) return '--';

    // Берем последний результат
    final lastResult = lastResultsForSet.last;
    final reps = lastResult['reps'] ?? 0;
    final weight = lastResult['weight'];

    // Всегда показываем и вес и повторения для свободной тренировки
    if (weight != null) {
      return '$reps x ${(weight as num).toStringAsFixed(1)} кг';
    } else if (reps > 0) {
      return '$reps';
    } else {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupData?['caption'] ?? 'Упражнение'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exerciseData == null
          ? const Center(child: Text('Упражнение не найдено'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Изображение/GIF упражнения (показываем только если есть)
                        if (exerciseReference != null &&
                            (exerciseReference!['gif_uuid'] != null ||
                                exerciseReference!['image_uuid'] != null)) ...[
                          _buildExerciseMedia(),
                          const SizedBox(height: 16),
                        ],

                        // Название упражнения
                        Text(
                          exerciseData!['caption'] ?? 'Упражнение',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Заголовок таблицы подходов
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Text(
                                'Предыдущий результат',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Повторения и вес',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Выполнено',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Список подходов
                        ...userExercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ue = entry.value;
                          return _buildSetRow(index, ue);
                        }),

                        const SizedBox(height: 16),

                        // Кнопка добавления подхода
                        ElevatedButton.icon(
                          onPressed: _addSet,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить подход'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Кнопка удаления всех подходов (отображается только если есть подходящие подходы)
                        if (_shouldShowDeleteButton())
                          OutlinedButton.icon(
                            onPressed: _deleteAllSets,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text('Удалить все подходы'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Кнопка секундомера
                        ElevatedButton.icon(
                          onPressed: () {
                            final stopwatchProvider =
                                Provider.of<StopwatchOverlayProvider>(
                                  context,
                                  listen: false,
                                );
                            if (stopwatchProvider.isVisible) {
                              stopwatchProvider.hide();
                            } else {
                              stopwatchProvider.show();
                            }
                          },
                          icon: Consumer<StopwatchOverlayProvider>(
                            builder: (context, provider, child) {
                              return Icon(
                                provider.isVisible
                                    ? Icons.timer_off
                                    : Icons.timer,
                              );
                            },
                          ),
                          label: const Text('Секундомер'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Кнопка сохранения внизу
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
                      onPressed: _saveResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Сохранить результаты',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseMedia() {
    final gifUuid = exerciseReference?['gif_uuid'];
    final imageUuid = exerciseReference?['image_uuid'];

    if (gifUuid != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GifWidget(gifUuid: gifUuid, height: 200, width: double.infinity),
      );
    } else if (imageUuid != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AuthImageWidget(
          imageUuid: imageUuid,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputBorder.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.fitness_center, size: 80),
      );
    }
  }

  Widget _buildSetRow(int index, Map<String, dynamic> ue) {
    final reps = ue['reps'] ?? 0;
    final weight = (ue['weight'] ?? 0.0).toDouble();
    // Отметка активна если существует uuid (user_exercise уже создан)
    final completed = ue['uuid'] != null;
    final isPassed = ue['status'] == 'passed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed
            ? isPassed
                  ? Colors.green.withOpacity(0.1)
                  : AppColors.buttonPrimary.withOpacity(0.1)
            : AppColors.inputBorder.withOpacity(0.13),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          // Колонка "Предыдущий результат"
          Expanded(
            child: Center(
              child: Text(
                _getLastResultText(index + 1),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Колонка "Повторения и вес"
          Expanded(
            child: GestureDetector(
              onTap: () => _showRepsWeightPicker(index, true),
              child: Center(
                child: Text(
                  '$reps x ${weight.toStringAsFixed(1)} кг',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: IconButton(
                icon: completed
                    ? Icon(
                        isPassed ? Icons.verified : Icons.check_circle,
                        color: isPassed ? Colors.green.shade700 : Colors.green,
                        size: 32,
                      )
                    : const Icon(Icons.radio_button_unchecked, size: 32),
                onPressed: isPassed
                    ? null // Кнопка неактивна для PASSED подходов
                    : () => _updateSet(index, null, null, !completed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRepsWeightPicker(int index, bool _) {
    final ue = userExercises[index];
    final currentReps = ue['reps'] ?? 0;
    final currentWeight = (ue['weight'] ?? 0.0).toDouble();

    int selectedReps = currentReps;
    double selectedWeight = currentWeight;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Повторения',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListWheelScrollView(
                            itemExtent: 40,
                            diameterRatio: 1.5,
                            onSelectedItemChanged: (val) {
                              setModalState(() => selectedReps = val);
                            },
                            controller: FixedExtentScrollController(
                              initialItem: selectedReps,
                            ),
                            children: List.generate(101, (i) => Text('$i')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Вес (кг)', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListWheelScrollView(
                            itemExtent: 40,
                            diameterRatio: 1.5,
                            onSelectedItemChanged: (val) {
                              setModalState(() => selectedWeight = val * 0.5);
                            },
                            controller: FixedExtentScrollController(
                              initialItem: (selectedWeight / 0.5).round(),
                            ),
                            children: List.generate(
                              200,
                              (i) => Text('${i * 0.5} кг'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _updateSet(index, selectedReps, selectedWeight, null);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Готово'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
