import 'package:flutter/material.dart';
import '../models/exercise_statistics_model.dart';
import 'metal_table.dart';

class ExerciseStatisticsTable extends StatelessWidget {
  final ExerciseStatisticsModel statistics;

  const ExerciseStatisticsTable({Key? key, required this.statistics})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxSets = statistics.maxSetsPerDay;

    // Формируем заголовки
    final headers = <String>[
      'Дата тренировки',
      ...List.generate(
        maxSets,
        (index) => '${index + 1} подход',
      ),
    ];

    // Формируем строки данных
    final rows = statistics.history.map((entry) {
      final row = <String>[
        _formatDate(entry.trainingDate),
        ...List.generate(maxSets, (setIndex) {
          final set = entry.sets.firstWhere(
            (s) => s.setNumber == setIndex + 1,
            orElse: () =>
                ExerciseSet(setNumber: setIndex + 1, reps: 0, weight: 0),
          );
          return set.reps > 0 ? set.displayText : '-';
        }),
      ];
      return row;
    }).toList();

    return MetalTable(
      headers: headers,
      rows: rows,
      cellHeight: 50,
      fontSize: 12,
      isScrollable: true,
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
