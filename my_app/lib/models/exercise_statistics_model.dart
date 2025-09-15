class ExerciseStatisticsModel {
  final String exerciseReferenceUuid;
  final String userUuid;
  final int maxSetsPerDay;
  final int totalTrainingDays;
  final List<ExerciseHistoryEntry> history;

  ExerciseStatisticsModel({
    required this.exerciseReferenceUuid,
    required this.userUuid,
    required this.maxSetsPerDay,
    required this.totalTrainingDays,
    required this.history,
  });

  factory ExerciseStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ExerciseStatisticsModel(
      exerciseReferenceUuid: json['exercise_reference_uuid'] ?? '',
      userUuid: json['user_uuid'] ?? '',
      maxSetsPerDay: json['max_sets_per_day'] ?? 0,
      totalTrainingDays: json['total_training_days'] ?? 0,
      history:
          (json['history'] as List<dynamic>?)
              ?.map((item) => ExerciseHistoryEntry.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ExerciseHistoryEntry {
  final String trainingDate;
  final List<ExerciseSet> sets;

  ExerciseHistoryEntry({required this.trainingDate, required this.sets});

  factory ExerciseHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryEntry(
      trainingDate: json['training_date'] ?? '',
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((item) => ExerciseSet.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ExerciseSet {
  final int setNumber;
  final int reps;
  final double weight;

  ExerciseSet({
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setNumber: json['set_number'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
    );
  }

  String get displayText {
    if (weight > 0) {
      return '$reps x ${weight.toStringAsFixed(1)}';
    } else {
      return '$reps';
    }
  }
}

