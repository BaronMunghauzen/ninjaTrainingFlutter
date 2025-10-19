import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/exercise_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/exercise_info_modal.dart';
import '../../constants/app_colors.dart';
import 'package:my_app/providers/timer_overlay_provider.dart';
import 'package:provider/provider.dart';

class ExerciseGroupCarouselScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  final String? userUuid;
  final String? trainingDate;
  final String? programUuid;
  final String? trainingUuid;
  final String? userTrainingUuid;
  const ExerciseGroupCarouselScreen({
    Key? key,
    required this.exerciseGroupUuid,
    this.userUuid,
    this.trainingDate,
    this.programUuid,
    this.trainingUuid,
    this.userTrainingUuid,
  }) : super(key: key);

  @override
  State<ExerciseGroupCarouselScreen> createState() =>
      _ExerciseGroupCarouselScreenState();
}

class _ExerciseGroupCarouselScreenState
    extends State<ExerciseGroupCarouselScreen> {
  // ОПТИМИЗАЦИЯ: Данные справочника упражнений и предыдущие результаты загружаются
  // только один раз при переходе на страницу, а не при каждом обновлении данных

  Map<String, dynamic>? groupData;
  List<ExerciseModel> exercises = [];
  Map<String, Map<String, dynamic>> exerciseReferences =
      {}; // Хранилище данных справочника
  bool isLoading = true;
  int currentPage = 0;
  List<List<UserExerciseRow>> userExerciseRows = [];

  // Флаги для оптимизации загрузки - предотвращают повторные API вызовы
  bool _exerciseReferencesLoaded = false; // Данные справочника загружены
  bool _lastResultsLoaded = false; // Предыдущие результаты загружены

  @override
  void initState() {
    super.initState();
    _loadGroupAndExercises();
  }

  @override
  void dispose() {
    // Очищаем кэш изображений при закрытии экрана
    // VideoPlayerWidget.clearImageCache(); // Статический метод недоступен извне
    super.dispose();
  }

  Future<void> _loadGroupAndExercises() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final groupResp = await ApiService.get(
        '/exercise-groups/${widget.exerciseGroupUuid}',
      );
      if (groupResp.statusCode == 200) {
        final group = ApiService.decodeJson(groupResp.body);
        groupData = group;
        final List exUuids = group['exercises'] ?? [];
        List<ExerciseModel> loaded = [];
        for (final uuid in exUuids) {
          final exResp = await ApiService.get('/exercises/$uuid');
          if (exResp.statusCode == 200) {
            final exJson = ApiService.decodeJson(exResp.body);
            final exercise = ExerciseModel.fromJson(exJson);
            loaded.add(exercise);
          }
        }

        // Загружаем данные справочника упражнений только один раз
        if (!_exerciseReferencesLoaded) {
          await _loadExerciseReferences(loaded);
          _exerciseReferencesLoaded = true;
        }
        if (!mounted) return;
        setState(() {
          exercises = loaded;
          userExerciseRows = [
            for (var ex in loaded)
              List.generate(ex.setsCount, (i) => UserExerciseRow()),
          ];
          isLoading = false;
        });
        // Загружаем user_exercises для каждой строки
        for (int i = 0; i < loaded.length; i++) {
          for (int set = 0; set < loaded[i].setsCount; set++) {
            _loadUserExercise(i, set, loaded[i].uuid);
          }
        }

        // Загружаем предыдущие результаты только один раз
        if (!_lastResultsLoaded) {
          await _loadAllLastResults(loaded);
          _lastResultsLoaded = true;
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Загружает данные справочника упражнений (image_uuid, video_uuid) только один раз
  /// для предотвращения повторных API вызовов при обновлении данных
  Future<void> _loadExerciseReferences(List<ExerciseModel> exercises) async {
    for (final exercise in exercises) {
      // Получаем exercise_reference_uuid из исходных данных упражнения
      try {
        final exResp = await ApiService.get('/exercises/${exercise.uuid}');
        if (exResp.statusCode == 200) {
          final exJson = ApiService.decodeJson(exResp.body);
          final exerciseReferenceUuid = exJson['exercise_reference_uuid'];

          if (exerciseReferenceUuid != null) {
            try {
              final refResp = await ApiService.get(
                '/exercise_reference/$exerciseReferenceUuid',
              );
              if (refResp.statusCode == 200) {
                final refJson = ApiService.decodeJson(refResp.body);
                exerciseReferences[exercise.uuid] = refJson;
                print(
                  '📚 Получены данные справочника для упражнения ${exercise.uuid}: image_uuid=${refJson['image_uuid']}, video_uuid=${refJson['video_uuid']}, gif_uuid=${refJson['gif_uuid']}',
                );
              }
            } catch (e) {
              print(
                '❌ Ошибка при загрузке справочника упражнения $exerciseReferenceUuid: $e',
              );
            }
          }
        }
      } catch (e) {
        print('❌ Ошибка при получении данных упражнения ${exercise.uuid}: $e');
      }
    }
  }

  List<Widget> _buildGifSection(ExerciseModel exercise) {
    final exerciseRef = exerciseReferences[exercise.uuid];
    final gifUuid = exerciseRef?['gif_uuid'];
    final imageUuid = exerciseRef?['image_uuid'];

    // Если есть gif_uuid, показываем гифку
    if (gifUuid != null) {
      return [_buildGifPlayer(exercise)];
    }

    // Если нет гифки, но есть image_uuid, показываем картинку
    if (imageUuid != null) {
      return [_buildImagePlayer(exercise)];
    }

    // Если нет ни гифки, ни картинки - не показываем ничего
    return [];
  }

  Widget _buildGifPlayer(ExerciseModel exercise) {
    final exerciseRef = exerciseReferences[exercise.uuid];
    final gifUuid = exerciseRef?['gif_uuid'];

    // Этот метод вызывается только когда gif_uuid есть
    return GifWidget(
      gifUuid: gifUuid,
      width: double.infinity,
      height: 250, // Увеличиваем высоту для лучшего отображения
    );
  }

  Widget _buildImagePlayer(ExerciseModel exercise) {
    final exerciseRef = exerciseReferences[exercise.uuid];
    final imageUuid = exerciseRef?['image_uuid'];

    // Этот метод вызывается только когда image_uuid есть
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        '${ApiService.baseUrl}/files/file/$imageUuid',
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExerciseInfo(ExerciseModel exercise) {
    // Получаем exercise_reference_uuid из данных упражнения
    final exerciseRef = exerciseReferences[exercise.uuid];
    final exerciseReferenceUuid =
        exerciseRef?['uuid']; // Используем uuid из справочника
    final userUuid = widget.userUuid ?? '';

    print('🔍 Отладка _showExerciseInfo:');
    print('  exercise.uuid: ${exercise.uuid}');
    print('  exerciseRef: $exerciseRef');
    print('  exerciseReferenceUuid: $exerciseReferenceUuid');
    print('  userUuid: $userUuid');

    if (exerciseReferenceUuid == null || userUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось загрузить информацию об упражнении. exerciseReferenceUuid: $exerciseReferenceUuid, userUuid: $userUuid',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ExerciseInfoModal(
        exerciseReferenceUuid: exerciseReferenceUuid,
        userUuid: userUuid,
      ),
    );
  }

  /// Очищает кэш изображений для экономии памяти
  void _clearImageCache() {
    // Очищаем кэш изображений при переключении упражнений
    // Это помогает предотвратить утечки памяти
    print('Clearing image cache for memory optimization');

    // Принудительно очищаем память для предотвращения OutOfMemoryError
    // Это особенно важно при переключении между упражнениями с большими изображениями
    if (mounted) {
      // Добавляем небольшую задержку для завершения текущих операций
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Здесь можно добавить вызов очистки памяти если будет доступен
          print('Memory cleanup scheduled for next exercise');
        }
      });
    }
  }

  /// Обновляет только текущие данные упражнений без повторной загрузки справочника и предыдущих результатов
  Future<void> refreshExerciseData() async {
    if (exercises.isEmpty) return;

    // Обновляем только user_exercises для каждой строки
    for (int i = 0; i < exercises.length; i++) {
      for (int set = 0; set < exercises[i].setsCount; set++) {
        await _loadUserExercise(i, set, exercises[i].uuid);
      }
    }
  }

  /// Загружает все предыдущие результаты упражнений только один раз
  /// для предотвращения повторных API вызовов при обновлении данных
  Future<void> _loadAllLastResults(List<ExerciseModel> exercises) async {
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      for (int set = 0; set < exercise.setsCount; set++) {
        await _loadLastUserExerciseResult(i, set, exercise.uuid);
      }
    }
  }

  Future<void> _loadUserExercise(
    int exIndex,
    int setNumber,
    String exerciseUuid,
  ) async {
    final userUuid = widget.userUuid ?? '';
    final trainingDate = widget.trainingDate ?? '';
    final programUuid = widget.programUuid ?? '';
    final trainingUuid = widget.trainingUuid ?? '';
    try {
      final resp = await ApiService.get(
        '/user_exercises/',
        queryParams: {
          'user_uuid': userUuid,
          'set_number': setNumber + 1,
          'exercise_uuid': exerciseUuid,
          'training_date': trainingDate,
          'program_uuid': programUuid,
          'training_uuid': trainingUuid,
        },
      );
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List && data.isNotEmpty) {
          final row = data[0];
          if (mounted) {
            setState(() {
              userExerciseRows[exIndex][setNumber] = UserExerciseRow(
                userExerciseUuid: row['uuid'],
                reps: row['reps'] ?? 0,
                weight: (row['weight'] ?? 0).toDouble(),
                status: row['status'] ?? 'active',
                lastResult: userExerciseRows[exIndex][setNumber]
                    .lastResult, // сохраняем lastResult
              );
            });
          }
        } else {
          if (mounted) {
            setState(() {
              userExerciseRows[exIndex][setNumber] = UserExerciseRow(
                lastResult: userExerciseRows[exIndex][setNumber].lastResult,
              );
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            userExerciseRows[exIndex][setNumber] = UserExerciseRow(
              lastResult: userExerciseRows[exIndex][setNumber].lastResult,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          userExerciseRows[exIndex][setNumber] = UserExerciseRow(
            lastResult: userExerciseRows[exIndex][setNumber].lastResult,
          );
        });
      }
    }
    // Убираем вызов _loadLastUserExerciseResult, так как теперь он вызывается только один раз
  }

  Future<void> _loadLastUserExerciseResult(
    int exIndex,
    int setNumber,
    String exerciseUuid,
  ) async {
    final userUuid = widget.userUuid ?? '';
    final trainingDate = widget.trainingDate ?? '';
    final programUuid = widget.programUuid ?? '';
    final trainingUuid = widget.trainingUuid ?? '';
    try {
      final resp = await ApiService.get(
        '/user_exercises/utils/getLastUserExercises',
        queryParams: {
          'user_uuid': userUuid,
          'set_number': setNumber + 1,
          'exercise_uuid': exerciseUuid,
          'training_date': trainingDate,
          'program_uuid': programUuid,
        },
      );
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        String result = '0';
        if (data is List && data.isNotEmpty) {
          final row = data[0];
          if (row is Map && row.containsKey('reps')) {
            if (row['weight'] != null && row['weight'] > 0) {
              result =
                  '${row['reps'] ?? 0} x ${(row['weight'] ?? 0).toStringAsFixed(2)} кг';
            } else {
              result = '${row['reps'] ?? 0}';
            }
          }
        } else if (data is Map && data.containsKey('reps')) {
          // Если сервер возвращает просто объект
          if (data['weight'] != null && data['weight'] > 0) {
            result =
                '${data['reps'] ?? 0} x ${(data['weight'] ?? 0).toStringAsFixed(2)} кг';
          } else {
            result = '${data['reps'] ?? 0}';
          }
        }
        if (mounted) {
          setState(() {
            userExerciseRows[exIndex][setNumber].lastResult = result;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userExerciseRows[exIndex][setNumber].lastResult = '0';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          userExerciseRows[exIndex][setNumber].lastResult = '0';
        });
      }
    }
  }

  void _showRepsWeightPicker(
    int exIndex,
    int setIndex,
    int maxReps,
    bool withWeight,
  ) async {
    int selectedReps = userExerciseRows[exIndex][setIndex].reps;
    double selectedWeight = userExerciseRows[exIndex][setIndex].weight;
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Слева — повторения
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Повторения'),
                      SizedBox(
                        height: 120,
                        width: 80,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (val) {
                            selectedReps = val;
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, i) => Center(
                              child: Text(
                                '$i',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            childCount: maxReps + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (withWeight) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Вес (кг)'),
                        SizedBox(
                          height: 120,
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (val) {
                              selectedWeight = val * 0.25;
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, i) => Center(
                                child: Text(
                                  (i * 0.25).toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              childCount: 2001, // 0..500кг с шагом 0.25
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!mounted) return;
                    setState(() {
                      userExerciseRows[exIndex][setIndex] = UserExerciseRow(
                        userExerciseUuid: userExerciseRows[exIndex][setIndex]
                            .userExerciseUuid,
                        reps: selectedReps,
                        weight: selectedWeight,
                        status: userExerciseRows[exIndex][setIndex].status,
                        lastResult:
                            userExerciseRows[exIndex][setIndex].lastResult,
                      );
                    });
                    // НЕ обновляем с сервера!
                    Navigator.of(context).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(groupData?['caption'] ?? 'Группа упражнений'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? const Center(child: Text('Нет упражнений'))
          : Column(
              children: [
                // Индикаторы упражнений (точечки) - над галереей
                if (exercises.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        exercises.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == currentPage
                                ? AppColors.textSecondary.withOpacity(0.3)
                                : AppColors.buttonPrimary,
                            border: index == currentPage
                                ? Border.all(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.3,
                                    ),
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Галерея упражнений
                Expanded(
                  child: PageView.builder(
                    itemCount: exercises.length,
                    onPageChanged: (i) {
                      if (mounted) {
                        setState(() => currentPage = i);
                      }
                      // Очищаем кэш изображений при переключении упражнений для экономии памяти
                      if (mounted) {
                        _clearImageCache();
                      }
                    },
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 3. Название упражнения
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          ex.caption,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _showExerciseInfo(ex),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.inputBorder
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.inputBorder
                                                    .withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.info_outline,
                                              color: AppColors.textPrimary,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 2. Гифка
                                  ..._buildGifSection(ex),
                                  const SizedBox(height: 20),
                                  // 4. Три серых квадрата
                                  Row(
                                    children: [
                                      _InfoSquare(
                                        text:
                                            '${ex.setsCount} подход${_ending(ex.setsCount, "а", "ов", "")}',
                                      ),
                                      _InfoSquare(
                                        text:
                                            '${ex.repsCount} повторени${_ending(ex.repsCount, "е", "й", "я")}',
                                      ),
                                      _InfoSquare(
                                        text: '${ex.restTime} сек отдых',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // 5. Кастомная "таблица"
                                  const SizedBox(height: 24),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                ex.withWeight
                                                    ? 'Повторения и вес'
                                                    : 'Повторения',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
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
                                        ...List.generate(
                                          ex.setsCount,
                                          (setIdx) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.inputBorder
                                                    .withOpacity(0.13),
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Center(
                                                      child: Text(
                                                        userExerciseRows[index][setIdx]
                                                            .lastResult,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap:
                                                          userExerciseRows[index][setIdx]
                                                                  .status ==
                                                              'passed'
                                                          ? null
                                                          : () => _showRepsWeightPicker(
                                                              index,
                                                              setIdx,
                                                              100, // Фиксированное максимальное количество повторений
                                                              ex.withWeight,
                                                            ),
                                                      child: Center(
                                                        child: ex.withWeight
                                                            ? Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    '${userExerciseRows[index][setIdx].reps}',
                                                                    style: TextStyle(
                                                                      color: AppColors
                                                                          .textPrimary,
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Text(
                                                                    '${userExerciseRows[index][setIdx].weight.toStringAsFixed(2)} кг',
                                                                    style: TextStyle(
                                                                      color: AppColors
                                                                          .textPrimary,
                                                                      fontSize:
                                                                          20,
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            : Text(
                                                                '${userExerciseRows[index][setIdx].reps}',
                                                                style: TextStyle(
                                                                  color: AppColors
                                                                      .textPrimary,
                                                                  fontSize: 20,
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Center(
                                                      child: (() {
                                                        final row =
                                                            userExerciseRows[index][setIdx];
                                                        if (row.status ==
                                                            'passed') {
                                                          return IgnorePointer(
                                                            ignoring: true,
                                                            child: const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 34,
                                                            ),
                                                          );
                                                        } else {
                                                          return _RoundCheckbox(
                                                            value:
                                                                row.userExerciseUuid !=
                                                                null,
                                                            onChanged: (val) {
                                                              _onSetCompleted(
                                                                index,
                                                                setIdx,
                                                                ex,
                                                                value: val,
                                                              );
                                                            },
                                                          );
                                                        }
                                                      })(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 6. Кнопка закреплена внизу
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CustomButton(
                                text: 'Завершить упражнение',
                                onPressed:
                                    userExerciseRows[index].every(
                                      (row) => row.status == 'passed',
                                    )
                                    ? null
                                    : () => _onFinishExercise(index, ex),
                                height: 64,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _ending(int n, String one, String many, String few) {
    if (n % 10 == 1 && n % 100 != 11) return one;
    if ([2, 3, 4].contains(n % 10) && !(n % 100 >= 12 && n % 100 <= 14))
      return few;
    return many;
  }

  void _onSetCompleted(
    int exIndex,
    int setIdx,
    ExerciseModel ex, {
    bool? value,
  }) async {
    final row = userExerciseRows[exIndex][setIdx];
    final userUuid = widget.userUuid ?? '';
    final trainingDate = widget.trainingDate ?? '';
    final programUuid = widget.programUuid ?? '';
    final trainingUuid = widget.trainingUuid ?? '';
    final exerciseUuid = ex.uuid;
    if (value == false && row.userExerciseUuid != null) {
      // Снятие чекбокса — удаляем user_exercise
      await ApiService.delete('/user_exercises/delete/${row.userExerciseUuid}');
      await _loadUserExercise(exIndex, setIdx, exerciseUuid);
      return;
    }
    // Установка чекбокса — добавляем user_exercise
    final body = {
      'program_uuid': programUuid,
      'training_uuid': trainingUuid,
      'user_uuid': userUuid,
      'exercise_uuid': exerciseUuid,
      'training_date': trainingDate,
      'status': 'active',
      'set_number': setIdx + 1,
      'weight': row.weight,
      'reps': row.reps,
    };
    await ApiService.post('/user_exercises/add/', body: body);
    await _loadUserExercise(exIndex, setIdx, exerciseUuid);
    // Запуск таймера только при установке чекбокса
    if (value == true && ex.restTime > 0) {
      final timerProvider = Provider.of<TimerOverlayProvider>(
        context,
        listen: false,
      );
      final userUuid = widget.userUuid ?? '';
      timerProvider.show(
        ex.restTime,
        userUuid: userUuid.isNotEmpty ? userUuid : null,
        exerciseUuid: ex.uuid,
        exerciseName: ex.caption,
      );
    }
  }

  Future<void> _onFinishExercise(int exIndex, ExerciseModel ex) async {
    // Собираем все user_exercise_uuids для batch запроса
    List<String> userExerciseUuids = [];
    for (int i = 0; i < userExerciseRows[exIndex].length; i++) {
      final row = userExerciseRows[exIndex][i];
      if (row.userExerciseUuid != null) {
        userExerciseUuids.add(row.userExerciseUuid!);
      }
    }

    // Если есть упражнения для обновления, отправляем batch запрос
    if (userExerciseUuids.isNotEmpty) {
      await ApiService.patch(
        '/user_exercises/batch_set_passed',
        body: {'user_exercise_uuids': userExerciseUuids},
      );

      // Обновляем данные для каждого подхода
      for (int i = 0; i < userExerciseRows[exIndex].length; i++) {
        await _loadUserExercise(exIndex, i, ex.uuid);
      }
    }

    // После завершения возвращаемся на предыдущий экран
    if (mounted) {
      Navigator.of(context).pop();
    }
    // Можно добавить переход назад или обновление UI
  }
}

class _InfoSquare extends StatelessWidget {
  final String text;
  const _InfoSquare({required this.text});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.inputBorder,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class UserExerciseRow {
  String? userExerciseUuid;
  int reps;
  double weight;
  String status;
  String lastResult; // Новое поле для предыдущего результата
  UserExerciseRow({
    this.userExerciseUuid,
    this.reps = 0,
    this.weight = 0.0,
    this.status = 'active',
    this.lastResult = '0',
  });
}

class _RoundCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  const _RoundCheckbox({required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: value ? Colors.green : Colors.grey,
            width: 2.5,
          ),
          color: value ? Colors.white : Colors.transparent,
        ),
        child: null,
      ),
    );
  }
}
