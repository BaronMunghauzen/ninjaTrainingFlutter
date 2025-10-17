import 'package:flutter/material.dart';
import '../../services/training_service.dart';
import '../../constants/app_colors.dart';

class WeeksDaysNavigation extends StatefulWidget {
  final int weeksCount;
  final int daysCount;
  final int? selectedWeek;
  final int? selectedDay;
  final void Function(int week)? onWeekTap;
  final void Function(int day)? onDayTap;
  final double? weekTabWidth;
  final bool isActiveProgram;
  final String? userProgramUuid;
  final Function(Map<String, dynamic>? training)? onTrainingSelected;

  const WeeksDaysNavigation({
    Key? key,
    this.weeksCount = 4,
    this.daysCount = 7,
    this.selectedWeek,
    this.selectedDay,
    this.onWeekTap,
    this.onDayTap,
    this.weekTabWidth,
    this.isActiveProgram = false,
    this.userProgramUuid,
    this.onTrainingSelected,
  }) : super(key: key);

  @override
  State<WeeksDaysNavigation> createState() => WeeksDaysNavigationState();
}

class WeeksDaysNavigationState extends State<WeeksDaysNavigation> {
  List<Map<String, dynamic>> trainings = [];
  bool _isLoading = false;
  int currentWeek = 0; // Для визуального отображения
  int currentDay = 0; // Для визуального отображения
  int currentDayIndex = 0; // Общий индекс дня в полотне (0-27)
  String? _lastLoadedUserProgramUuid; // Для предотвращения зацикливания
  final ScrollController _weekScrollController = ScrollController();
  final ScrollController _dayScrollController = ScrollController();

  // Оптимизация: индексация тренировок для быстрого доступа
  Map<String, Map<String, dynamic>> _trainingsIndex = {};

  // Оптимизация: карта статусов для всех 28 дней
  Map<int, Map<String, dynamic>> _allDaysStatusCache = {};

  // Кэш стилей для всех дней (0-27)
  Map<int, Map<String, dynamic>> _allDaysStylesCache = {};

  @override
  void dispose() {
    _weekScrollController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActiveProgram && widget.userProgramUuid != null) {
      _loadTrainings();
    }
  }

  @override
  void didUpdateWidget(WeeksDaysNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveProgram &&
        widget.userProgramUuid != null &&
        widget.userProgramUuid != _lastLoadedUserProgramUuid) {
      _loadTrainings();
    }
  }

  // Оптимизация: создание индекса тренировок для быстрого доступа
  void _buildTrainingsIndex() {
    _trainingsIndex.clear();
    for (final training in trainings) {
      final week = training['week']?.toString() ?? '';
      final weekday = training['weekday']?.toString() ?? '';
      final key = '$week:$weekday';
      _trainingsIndex[key] = training;
    }
  }

  // Оптимизация: создание карты статусов для всех 28 дней сразу
  void _buildAllDaysStatusCache() {
    _allDaysStatusCache.clear();
    final totalDays = widget.weeksCount * widget.daysCount;

    for (int dayIndex = 0; dayIndex < totalDays; dayIndex++) {
      final training = _getTrainingByDayIndex(dayIndex);
      _allDaysStatusCache[dayIndex] = {
        'training': training,
        'status': training?['status'],
        'isRestDay': training?['is_rest_day'] ?? false,
      };
    }
  }

  // Оптимизация: получение тренировки по индексу дня O(1)
  Map<String, dynamic>? _getTrainingByDayIndex(int dayIndex) {
    final week = (dayIndex ~/ 7) + 1;
    final weekday = (dayIndex % 7) + 1;
    final key = '$week:$weekday';
    return _trainingsIndex[key];
  }

  // Оптимизация: получение статуса дня из кэша
  Map<String, dynamic>? _getDayStatus(int dayIndex) {
    return _allDaysStatusCache[dayIndex];
  }

  // Оптимизация: обновление кэша стилей для всех дней
  void _updateAllDaysStylesCache() {
    _allDaysStylesCache.clear();
    final totalDays = widget.weeksCount * widget.daysCount;
    for (int globalDayIndex = 0; globalDayIndex < totalDays; globalDayIndex++) {
      final dayStatus = _getDayStatus(globalDayIndex);
      _allDaysStylesCache[globalDayIndex] = {
        'background': _calculateBackgroundColor(dayStatus),
        'border': _calculateBorderColor(
          dayStatus,
          globalDayIndex % widget.daysCount,
        ),
        'text': _calculateTextColor(dayStatus, globalDayIndex),
        'borderWidth': _calculateBorderWidth(
          dayStatus,
          globalDayIndex % widget.daysCount,
        ),
        'status': dayStatus?['status'],
      };
    }
  }

  Color _calculateBackgroundColor(Map<String, dynamic>? dayStatus) {
    if (!widget.isActiveProgram) {
      return Colors.transparent;
    }

    if (dayStatus == null) {
      return Colors.transparent;
    }

    String status = dayStatus['status']?.toString().toLowerCase() ?? 'null';

    switch (status) {
      case 'passed':
        return Colors.green.withOpacity(0.2); // Зеленый фон для завершенных
      case 'active':
        return Colors.blue.withOpacity(0.2); // Синий фон для активных
      case 'skipped':
        return Colors.red.withOpacity(0.2); // Красный фон для пропущенных
      case 'blocked_yet':
        return Colors.grey.withOpacity(0.1); // Серый фон для заблокированных
      default:
        return Colors.transparent;
    }
  }

  Color _calculateBorderColor(Map<String, dynamic>? dayStatus, int dayIndex) {
    String status = dayStatus?['status']?.toString().toLowerCase() ?? 'null';
    Color result;

    if (!widget.isActiveProgram) {
      result = currentDay == dayIndex
          ? AppColors.buttonPrimary
          : Colors.grey[700]!;
      return result;
    }

    if (dayStatus == null) {
      result = currentDay == dayIndex
          ? AppColors.buttonPrimary
          : Colors.grey[700]!;
      return result;
    }

    // Цвета границ для разных статусов
    switch (status) {
      case 'passed':
        result = Colors.green; // Зеленая граница для завершенных
        break;
      case 'active':
        result = Colors.blue; // Синяя граница для активных
        break;
      case 'skipped':
        result = Colors.red; // Красная граница для пропущенных
        break;
      case 'blocked_yet':
        result = Colors.grey[600]!; // Серая граница для заблокированных
        break;
      default:
        result = currentDay == dayIndex ? Colors.blueAccent : Colors.grey[700]!;
    }

    return result;
  }

  Color _calculateTextColor(Map<String, dynamic>? dayStatus, int dayIndex) {
    int globalDayIndex = currentWeek * widget.daysCount + dayIndex;

    // Если это текущий выбранный день - белый текст
    if (globalDayIndex == currentDayIndex) {
      return Colors.white;
    }

    // Если это активная программа, используем цвета в зависимости от статуса
    if (widget.isActiveProgram && dayStatus != null) {
      String status = dayStatus['status']?.toString().toLowerCase() ?? 'null';

      switch (status) {
        case 'passed':
          return Colors.green[800]!; // Темно-зеленый текст для завершенных
        case 'active':
          return Colors.blue[800]!; // Темно-синий текст для активных
        case 'skipped':
          return Colors.red[800]!; // Темно-красный текст для пропущенных
        case 'blocked_yet':
          return Colors.grey[500]!; // Серый текст для заблокированных
        default:
          return Colors.grey[400]!;
      }
    }

    // По умолчанию серый текст
    return Colors.grey[400]!;
  }

  FontWeight _calculateTextWeight(int dayIndex) {
    int globalDayIndex = currentWeek * widget.daysCount + dayIndex;
    if (globalDayIndex == currentDayIndex) {
      return FontWeight.w700;
    }
    return FontWeight.w500;
  }

  double _calculateBorderWidth(Map<String, dynamic>? dayStatus, int dayIndex) {
    if (!widget.isActiveProgram) {
      return currentDay == dayIndex ? 3.0 : 1.0;
    }

    if (dayStatus == null) return currentDay == dayIndex ? 3.0 : 1.0;

    final status = dayStatus['status'];
    if (status == 'blocked_yet') return 1.0;
    if (status == 'passed') return 1.0;
    if (status == 'skipped') return 1.0;

    return currentDay == dayIndex ? 3.0 : 1.0;
  }

  Future<void> _loadTrainings() async {
    if (widget.userProgramUuid == null) return;

    // Предотвращаем зацикливание - загружаем только если изменился userProgramUuid
    if (_lastLoadedUserProgramUuid == widget.userProgramUuid &&
        trainings.isNotEmpty) {
      return;
    }

    // Дополнительная защита от зацикливания - не загружаем если уже загружаем
    if (_isLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final trainings = await TrainingService.getUserTrainings(
        widget.userProgramUuid!,
      );

      // Оптимизация: строим индекс и карту статусов сразу после получения данных
      this.trainings = trainings;
      _buildTrainingsIndex();
      _buildAllDaysStatusCache();
      _updateAllDaysStylesCache();

      final activeTraining = TrainingService.getActiveTraining(trainings);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastLoadedUserProgramUuid = widget.userProgramUuid;
        });
      }

      if (activeTraining != null && mounted) {
        final week = activeTraining['week'] - 1;
        final weekday = activeTraining['weekday'] - 1;
        setState(() {
          currentDayIndex = week * 7 + weekday;
          currentWeek = week;
          currentDay = weekday;
        });
        widget.onTrainingSelected?.call(activeTraining);
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToActiveDay();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastLoadedUserProgramUuid = widget.userProgramUuid;
        });
      }
      print('Error loading trainings: $e');
    }
  }

  Future<void> refreshTrainings() async {
    if (widget.userProgramUuid == null) return;

    // Очищаем кэш для принудительной перезагрузки
    _lastLoadedUserProgramUuid = null;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      TrainingService.clearTrainingsCache(widget.userProgramUuid!);

      final trainings = await TrainingService.getUserTrainings(
        widget.userProgramUuid!,
      );

      print('[refreshTrainings] loaded trainings: ' + trainings.toString());

      // Оптимизация: строим индекс и карту статусов сразу после получения данных
      this.trainings = trainings;
      _buildTrainingsIndex();
      _buildAllDaysStatusCache();
      _updateAllDaysStylesCache();

      final activeTraining = TrainingService.getActiveTraining(trainings);
      print('[refreshTrainings] activeTraining: ' + activeTraining.toString());

      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastLoadedUserProgramUuid = widget.userProgramUuid;
        });
      }

      if (activeTraining != null && mounted) {
        final week = activeTraining['week'] - 1;
        final weekday = activeTraining['weekday'] - 1;
        setState(() {
          currentDayIndex = week * 7 + weekday;
          currentWeek = week;
          currentDay = weekday;
        });
        print(
          '[refreshTrainings] setState: currentDayIndex=$currentDayIndex, currentWeek=$currentWeek, currentDay=$currentDay',
        );
        widget.onTrainingSelected?.call(activeTraining);
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToActiveDay();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastLoadedUserProgramUuid = widget.userProgramUuid;
        });
      }
      print('Error refreshing trainings: $e');
    }
  }

  void updateTrainingStatus(String trainingUuid, String newStatus) {
    if (!mounted) return;

    setState(() {
      for (int i = 0; i < trainings.length; i++) {
        if (trainings[i]['uuid'] == trainingUuid) {
          trainings[i]['status'] = newStatus;
          break;
        }
      }
      // Оптимизация: перестраиваем индекс и кэши после изменения
      _buildTrainingsIndex();
      _buildAllDaysStatusCache();
      _updateAllDaysStylesCache();
    });
  }

  void goToNextActiveTraining() {
    if (!mounted) return;

    final totalDays = widget.weeksCount * widget.daysCount;

    // Ищем следующую доступную тренировку
    for (int dayIndex = currentDayIndex + 1; dayIndex < totalDays; dayIndex++) {
      final training = _getTrainingByDayIndex(dayIndex);
      if (training != null && training['status'] != 'blocked_yet') {
        final week = dayIndex ~/ 7;
        final weekday = dayIndex % 7;

        setState(() {
          currentDayIndex = dayIndex;
          currentWeek = week;
          currentDay = weekday;
        });

        // Оптимизация: обновляем кэш стилей
        _updateAllDaysStylesCache();

        widget.onTrainingSelected?.call(training);

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToActiveDay();
            }
          });
        }
        return;
      }
    }
  }

  void goToActiveTraining() {
    final activeTraining = TrainingService.getActiveTraining(trainings);
    print('[goToActiveTraining] trainings: ' + trainings.toString());
    print('[goToActiveTraining] activeTraining: ' + activeTraining.toString());
    if (activeTraining != null && mounted) {
      final week = activeTraining['week'] - 1;
      final weekday = activeTraining['weekday'] - 1;
      setState(() {
        currentDayIndex = week * 7 + weekday;
        currentWeek = week;
        currentDay = weekday;
      });
      print(
        '[goToActiveTraining] setState: currentDayIndex=$currentDayIndex, currentWeek=$currentWeek, currentDay=$currentDay',
      );
      widget.onTrainingSelected?.call(activeTraining);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToActiveDay();
          }
        });
      }
    }
  }

  void _onWeekTap(int week) {
    if (!widget.isActiveProgram || !mounted) return;

    setState(() {
      currentWeek = week;
      // Устанавливаем день на первый день недели
      currentDay = 0;
      currentDayIndex = week * 7;
    });

    // Оптимизация: обновляем кэш стилей
    _updateAllDaysStylesCache();

    // Найти тренировку для выбранной недели и первого дня
    final training = _getTrainingByDayIndex(currentDayIndex);
    widget.onTrainingSelected?.call(training);
    widget.onWeekTap?.call(week);
  }

  void _scrollToActiveDay() {
    // Скроллим к активной неделе
    if (_weekScrollController.hasClients) {
      final weekItemWidth = widget.weekTabWidth ?? 80.0;
      final weekOffset = currentWeek * weekItemWidth;
      _weekScrollController.animateTo(
        weekOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Скроллим к активному дню
    if (_dayScrollController.hasClients) {
      final dayItemWidth = 108.0; // 96 + 12 (margin)
      final dayOffset = currentDay * dayItemWidth;
      _dayScrollController.animateTo(
        dayOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeks = List.generate(widget.weeksCount, (i) => '${i + 1} неделя');
    final days = List.generate(widget.daysCount, (i) => 'День ${i + 1}');
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Вкладки недель с горизонтальным скроллом
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _weekScrollController,
          child: Row(
            children: List.generate(
              widget.weeksCount,
              (i) => Container(
                width: widget.weekTabWidth ?? screenWidth / widget.weeksCount,
                child: GestureDetector(
                  onTap: widget.isActiveProgram ? () => _onWeekTap(i) : null,
                  child: Container(
                    alignment: Alignment.center,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius:
                          (widget.isActiveProgram
                                  ? currentWeek
                                  : widget.selectedWeek) ==
                              i
                          ? null
                          : BorderRadius.circular(8),
                      border:
                          (widget.isActiveProgram
                                  ? currentWeek
                                  : widget.selectedWeek) ==
                              i
                          ? Border(
                              bottom: BorderSide(
                                color: AppColors.buttonPrimary,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      weeks[i],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Квадратики дней с горизонтальным скроллом
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _dayScrollController,
          child: Row(
            children: List.generate(widget.daysCount, (i) {
              final globalDayIndex = currentWeek * widget.daysCount + i;
              final style = _allDaysStylesCache[globalDayIndex] ?? {};
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: widget.isActiveProgram ? () => _onDayTap(i) : null,
                  child: MouseRegion(
                    cursor: widget.isActiveProgram && _isDayClickable(i)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Container(
                      width: 96,
                      height: 56,
                      decoration: BoxDecoration(
                        color: style['background'] ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: style['border'] ?? Colors.grey[700]!,
                          width: style['borderWidth'] ?? 1.0,
                        ),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[i],
                                    style: TextStyle(
                                      color: style['text'] ?? Colors.grey[400]!,
                                      fontWeight: _calculateTextWeight(i),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (widget.isActiveProgram) ...[
                                    const SizedBox(height: 2),
                                    _buildDayStatusIcon(i),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayStatusIcon(int dayIndex) {
    // Не показываем иконки статуса
    return const SizedBox.shrink();
  }

  void _onDayTap(int day) {
    if (!widget.isActiveProgram || !mounted) return;

    final globalDayIndex = currentWeek * 7 + day;
    final trainingDay = _getTrainingByDayIndex(globalDayIndex);

    // Разрешаем переход только если тренировка не заблокирована
    if (trainingDay != null && trainingDay['status'] == 'blocked_yet') {
      return; // Не переходим к заблокированным тренировкам
    }

    setState(() {
      currentDay = day;
      currentDayIndex = globalDayIndex;
    });

    // Оптимизация: обновляем кэш стилей
    _updateAllDaysStylesCache();

    final selectedDay = _getTrainingByDayIndex(globalDayIndex);
    widget.onTrainingSelected?.call(selectedDay);
    widget.onDayTap?.call(day);
  }

  void updateCurrentWeekStylesCache() => _updateAllDaysStylesCache();

  bool _isDayClickable(int dayIndex) {
    if (!widget.isActiveProgram) return false;

    final globalDayIndex = currentWeek * 7 + dayIndex;
    final training = _getTrainingByDayIndex(globalDayIndex);

    // День кликабелен, если тренировка не заблокирована
    return training == null || training['status'] != 'blocked_yet';
  }

  Map<String, dynamic>? getCurrentActiveTraining() {
    return TrainingService.getActiveTraining(trainings);
  }
}
