import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user_training_model.dart';

class TrainingCalendar extends StatefulWidget {
  final List<UserTrainingModel> trainings;
  final Function(
    DateTime selectedDate,
    List<UserTrainingModel> trainingsForDate,
  )
  onDateSelected;

  const TrainingCalendar({
    super.key,
    required this.trainings,
    required this.onDateSelected,
  });

  @override
  State<TrainingCalendar> createState() => _TrainingCalendarState();
}

class _TrainingCalendarState extends State<TrainingCalendar> {
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Устанавливаем фокус на текущий месяц
    _focusedDay = DateTime.now();
  }

  bool _hasTrainingOnDay(DateTime day) {
    final hasTraining = widget.trainings.any((training) {
      final trainingDate = DateTime.parse(training.trainingDate);
      final matches =
          trainingDate.year == day.year &&
          trainingDate.month == day.month &&
          trainingDate.day == day.day;
      return matches;
    });
    return hasTraining;
  }

  List<UserTrainingModel> _getTrainingsForDay(DateTime day) {
    return widget.trainings.where((training) {
      final trainingDate = DateTime.parse(training.trainingDate);
      return trainingDate.year == day.year &&
          trainingDate.month == day.month &&
          trainingDate.day == day.day;
    }).toList();
  }

  void _onDaySelected(DateTime day) {
    final trainingsForDay = _getTrainingsForDay(day);
    if (trainingsForDay.isNotEmpty) {
      widget.onDateSelected(day, trainingsForDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Заголовок с навигацией
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    });
                  },
                  icon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                ),
                Text(
                  _getMonthName(_focusedDay.month) + ' ${_focusedDay.year}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: _focusedDay.isBefore(DateTime.now())
                      ? () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                            );
                          });
                        }
                      : null,
                  icon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),

          // Календарная сетка
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;

    // Заголовки дней недели
    final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Container(
      child: Column(
        children: [
          // Заголовки дней недели
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
            ),
            child: Row(
              children: weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Дни месяца
          ...List.generate((lastDayOfMonth.day + firstDayOfWeek - 2) ~/ 7 + 1, (
            weekIndex,
          ) {
            return Container(
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber =
                      weekIndex * 7 + dayIndex - firstDayOfWeek + 2;

                  if (dayNumber < 1 || dayNumber > lastDayOfMonth.day) {
                    return Expanded(child: Container(height: 40));
                  }

                  final day = DateTime(
                    _focusedDay.year,
                    _focusedDay.month,
                    dayNumber,
                  );
                  final hasTraining = _hasTrainingOnDay(day);
                  final isToday =
                      DateTime.now().year == day.year &&
                      DateTime.now().month == day.month &&
                      DateTime.now().day == day.day;

                  return Expanded(
                    child: GestureDetector(
                      onTap: hasTraining ? () => _onDaySelected(day) : null,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary.withOpacity(0.3)
                              : null,
                          borderRadius: hasTraining
                              ? BorderRadius.circular(20)
                              : null,
                          border: hasTraining
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (hasTraining)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month - 1];
  }
}
