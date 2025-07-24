import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'weeks_days_navigation.dart'
    show WeeksDaysNavigation, WeeksDaysNavigationState;
import '../../services/training_service.dart';
import 'exercise_group_carousel_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ActiveTrainingScreen extends StatefulWidget {
  final Map<String, dynamic> userProgramData;

  const ActiveTrainingScreen({Key? key, required this.userProgramData})
    : super(key: key);

  @override
  State<ActiveTrainingScreen> createState() => _ActiveTrainingScreenState();
}

class _ActiveTrainingScreenState extends State<ActiveTrainingScreen> {
  Map<String, dynamic>? _currentTraining;
  List<Map<String, dynamic>> _exerciseGroups = [];
  bool _isLoadingGroups = false;
  bool _groupsLoadedOnce = false; // <--- добавлено
  final GlobalKey<WeeksDaysNavigationState> _navigationKey =
      GlobalKey<WeeksDaysNavigationState>();
  bool _navigatedToActive = false; // чтобы не делать переход повторно
  bool _showCongrats = false; // Показывать поздравительный экран

  @override
  void initState() {
    super.initState();
    // Не делаем ничего здесь, ждем onTrainingSelected
  }

  @override
  Widget build(BuildContext context) {
    // Если тренировка уже выбрана (например, после первого build), загрузить группы
    if (_currentTraining != null &&
        _currentTraining!['training'] != null &&
        _exerciseGroups.isEmpty &&
        !_isLoadingGroups &&
        !_groupsLoadedOnce) {
      // <--- добавлено
      _loadExerciseGroups(_currentTraining!['training']['uuid']);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя панель с кнопкой назад и заголовком
              Row(
                children: [
                  // Кнопка "Назад"
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // Заголовок по центру
                  Expanded(
                    child: Text(
                      'Активная тренировка',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  // Кнопка "Завершить программу"
                  IconButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Завершить программу'),
                          content: const Text(
                            'Вы уверены, что хотите завершить программу?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Завершить'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          final success =
                              await TrainingService.finishUserProgram(
                                widget.userProgramData['uuid'],
                              );
                          if (success) {
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ошибка завершения программы'),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.stop,
                      color: AppColors.error,
                      size: 24,
                    ),
                    tooltip: 'Завершить программу',
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Навигация по неделям и дням
              WeeksDaysNavigation(
                key: _navigationKey,
                weeksCount: 4,
                daysCount: 7,
                isActiveProgram: true,
                userProgramUuid: widget.userProgramData['uuid'],
                onTrainingSelected: _onTrainingSelected,
              ),

              const SizedBox(height: 30),

              // Контент тренировки
              Expanded(child: _buildTrainingContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingContent() {
    final navState = _navigationKey.currentState;
    final trainings = navState?.trainings ?? [];
    if (_showCongrats) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.emoji_events, size: 80, color: AppColors.buttonPrimary),
            const SizedBox(height: 20),
            const Text(
              'Поздравляем! Вы проделали большую работу. Переходите к следующему этапу.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: _continueToNextStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Продолжить',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Spacer(),
          ],
        ),
      );
    }
    // Если нет ни одной тренировки или групп упражнений — явно показываем сообщение
    // Показываем сообщение только если есть тренировки, но для выбранной тренировки нет групп

    if (_currentTraining == null) {
      // Попробовать найти последнюю завершённую тренировку (28-ю)
      final totalDays = 28;
      if (trainings.isNotEmpty) {
        final lastTraining = trainings.firstWhere((t) {
          final week = t['week'] ?? 0;
          final weekday = t['weekday'] ?? 0;
          final globalDayIndex = (week - 1) * 7 + (weekday - 1);
          final status = t['status']?.toString()?.toLowerCase() ?? '';
          return (globalDayIndex == totalDays - 1) &&
              (status == 'passed' || status == 'skipped');
        }, orElse: () => <String, dynamic>{});
        if (lastTraining.isNotEmpty) {
          // Показываем поздравление и кнопку
          final week = lastTraining['week'] ?? 0;
          final weekday = lastTraining['weekday'] ?? 0;
          final status =
              lastTraining['status']?.toString()?.toLowerCase() ?? '';
          final isRestDay = lastTraining['is_rest_day'] ?? false;
          final isLastStageTrigger = true;
          final globalDayIndex = (week - 1) * 7 + (weekday - 1);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: AppColors.buttonPrimary,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Поздравляем! Вы проделали большую работу. Переходите к следующему этапу.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _continueToNextStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Продолжить',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Spacer(),
              ],
            ),
          );
        }
      }
      return const Center(
        child: Text(
          'Выберите день для просмотра тренировки',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }
    final isRestDay = _currentTraining!['is_rest_day'] ?? false;
    final status = _currentTraining!['status']?.toString()?.toLowerCase() ?? '';
    final week = _currentTraining!['week'] ?? 0;
    final weekday = _currentTraining!['weekday'] ?? 0;
    final totalDays = 28;
    final globalDayIndex = (week - 1) * 7 + (weekday - 1);
    final isLastStageTrigger =
        ((week == 4 && weekday == 7) || globalDayIndex == totalDays - 1) &&
        (status == 'passed' || status == 'skipped');
    if (isRestDay) {
      if (isLastStageTrigger) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.emoji_events,
                size: 80,
                color: AppColors.buttonPrimary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Поздравляем! Вы проделали большую работу. Переходите к следующему этапу.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _continueToNextStage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Продолжить',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Spacer(),
            ],
          ),
        );
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.bedtime, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 20),
            const Text(
              'День отдыха',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Сегодня можно отдохнуть и восстановиться',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Кнопка "Завершить" для дня отдыха
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _passTraining(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Завершить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      }
    }
    final training = _currentTraining!['training'];
    if (training == null) {
      return const Center(
        child: Text(
          'Нет данных о тренировке',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Группы упражнений
        Expanded(
          child: Builder(
            builder: (context) {
              if (_isLoadingGroups) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_exerciseGroups.isEmpty) {
                final isRestDay = _currentTraining?['is_rest_day'] ?? false;
                if (isRestDay) {
                  return _buildRestDayContent();
                } else {
                  return const SizedBox.shrink();
                }
              }
              return ListView.separated(
                itemCount: _exerciseGroups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final group = _exerciseGroups[index];
                  return GestureDetector(
                    onTap: () {
                      final userUuid = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).userUuid;
                      final trainingDate =
                          _currentTraining?['training_date'] ?? '';
                      final programUuid =
                          _currentTraining?['program']?['uuid'] ?? '';
                      final userTrainingUuid = _currentTraining?['uuid'] ?? '';
                      final trainingUuid =
                          _currentTraining?['training']?['uuid'] ?? '';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ExerciseGroupCarouselScreen(
                            exerciseGroupUuid: group['uuid'],
                            userUuid: userUuid,
                            trainingDate: trainingDate,
                            programUuid: programUuid,
                            trainingUuid: trainingUuid,
                            userTrainingUuid: userTrainingUuid,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.inputBorder,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // TODO: вставить фото группы упражнений (например, через Image.network или Image.asset)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.05),
                              // Заглушка под фото
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                group['caption'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Поздравление и кнопка "Продолжить" для последнего дня
        if (isLastStageTrigger)
          Center(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    return const SizedBox.shrink();
                  },
                ),
                const Text(
                  'Поздравляем! Вы проделали большую работу. Переходите к следующему этапу.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _continueToNextStage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Продолжить',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        // Кнопки управления тренировкой или статус
        if (!isRestDay && status == 'active')
          Row(
            children: [
              // Кнопка "Пропустить"
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _skipTraining(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Кнопка "Завершить"
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _passTraining(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Завершить',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (!isRestDay && status == 'passed')
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Тренировка завершена',
              style: TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (!isRestDay && status == 'skipped')
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Тренировка пропущена',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (isRestDay) const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildRestDayContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Icon(Icons.bedtime, size: 80, color: AppColors.textSecondary),
        const SizedBox(height: 20),
        const Text(
          'День отдыха',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Сегодня можно отдохнуть и восстановиться',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        // Кнопка "Завершить" для дня отдыха
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _passTraining(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Завершить',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _onTrainingSelected(Map<String, dynamic>? training) {
    final prevUuid = _currentTraining?['training']?['uuid'];
    final newUuid = training?['training']?['uuid'];
    setState(() {
      _currentTraining = training;
      if (prevUuid != newUuid) {
        _exerciseGroups = [];
        _groupsLoadedOnce = false; // <--- добавлено
      }
    });
    if (newUuid != null && (prevUuid != newUuid || _exerciseGroups.isEmpty)) {
      _loadExerciseGroups(newUuid);
    }
  }

  Future<void> _loadExerciseGroups(String trainingUuid) async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await TrainingService.getExerciseGroups(trainingUuid);
      if (groups.isEmpty) {
        print(
          '[DEBUG] _loadExerciseGroups: для trainingUuid= [0m$trainingUuid получен пустой список групп упражнений',
        );
      }
      setState(() {
        _exerciseGroups = groups;
        _isLoadingGroups = false;
        _groupsLoadedOnce = true; // <--- добавлено
      });
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
        _groupsLoadedOnce = true; // <--- добавлено
      });
      print('Error loading exercise groups: $e');
    }
  }

  Future<void> _skipTraining() async {
    if (_currentTraining == null) return;

    try {
      print(
        '[SKIP] Запрос skipUserTraining для uuid: \'${_currentTraining!['uuid']}\'',
      );
      final response = await TrainingService.skipUserTrainingWithResponse(
        _currentTraining!['uuid'],
      );
      print('[SKIP] Ответ skipUserTraining: $response');
      final success = response['success'] == true;
      final nextStageCreated = response['next_stage_created'] == true;
      if (success) {
        setState(() {
          _showCongrats = nextStageCreated;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка пропущена')));

        TrainingService.clearTrainingsCache(widget.userProgramData['uuid']);
        print('[SKIP] До refreshTrainings');
        await Future.delayed(Duration(seconds: 1));
        await _navigationKey.currentState?.refreshTrainings();
        print('[SKIP] После refreshTrainings, до goToActiveTraining');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('[SKIP] Внутри postFrameCallback, вызываю goToActiveTraining');
          _navigationKey.currentState?.goToActiveTraining();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка пропуска тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _passTraining() async {
    if (_currentTraining == null) return;

    try {
      print(
        '[PASS] Запрос passUserTraining для uuid: \'${_currentTraining!['uuid']}\'',
      );
      final response = await TrainingService.passUserTrainingWithResponse(
        _currentTraining!['uuid'],
      );
      print('[PASS] Ответ passUserTraining: $response');
      final success = response['success'] == true;
      final nextStageCreated = response['next_stage_created'] == true;
      if (success) {
        setState(() {
          _showCongrats = nextStageCreated;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка завершена')));

        TrainingService.clearTrainingsCache(widget.userProgramData['uuid']);
        print('[PASS] До refreshTrainings');
        await Future.delayed(Duration(seconds: 1));
        await _navigationKey.currentState?.refreshTrainings();
        print('[PASS] После refreshTrainings, до goToActiveTraining');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('[PASS] Внутри postFrameCallback, вызываю goToActiveTraining');
          _navigationKey.currentState?.goToActiveTraining();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка завершения тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _continueToNextStage() async {
    try {
      final userUuid =
          widget.userProgramData['user']?['uuid']?.toString() ?? '';
      final programUuid =
          widget.userProgramData['program']?['uuid']?.toString() ?? '';
      final newUserProgram = await TrainingService.getActiveUserProgram(
        userUuid: userUuid,
        programUuid: programUuid,
      );
      final newUserProgramUuid = newUserProgram?['uuid']?.toString() ?? '';
      final success = newUserProgramUuid.isNotEmpty;
      print(
        'RefreshUserProgramAndSchedule result: $success, newUserProgramUuid=$newUserProgramUuid',
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Программа и расписание обновлены')),
        );
        // Сброс состояния перед переходом на новый этап
        setState(() {
          _currentTraining = null;
          _exerciseGroups = [];
          _isLoadingGroups = false;
          _showCongrats = false;
          _navigatedToActive = false;
        });
        // Собираем новые userProgramData для передачи в новый этап
        final newUserProgramData = Map<String, dynamic>.from(
          newUserProgram ?? {},
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ActiveTrainingScreen(userProgramData: newUserProgramData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка обновления программы и расписания'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
