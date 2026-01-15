import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/timer_overlay_provider.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/exercise_info_modal.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/program_exercise_sets_table.dart'
    show ProgramExerciseSetsTable, UserExerciseRow;
import '../../models/exercise_model.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_spacing.dart';
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
  List<UserExerciseRow> userExerciseRows = [];
  ExerciseModel? exerciseModel;
  bool isLoading = true;
  String? savedTimerValue;

  void _showExerciseInfo() {
    final exerciseReferenceUuid = exerciseReference?['uuid'];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    final exerciseName = exerciseData?['caption'] ?? 'Упражнение';

    if (exerciseReferenceUuid == null || userUuid == null || userUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить информацию об упражнении'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ExerciseInfoModal.show(
      context: context,
      exerciseReferenceUuid: exerciseReferenceUuid,
      userUuid: userUuid,
      exerciseName: exerciseName, // Передаем название упражнения
    );
  }

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
    _loadTimerValue();
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

            // Создаем ExerciseModel
            exerciseModel = ExerciseModel.fromJson(exerciseData!);

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
              
              // Преобразуем в UserExerciseRow
              userExerciseRows = loaded.map((ue) {
                return UserExerciseRow(
                  userExerciseUuid: ue['uuid'],
                  reps: ue['reps'] ?? 0,
                  weight: (ue['weight'] ?? 0).toDouble(),
                  status: ue['status'] ?? 'active',
                  lastResult: '0',
                );
              }).toList();
              
              // Если подходов нет, создаем один пустой
              if (userExerciseRows.isEmpty) {
                userExerciseRows = [UserExerciseRow()];
              }
            } else {
              // Если нет подходов, создаем один пустой
              userExerciseRows = [UserExerciseRow()];
            }

            // Загружаем предыдущие результаты для каждого подхода
            await _loadAllLastResults(exerciseUuid);
            
            // Обновляем lastResult в userExerciseRows
            for (int i = 0; i < userExerciseRows.length; i++) {
              final lastResultText = _getLastResultText(i + 1);
              userExerciseRows[i] = UserExerciseRow(
                userExerciseUuid: userExerciseRows[i].userExerciseUuid,
                reps: userExerciseRows[i].reps,
                weight: userExerciseRows[i].weight,
                status: userExerciseRows[i].status,
                lastResult: lastResultText,
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error loading exercise data: $e');
    }
    setState(() => isLoading = false);
  }


  Future<void> _saveResults() async {
    try {
      // Собираем все UUID user_exercises, которые имеют uuid
      final userExerciseUuids = userExerciseRows
          .where((row) => row.userExerciseUuid != null)
          .map((row) => row.userExerciseUuid!)
          .toList();

      if (userExerciseUuids.isEmpty) {
        MetalMessage.show(
          context: context,
          message: 'Нет выполненных подходов для сохранения',
          type: MetalMessageType.warning,
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
          MetalMessage.show(
            context: context,
            message: 'Результаты сохранены',
            type: MetalMessageType.success,
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка сохранения: $e',
          type: MetalMessageType.error,
        );
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
      for (int i = 0; i < userExerciseRows.length; i++) {
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

  /// Загружает предыдущий результат для подхода (используется в ProgramExerciseSetsTable)
  Future<void> _loadLastUserExerciseResult(int setNumber) async {
    if (exerciseData == null) return;
    
    final exerciseUuid = exerciseData!['uuid'];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    
    if (userUuid == null) return;
    
    await _loadLastResult(exerciseUuid, userUuid, setNumber + 1);
    
    // Обновляем lastResult в userExerciseRows
    if (setNumber < userExerciseRows.length) {
      final lastResultText = _getLastResultText(setNumber + 1);
      setState(() {
        userExerciseRows[setNumber] = UserExerciseRow(
          userExerciseUuid: userExerciseRows[setNumber].userExerciseUuid,
          reps: userExerciseRows[setNumber].reps,
          weight: userExerciseRows[setNumber].weight,
          status: userExerciseRows[setNumber].status,
          lastResult: lastResultText,
        );
      });
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
      return '$reps x ${(weight as num).toStringAsFixed(2)} кг';
    } else if (reps > 0) {
      return '$reps';
    } else {
      return '--';
    }
  }

  bool _shouldShowDeleteButton() {
    // Кнопка не показывается, если нет ни одного user_exercise
    final hasUserExercises = userExerciseRows.any((row) => row.userExerciseUuid != null);
    if (!hasUserExercises) return false;

    // Кнопка не показывается, если есть хотя бы один подход со статусом PASSED
    final hasPassed = userExerciseRows.any((row) => row.status == 'passed');
    if (hasPassed) return false;

    return true;
  }

  Future<void> _deleteAllSets() async {
    // Собираем все uuid подходов
    final uuids = userExerciseRows
        .where((row) => row.userExerciseUuid != null)
        .map((row) => row.userExerciseUuid!)
        .toList();

    if (uuids.isEmpty) {
      MetalMessage.show(
        context: context,
        message: 'Нет выполненных подходов для удаления',
        type: MetalMessageType.warning,
      );
      return;
    }

    // Подтверждение удаления
    final confirm = await MetalModal.show<bool>(
      context: context,
      title: 'Подтверждение',
      children: [
        Text(
          'Вы уверены, что хотите удалить все ${uuids.length} подходов?',
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
                topColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
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

      // Перезагружаем данные подходов из API
      if (exerciseData != null && mounted) {
        final exerciseUuid = exerciseData!['uuid'];
        
        // Загружаем user_exercises заново
        final userExResp = await ApiService.get(
          '/user_exercises/',
          queryParams: {'exercise_uuid': exerciseUuid},
        );
        
        if (userExResp.statusCode == 200 && mounted) {
          final loaded = List<Map<String, dynamic>>.from(
            ApiService.decodeJson(userExResp.body) ?? [],
          );
          
          // Сортируем подходы по set_number
          loaded.sort((a, b) {
            final setA = a['set_number'] ?? 0;
            final setB = b['set_number'] ?? 0;
            return setA.compareTo(setB);
          });
          
          // Обновляем userExerciseRows
          setState(() {
            // Если есть загруженные подходы, обновляем их
            if (loaded.isNotEmpty) {
              userExerciseRows = loaded.map((ue) {
                return UserExerciseRow(
                  userExerciseUuid: ue['uuid'],
                  reps: ue['reps'] ?? 0,
                  weight: (ue['weight'] ?? 0).toDouble(),
                  status: ue['status'] ?? 'active',
                  lastResult: '0',
                );
              }).toList();
              
              // Обновляем lastResult для каждого подхода
              for (int i = 0; i < userExerciseRows.length; i++) {
                final lastResultText = _getLastResultText(i + 1);
                userExerciseRows[i] = UserExerciseRow(
                  userExerciseUuid: userExerciseRows[i].userExerciseUuid,
                  reps: userExerciseRows[i].reps,
                  weight: userExerciseRows[i].weight,
                  status: userExerciseRows[i].status,
                  lastResult: lastResultText,
                );
              }
            } else {
              // Если подходов нет, оставляем один пустой
              userExerciseRows = [UserExerciseRow()];
            }
            
            // Синхронизируем с userExercises
            userExercises = userExerciseRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return {
                'uuid': row.userExerciseUuid,
                'reps': row.reps,
                'weight': row.weight,
                'status': row.status,
                'set_number': index + 1,
              };
            }).toList();
          });
        }
      }

      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Удалено подходов: $deletedCount',
          type: MetalMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка удаления: $e',
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
              : exerciseData == null
                  ? const Center(child: Text('Упражнение не найдено'))
                  : Column(
                      children: [
                        // Верхняя панель с кнопкой назад
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              const MetalBackButton(),
                              const Spacer(),
                              // Пустое место для симметрии
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Название упражнения + кнопка информации
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        exerciseData!['caption'] ?? 'Упражнение',
                                        style: NinjaText.title,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 36,
                                      child: MetalButton(
                                        label: '',
                                        icon: Icons.info_outline,
                                        onPressed: _showExerciseInfo,
                                        height: 36,
                                        fontSize: 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Медиа упражнения (видео/гиф/картинка) — после заголовка
                                if (exerciseReference != null &&
                                    (exerciseReference!['video_uuid'] != null ||
                                        exerciseReference!['gif_uuid'] != null ||
                                        exerciseReference!['image_uuid'] != null)) ...[
                                  _buildExerciseMedia(),
                                  const SizedBox(height: 16),
                                ],

                                // Таблица подходов
                                if (exerciseModel != null) ...[
                                  ProgramExerciseSetsTable(
                                    exercise: exerciseModel!,
                                    initialRows: userExerciseRows,
                                    userUuid: Provider.of<AuthProvider>(context, listen: false).userUuid,
                                    trainingDate: DateTime.now().toIso8601String().split('T')[0],
                                    trainingUuid: widget.trainingUuid,
                                    isProgram: false,
                                    isFreeWorkout: true, // Указываем, что это свободная тренировка
                                    onLoadLastResult: (setNumber) async {
                                      await _loadLastUserExerciseResult(setNumber);
                                    },
                                    onRowsChanged: (newRows) {
                                      setState(() {
                                        userExerciseRows = newRows;
                                        // Синхронизируем с userExercises для совместимости
                                        userExercises = newRows.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final row = entry.value;
                                          return {
                                            'uuid': row.userExerciseUuid,
                                            'reps': row.reps,
                                            'weight': row.weight,
                                            'status': row.status,
                                            'set_number': index + 1,
                                          };
                                        }).toList();
                                      });
                                    },
                                  ),
                                  // Кнопка удаления всех подходов (отображается только если есть подходящие подходы)
                                  if (_shouldShowDeleteButton()) ...[
                                    const SizedBox(height: 8),
                                    MetalButton(
                                      label: 'Удалить все подходы',
                                      icon: Icons.delete_outline,
                                      onPressed: _deleteAllSets,
                                      height: 56,
                                      fontSize: 16,
                                      topColor: Colors.red,
                                    ),
                                  ],
                                ],

                                const SizedBox(height: 16),

                                // Кнопки таймера
                                Row(
                                  children: [
                                    Expanded(
                                      child: MetalButton(
                                        label: savedTimerValue != null
                                            ? 'Таймер ($savedTimerValue)'
                                            : 'Таймер',
                                        icon: Icons.timer,
                                        onPressed: _showTimerPicker,
                                        height: 56,
                                        fontSize: 16,
                                        position: savedTimerValue != null
                                            ? MetalButtonPosition.first
                                            : MetalButtonPosition.single,
                                      ),
                                    ),
                                    if (savedTimerValue != null)
                                      Expanded(
                                        child: MetalButton(
                                          label: 'Запустить',
                                          onPressed: _startTimerWithSavedValue,
                                          height: 56,
                                          fontSize: 16,
                                          position: MetalButtonPosition.last,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),

                        // Кнопка завершения внизу
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: MetalButton(
                            label: 'Завершить упражнение',
                            onPressed: _saveResults,
                            height: 56,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildExerciseMedia() {
    final videoUuid = exerciseReference?['video_uuid'];
    final gifUuid = exerciseReference?['gif_uuid'];
    final imageUuid = exerciseReference?['image_uuid'];

    if (videoUuid != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(
          videoUuid: videoUuid,
          imageUuid: imageUuid,
          height: 200,
          width: double.infinity,
          showControls: true,
          autoInitialize: true,
        ),
      );
    } else if (gifUuid != null) {
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


  Future<void> _loadTimerValue() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;

      if (userUuid == null || userUuid.isEmpty) return;

      final resp = await ApiService.get(
        '/last-values/',
        queryParams: {
          'user_uuid': userUuid,
          'code': 'timerInFreeTraining',
          'actual': 'true',
        },
      );

      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List && data.isNotEmpty) {
          final value = data[0]['value'] as String?;
          if (mounted) {
            setState(() {
              savedTimerValue = value;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading timer value: $e');
    }
  }

  Future<void> _saveTimerValue(String value) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;

      if (userUuid == null || userUuid.isEmpty) return;

      final body = {
        'user_uuid': userUuid,
        'name': 'Значение таймера из свободных тренировок',
        'code': 'timerInFreeTraining',
        'value': value,
      };

      final resp = await ApiService.post('/last-values/', body: body);

      if (resp.statusCode == 200) {
        // После успешного сохранения загружаем обновленное значение
        await _loadTimerValue();
      }
    } catch (e) {
      debugPrint('Error saving timer value: $e');
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return minutes * 60 + seconds;
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return 0;
  }

  void _startTimerWithSavedValue() {
    if (savedTimerValue == null) return;

    final totalSeconds = _parseTime(savedTimerValue!);
    if (totalSeconds == 0) return;

    final timerProvider = Provider.of<TimerOverlayProvider>(
      context,
      listen: false,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;

    final exerciseUuid = exerciseData != null ? exerciseData!['uuid'] : null;
    final exerciseName = exerciseData != null ? exerciseData!['caption'] : null;

    timerProvider.show(
      totalSeconds,
      userUuid: userUuid?.isNotEmpty == true ? userUuid : null,
      exerciseUuid: exerciseUuid is String ? exerciseUuid : null,
      exerciseName: exerciseName is String ? exerciseName : null,
    );
  }

  void _showTimerPicker() {
    // Парсим сохраненное значение для предзаполнения
    int initialMinutes = 0;
    int initialSeconds = 0;
    
    if (savedTimerValue != null) {
      final totalSeconds = _parseTime(savedTimerValue!);
      initialMinutes = totalSeconds ~/ 60;
      initialSeconds = totalSeconds % 60;
    }

    int selectedMinutes = initialMinutes;
    int selectedSeconds = initialSeconds;

    final minuteController = FixedExtentScrollController(initialItem: initialMinutes);
    final secondController = FixedExtentScrollController(initialItem: initialSeconds);

    MetalModal.show(
      context: context,
      title: 'Выберите время отдыха',
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            final textStyle = const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: NinjaSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TimerPickerColumn(
                      title: 'Минуты',
                      controller: minuteController,
                      onSelectedItemChanged: (value) {
                        setModalState(() {
                          selectedMinutes = value;
                        });
                      },
                      textStyle: textStyle,
                    ),
                    _TimerPickerColumn(
                      title: 'Секунды',
                      controller: secondController,
                      onSelectedItemChanged: (value) {
                        setModalState(() {
                          selectedSeconds = value;
                        });
                      },
                      textStyle: textStyle,
                    ),
                  ],
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
                        label: 'Запустить таймер',
                        onPressed: () async {
                          final totalSeconds =
                              selectedMinutes * 60 + selectedSeconds;
                          if (totalSeconds == 0) {
                            MetalMessage.show(
                              context: context,
                              message: 'Выберите время больше 0 секунд',
                              type: MetalMessageType.warning,
                            );
                            return;
                          }

                          final timerProvider = Provider.of<TimerOverlayProvider>(
                            context,
                            listen: false,
                          );

                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final userUuid = authProvider.userUuid;

                          final exerciseUuid = exerciseData != null
                              ? exerciseData!['uuid']
                              : null;
                          final exerciseName = exerciseData != null
                              ? exerciseData!['caption']
                              : null;

                          timerProvider.show(
                            totalSeconds,
                            userUuid: userUuid?.isNotEmpty == true
                                ? userUuid
                                : null,
                            exerciseUuid: exerciseUuid is String
                                ? exerciseUuid
                                : null,
                            exerciseName: exerciseName is String
                                ? exerciseName
                                : null,
                          );

                          // Сохраняем значение таймера
                          final timeValue = _formatTime(totalSeconds);
                          await _saveTimerValue(timeValue);

                          Navigator.of(context).pop();
                        },
                        height: 56,
                        fontSize: 16,
                        position: MetalButtonPosition.last,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TimerPickerColumn extends StatelessWidget {
  final String title;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onSelectedItemChanged;
  final TextStyle textStyle;

  const _TimerPickerColumn({
    Key? key,
    required this.title,
    required this.controller,
    required this.onSelectedItemChanged,
    required this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>.generate(
      60,
      (index) => Center(child: Text(index.toString(), style: textStyle)),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          width: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 46,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: 1.3,
              onSelectedItemChanged: onSelectedItemChanged,
              childDelegate: ListWheelChildLoopingListDelegate(children: items),
            ),
          ),
        ),
      ],
    );
  }
}
