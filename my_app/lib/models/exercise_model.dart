class ExerciseModel {
  final String uuid;
  final String exerciseType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final int order;
  final String muscleGroup;
  final int setsCount;
  final int repsCount;
  final int restTime;
  final bool withWeight;

  ExerciseModel({
    required this.uuid,
    required this.exerciseType,
    required this.caption,
    required this.description,
    required this.difficultyLevel,
    required this.order,
    required this.muscleGroup,
    required this.setsCount,
    required this.repsCount,
    required this.restTime,
    required this.withWeight,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      uuid: json['uuid'] ?? '',
      exerciseType: json['exercise_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 1,
      order: json['order'] ?? 0,
      muscleGroup: json['muscle_group'] ?? '',
      setsCount: json['sets_count'] ?? 1,
      repsCount: json['reps_count'] ?? 1,
      restTime: json['rest_time'] ?? 0,
      withWeight: json['with_weight'] ?? false,
    );
  }
}
