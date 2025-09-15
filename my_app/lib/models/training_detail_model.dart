class TrainingDetailModel {
  final String trainingDate;
  final String trainingCaption;
  final int trainingDuration;
  final String trainingMuscleGroup;
  final String? programCaption;
  final List<UserExerciseModel> exercises;

  TrainingDetailModel({
    required this.trainingDate,
    required this.trainingCaption,
    required this.trainingDuration,
    required this.trainingMuscleGroup,
    this.programCaption,
    required this.exercises,
  });

  factory TrainingDetailModel.fromJson(Map<String, dynamic> json) {
    return TrainingDetailModel(
      trainingDate: json['training_date'] ?? '',
      trainingCaption: json['training_caption'] ?? '',
      trainingDuration: json['training_duration'] ?? 0,
      trainingMuscleGroup: json['training_muscle_group'] ?? '',
      programCaption: json['program_caption'],
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((item) => UserExerciseModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class UserExerciseModel {
  final String uuid;
  final String exerciseReferenceUuid;
  final String userUuid;
  final String trainingUuid;
  final String trainingDate;
  final int setNumber;
  final int reps;
  final double weight;
  final bool actual;
  final String createdAt;
  final String updatedAt;

  UserExerciseModel({
    required this.uuid,
    required this.exerciseReferenceUuid,
    required this.userUuid,
    required this.trainingUuid,
    required this.trainingDate,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.actual,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserExerciseModel.fromJson(Map<String, dynamic> json) {
    return UserExerciseModel(
      uuid: json['uuid'] ?? '',
      exerciseReferenceUuid: json['exercise_reference_uuid'] ?? '',
      userUuid: json['user_uuid'] ?? '',
      trainingUuid: json['training_uuid'] ?? '',
      trainingDate: json['training_date'] ?? '',
      setNumber: json['set_number'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: (json['weight'] ?? 0).toDouble(),
      actual: json['actual'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
