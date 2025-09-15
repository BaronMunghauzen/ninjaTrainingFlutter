import 'package:flutter/material.dart';
import '../models/exercise_statistics_model.dart';
import '../constants/app_colors.dart';

class ExerciseStatisticsTable extends StatelessWidget {
  final ExerciseStatisticsModel statistics;

  const ExerciseStatisticsTable({Key? key, required this.statistics})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: _buildTable(),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final maxSets = statistics.maxSetsPerDay;

    // Если нет данных, показываем сообщение
    if (statistics.history.isEmpty) {
      return Container(
        height: 100,
        child: const Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DataTable(
        columnSpacing: 8,
        horizontalMargin: 8,
        headingRowColor: MaterialStateProperty.all(
          AppColors.primary.withOpacity(0.2),
        ),
        headingTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: AppColors.textPrimary),
        dividerThickness: 1,
        border: TableBorder(
          horizontalInside: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
          verticalInside: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        columns: [
          DataColumn(
            label: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: const Text(
                'Дата\nтренировки',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          ...List.generate(
            maxSets,
            (index) => DataColumn(
              label: Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Text(
                  '${index + 1} подход',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
        rows: statistics.history.map((entry) {
          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Text(
                    _formatDate(entry.trainingDate),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              ...List.generate(maxSets, (setIndex) {
                final set = entry.sets.firstWhere(
                  (s) => s.setNumber == setIndex + 1,
                  orElse: () =>
                      ExerciseSet(setNumber: setIndex + 1, reps: 0, weight: 0),
                );

                return DataCell(
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 6,
                    ),
                    child: Text(
                      set.reps > 0 ? set.displayText : '-',
                      style: TextStyle(
                        color: set.reps > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
