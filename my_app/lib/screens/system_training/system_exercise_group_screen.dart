import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/exercise_model.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/exercise_info_modal.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/program_exercise_sets_table.dart'
    show ProgramExerciseSetsTable, UserExerciseRow;
import '../../constants/app_colors.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

class SystemExerciseGroupScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  final Map<String, dynamic> userTraining;
  const SystemExerciseGroupScreen({
    Key? key,
    required this.exerciseGroupUuid,
    required this.userTraining,
  }) : super(key: key);

  @override
  State<SystemExerciseGroupScreen> createState() =>
      _SystemExerciseGroupScreenState();
}

class _SystemExerciseGroupScreenState extends State<SystemExerciseGroupScreen> {
  Map<String, dynamic>? groupData;
  List<ExerciseModel> exercises = [];
  Map<String, Map<String, dynamic>> exerciseReferences =
      {}; // Хранилище данных справочника
  bool isLoading = true;
  int currentPage = 0;
  List<List<UserExerciseRow>> userExerciseRows = [];

  @override
  void initState() {
    super.initState();
    _loadGroupAndExercises();
  }

  Future<void> _loadGroupAndExercises() async {
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

            // Получаем данные из справочника упражнений
            final exerciseReferenceUuid = exJson['exercise_reference_uuid'];
            print('🔍 Загрузка справочника для упражнения $uuid:');
            print(
              '  exerciseReferenceUuid из упражнения: $exerciseReferenceUuid',
            );

            if (exerciseReferenceUuid != null) {
              try {
                final refResp = await ApiService.get(
                  '/exercise_reference/$exerciseReferenceUuid',
                );
                if (refResp.statusCode == 200) {
                  final refJson = ApiService.decodeJson(refResp.body);
                  exerciseReferences[uuid] = refJson;
                  print('📚 Получены данные справочника для упражнения $uuid:');
                  print('  refJson: $refJson');
                  print('  uuid в справочнике: ${refJson['uuid']}');
                  print(
                    '  image_uuid: ${refJson['image_uuid']}, video_uuid: ${refJson['video_uuid']}, gif_uuid: ${refJson['gif_uuid']}',
                  );
                } else {
                  print('❌ Ошибка загрузки справочника: ${refResp.statusCode}');
                }
              } catch (e) {
                print(
                  '❌ Ошибка при загрузке справочника упражнения $exerciseReferenceUuid: $e',
                );
              }
            } else {
              print('❌ exercise_reference_uuid не найден в данных упражнения');
            }
          }
        }
        setState(() {
          exercises = loaded;
          userExerciseRows = [
            for (var ex in loaded)
              List.generate(ex.setsCount, (i) => UserExerciseRow()),
          ];
          isLoading = false;
        });
        // Загружаем user_exercises для каждой строки (основные подходы)
        for (int i = 0; i < loaded.length; i++) {
          for (int set = 0; set < loaded[i].setsCount; set++) {
            _loadUserExercise(i, set, loaded[i].uuid);
          }
        }

        // Загружаем дополнительные подходы (если они существуют)
        for (int i = 0; i < loaded.length; i++) {
          await _loadAdditionalSets(i, loaded[i]);
        }

        // Загружаем предыдущие результаты для всех подходов, включая дополнительные
        for (int i = 0; i < loaded.length; i++) {
          for (int set = 0; set < userExerciseRows[i].length; set++) {
            await _loadLastUserExerciseResult(i, set, loaded[i].uuid);
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserExercise(
    int exIndex,
    int setNumber,
    String exerciseUuid,
  ) async {
    final userUuid = widget.userTraining['user']?['uuid'] ?? '';
    final trainingDate = widget.userTraining['training_date'] ?? '';
    final trainingUuid = widget.userTraining['training']?['uuid'] ?? '';
    try {
      final resp = await ApiService.get(
        '/user_exercises/',
        queryParams: {
          'user_uuid': userUuid,
          'set_number': setNumber + 1,
          'exercise_uuid': exerciseUuid,
          'training_date': trainingDate,
          'training_uuid': trainingUuid,
        },
      );
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List && data.isNotEmpty) {
          final row = data[0];
          setState(() {
            userExerciseRows[exIndex][setNumber] = UserExerciseRow(
              userExerciseUuid: row['uuid'],
              reps: row['reps'] ?? 0,
              weight: (row['weight'] ?? 0).toDouble(),
              status: row['status'] ?? 'active',
              lastResult: userExerciseRows[exIndex][setNumber].lastResult,
            );
          });
        } else {
          setState(() {
            userExerciseRows[exIndex][setNumber] = UserExerciseRow(
              lastResult: userExerciseRows[exIndex][setNumber].lastResult,
            );
          });
        }
      } else {
        setState(() {
          userExerciseRows[exIndex][setNumber] = UserExerciseRow(
            lastResult: userExerciseRows[exIndex][setNumber].lastResult,
          );
        });
      }
    } catch (_) {
      setState(() {
        userExerciseRows[exIndex][setNumber] = UserExerciseRow(
          lastResult: userExerciseRows[exIndex][setNumber].lastResult,
        );
      });
    }
  }

  /// Загружает дополнительные подходы, начиная с setsCount + 1
  /// Продолжает до тех пор, пока не получит пустой ответ
  Future<void> _loadAdditionalSets(int exIndex, ExerciseModel ex) async {
    int setNumber = ex.setsCount; // Начинаем с следующего после setsCount

    while (true) {
      final exists = await _checkAndLoadUserExercise(
        exIndex,
        setNumber,
        ex.uuid,
      );
      if (!exists) {
        // Пустой ответ - останавливаем загрузку
        break;
      }
      // Подход существует - загружаем предыдущий результат для него
      await _loadLastUserExerciseResult(exIndex, setNumber, ex.uuid);
      setNumber++; // Переходим к следующему подходу
    }
  }

  /// Проверяет существование подхода и загружает его данные
  /// Возвращает true, если подход существует, false если нет
  Future<bool> _checkAndLoadUserExercise(
    int exIndex,
    int setNumber,
    String exerciseUuid,
  ) async {
    final userUuid = widget.userTraining['user']?['uuid'] ?? '';
    final trainingDate = widget.userTraining['training_date'] ?? '';
    final trainingUuid = widget.userTraining['training']?['uuid'] ?? '';

    try {
      final resp = await ApiService.get(
        '/user_exercises/',
        queryParams: {
          'user_uuid': userUuid,
          'set_number': setNumber + 1,
          'exercise_uuid': exerciseUuid,
          'training_date': trainingDate,
          'training_uuid': trainingUuid,
        },
      );

      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List && data.isNotEmpty) {
          // Подход существует
          final row = data[0];
          if (mounted) {
            setState(() {
              // Убеждаемся, что есть место для этого подхода
              while (userExerciseRows[exIndex].length <= setNumber) {
                userExerciseRows[exIndex].add(UserExerciseRow());
              }
              // Загружаем данные подхода
              userExerciseRows[exIndex][setNumber] = UserExerciseRow(
                userExerciseUuid: row['uuid'],
                reps: row['reps'] ?? 0,
                weight: (row['weight'] ?? 0).toDouble(),
                status: row['status'] ?? 'active',
                lastResult: userExerciseRows[exIndex][setNumber].lastResult,
              );
              // Создаем новую копию списка, чтобы виджет увидел изменение
              userExerciseRows[exIndex] = List.from(userExerciseRows[exIndex]);
            });
          }
          return true;
        } else {
          // Пустой ответ - подхода не существует
          return false;
        }
      } else {
        // Ошибка - считаем, что подхода нет
        return false;
      }
    } catch (_) {
      // Ошибка - считаем, что подхода нет
      return false;
    }
  }

  Future<void> _loadLastUserExerciseResult(
    int exIndex,
    int setNumber,
    String exerciseUuid,
  ) async {
    final userUuid = widget.userTraining['user']?['uuid'] ?? '';
    final trainingDate = widget.userTraining['training_date'] ?? '';
    try {
      final resp = await ApiService.get(
        '/user_exercises/utils/getLastUserExercises',
        queryParams: {
          'user_uuid': userUuid,
          'set_number': setNumber + 1,
          'exercise_uuid': exerciseUuid,
          'training_date': trainingDate,
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
          if (data['weight'] != null && data['weight'] > 0) {
            result =
                '${data['reps'] ?? 0} x ${(data['weight'] ?? 0).toStringAsFixed(2)} кг';
          } else {
            result = '${data['reps'] ?? 0}';
          }
        }
        setState(() {
          userExerciseRows[exIndex][setNumber].lastResult = result;
        });
      } else {
        setState(() {
          userExerciseRows[exIndex][setNumber].lastResult = '0';
        });
      }
    } catch (_) {
      setState(() {
        userExerciseRows[exIndex][setNumber].lastResult = '0';
      });
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

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showExerciseInfo(ExerciseModel exercise) {
    // Получаем exercise_reference_uuid из данных упражнения
    final exerciseRef = exerciseReferences[exercise.uuid];
    final exerciseReferenceUuid =
        exerciseRef?['uuid']; // Используем uuid из справочника
    final userUuid = widget.userTraining['user']?['uuid'] ?? '';

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

    ExerciseInfoModal.show(
      context: context,
      exerciseReferenceUuid: exerciseReferenceUuid,
      userUuid: userUuid,
      exerciseName: exercise.caption, // Передаем название упражнения
    );
  }

  List<Widget> _buildGifSection(ExerciseModel exercise) {
    final exerciseRef = exerciseReferences[exercise.uuid];
    final videoUuid = exerciseRef?['video_uuid'];
    final gifUuid = exerciseRef?['gif_uuid'];
    final imageUuid = exerciseRef?['image_uuid'];

    // Если есть video_uuid, показываем видео (с превью изображением, если есть)
    if (videoUuid != null) {
      return [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayerWidget(
            videoUuid: videoUuid,
            imageUuid: imageUuid,
            width: double.infinity,
            height: 250,
            showControls: true,
            autoInitialize: true,
          ),
        ),
      ];
    }

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
      child: AuthImageWidget(
        imageUuid: imageUuid,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : exercises.isEmpty
                    ? const Center(child: Text('Нет упражнений'))
                    : Column(
                        children: [
                          // Верхняя панель с кнопкой назад и названием группы
                          Row(
                            children: [
                              const MetalBackButton(),
                              const SizedBox(width: NinjaSpacing.md),
                              Expanded(
                                child: Text(
                                  groupData?['caption'] ?? 'Группа упражнений',
                                  style: NinjaText.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: NinjaSpacing.md),
                              // Пустое место для симметрии
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Индикаторы упражнений (точечки) - над галереей
                          if (exercises.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  exercises.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index == currentPage
                                          ? AppColors.textSecondary
                                              .withOpacity(0.3)
                                          : AppColors.buttonPrimary,
                                      border: index == currentPage
                                          ? Border.all(
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.3),
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
                              onPageChanged: (i) => setState(() => currentPage = i),
                              itemBuilder: (context, index) {
                                final ex = exercises[index];
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        90,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // Название упражнения и кнопка i
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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
                                                SizedBox(
                                                  width: 36,
                                                  child: MetalButton(
                                                    label: '',
                                                    icon: Icons.info_outline,
                                                    onPressed: () =>
                                                        _showExerciseInfo(ex),
                                                    height: 36,
                                                    fontSize: 0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Гифка/видео/изображение
                                            ..._buildGifSection(ex),
                                            const SizedBox(height: 20),
                                            // Таблица подходов
                                            ProgramExerciseSetsTable(
                                              exercise: ex,
                                              initialRows: userExerciseRows[index],
                                              userUuid: widget.userTraining['user']?['uuid'],
                                              trainingDate: widget.userTraining['training_date'],
                                              trainingUuid: widget.userTraining['training']?['uuid'],
                                              isProgram: false, // Это тренировка, не программа
                                              onLoadLastResult: (setNumber) async {
                                                await _loadLastUserExerciseResult(
                                                  index,
                                                  setNumber,
                                                  ex.uuid,
                                                );
                                              },
                                              onRowsChanged: (newRows) {
                                                setState(() {
                                                  userExerciseRows[index] = newRows;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Кнопка закреплена внизу
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: MetalButton(
                                          label: 'Завершить упражнение',
                                          onPressed: userExerciseRows[index].every(
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
          ),
        ),
      ),
    );
  }
}

