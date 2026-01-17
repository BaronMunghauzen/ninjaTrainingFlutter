import 'package:flutter/material.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import 'weeks_days_navigation.dart'
    show WeeksDaysNavigation, WeeksDaysNavigationState;
import '../../services/training_service.dart';
import 'exercise_group_carousel_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/subscription_error_dialog.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/exercise_group_list_item.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

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
    // Проверяем подписку при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscription();
    });
    // Не делаем ничего здесь, ждем onTrainingSelected
  }

  void _checkSubscription() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile != null && userProfile.subscriptionStatus != 'active') {
      SubscriptionErrorDialog.show(
        context: context,
        barrierDismissible: false,
        onClose: () {
          Navigator.of(context).pop();
        },
      );
    }
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
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхняя панель с кнопкой назад и заголовком
                Row(
                  children: [
                    // Кнопка "Назад"
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    // Заголовок по центру
                    Expanded(
                      child: Text(
                        widget.userProgramData['caption'] ??
                            'Активная тренировка',
                        style: NinjaText.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    // Кнопка "Завершить программу"
                    MetalBackButton(
                      icon: Icons.stop,
                      onTap: () async {
                        final confirmed = await MetalModal.show<bool>(
                          context: context,
                          title: 'Завершить программу',
                          children: [
                            const Text(
                              'Вы уверены, что хотите завершить программу?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(false),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Отмена',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                MetalButton(
                                  label: 'Завершить',
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                ),
                              ],
                            ),
                          ],
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
                              MetalMessage.show(
                                context: context,
                                message: 'Не удалось завершить программу',
                                type: MetalMessageType.error,
                                title: 'Ошибка',
                                description: 'Ошибка завершения программы',
                              );
                            }
                          } catch (e) {
                            MetalMessage.show(
                              context: context,
                              message: e.toString(),
                              type: MetalMessageType.error,
                              title: 'Ошибка',
                              description:
                                  'Произошла ошибка при завершении программы',
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Навигация по неделям и дням
                Container(
                  margin: const EdgeInsets.all(16),
                  child: MetalCard(
                    child: WeeksDaysNavigation(
                      key: _navigationKey,
                      weeksCount: 4,
                      daysCount: 7,
                      isActiveProgram: true,
                      userProgramUuid: widget.userProgramData['uuid'],
                      onTrainingSelected: _onTrainingSelected,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Контент тренировки
                Expanded(child: _buildTrainingContent()),
              ],
            ),
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
            Text(
              'Поздравляем! Вы проделали большую работу. Продолжайте в том же духе',
              style: NinjaText.title.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: MetalButton(
                label: 'Продолжить',
                onPressed: _continueToNextStage,
                fontSize: 18,
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
                Text(
                  'Поздравляем! Вы проделали большую работу. Продолжайте в том же духе',
                  style: NinjaText.title.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: MetalButton(
                    label: 'Продолжить',
                    onPressed: _continueToNextStage,
                    fontSize: 18,
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
              Text(
                'Поздравляем! Вы проделали большую работу. Продолжайте в том же духе',
                style: NinjaText.title.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: MetalButton(
                  label: 'Продолжить',
                  onPressed: _continueToNextStage,
                  fontSize: 18,
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
            // Кнопка "Завершить" для дня отдыха - только если день активный
            if (status == 'active')
              SizedBox(
                width: double.infinity,
                child: MetalButton(
                  label: 'Завершить',
                  onPressed: () => _passTraining(),
                  height: 56,
                  fontSize: 16,
                  topColor: Colors.green,
                ),
              ),
            if (status == 'active') const SizedBox(height: 30),
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
              final isActiveTraining =
                  _currentTraining?['status']?.toString().toLowerCase() ==
                  'active';
              return ListView.builder(
                itemCount: _exerciseGroups.length,
                itemBuilder: (context, index) {
                  final group = _exerciseGroups[index];
                  final isFirst = index == 0;
                  final isLast = index == _exerciseGroups.length - 1;
                  return ExerciseGroupListItem(
                    group: group,
                    isActive: isActiveTraining,
                    isFirst: isFirst,
                    isLast: isLast,
                    onTap: () {
                      // Проверяем статус тренировки - можно переходить только если тренировка активна
                      if (!isActiveTraining) {
                        MetalMessage.show(
                          context: context,
                          message: 'Выполните тренировку в назначенное время.',
                          type: MetalMessageType.warning,
                          title: 'Тренировка не активна',
                          description:
                              'Выполните тренировку в назначенное время.',
                        );
                        return;
                      }

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
                    loadImage: _loadExerciseGroupImage,
                    getImageUuid: _getImageUuid,
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
                Text(
                  'Поздравляем! Вы проделали большую работу. Продолжайте в том же духе',
                  style: NinjaText.title.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  child: MetalButton(
                    label: 'Продолжить',
                    onPressed: _continueToNextStage,
                    fontSize: 18,
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
                child: MetalButton(
                  label: 'Пропустить',
                  onPressed: () => _skipTraining(),
                  height: 56,
                  fontSize: 16,
                  position: MetalButtonPosition.first,
                  topColor: Colors.red,
                ),
              ),
              // Кнопка "Завершить"
              Expanded(
                child: MetalButton(
                  label: 'Завершить',
                  onPressed: () => _passTraining(),
                  height: 56,
                  fontSize: 16,
                  position: MetalButtonPosition.last,
                  topColor: Colors.green,
                ),
              ),
            ],
          ),
        if (!isRestDay && status == 'passed')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'Тренировка завершена',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (!isRestDay && status == 'skipped')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16.0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                'Тренировка пропущена',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          child: MetalButton(
            label: 'Завершить',
            onPressed: () => _passTraining(),
            height: 56,
            fontSize: 16,
            topColor: Colors.green,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _onTrainingSelected(Map<String, dynamic>? training) {
    // Не обновляем состояние, если показывается форма поздравления
    if (_showCongrats) {
      return;
    }

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

  Future<ImageProvider?> _loadExerciseGroupImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      // Используем новый метод кэширования
      return await ApiService.getImageProvider(imageUuid);
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
  }

  String? _getImageUuid(Map<String, dynamic> group) {
    final imageUuid = group['image_uuid'];
    if (imageUuid is String && imageUuid.isNotEmpty) return imageUuid;
    return null;
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
        MetalMessage.show(
          context: context,
          message: 'Тренировка успешно пропущена',
          type: MetalMessageType.success,
          title: 'Тренировка пропущена',
          description: 'Тренировка успешно пропущена',
        );

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
        MetalMessage.show(
          context: context,
          message: 'Не удалось пропустить тренировку',
          type: MetalMessageType.error,
          title: 'Ошибка',
          description: 'Ошибка пропуска тренировки',
        );
      }
    } catch (e) {
      MetalMessage.show(
        context: context,
        message: e.toString(),
        type: MetalMessageType.error,
        title: 'Ошибка',
        description: 'Произошла ошибка при пропуске тренировки',
      );
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

      // Всегда показываем форму поздравления, независимо от ответа
      setState(() {
        _showCongrats = true;
      });

      final success = response['success'] == true;
      if (success) {
        MetalMessage.show(
          context: context,
          message: 'Тренировка успешно завершена',
          type: MetalMessageType.success,
          title: 'Тренировка завершена',
          description: 'Тренировка успешно завершена',
        );

        TrainingService.clearTrainingsCache(widget.userProgramData['uuid']);
        print('[PASS] До refreshTrainings');
        await Future.delayed(Duration(seconds: 1));
        await _navigationKey.currentState?.refreshTrainings();
        print('[PASS] После refreshTrainings');
        // НЕ вызываем goToActiveTraining(), так как нужно показать форму поздравления
        // Форма поздравления уже показана через setState выше
      } else {
        // Даже если success = false, форма поздравления уже показана
        // Не показываем сообщение об ошибке, так как форма поздравления уже отображается
      }
    } catch (e) {
      // Даже при ошибке показываем форму поздравления
      setState(() {
        _showCongrats = true;
      });
      MetalMessage.show(
        context: context,
        message: e.toString(),
        type: MetalMessageType.error,
        title: 'Ошибка',
        description: 'Произошла ошибка при завершении тренировки',
      );
    }
  }

  Future<void> _continueToNextStage() async {
    // Возвращаемся на главный экран
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
