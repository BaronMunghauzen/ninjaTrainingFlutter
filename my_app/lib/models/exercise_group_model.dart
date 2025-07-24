import 'user_training_model.dart';

class ExerciseGroupModel {
  final String uuid;
  final String caption;
  final String description;
  final List<String> exercises;
  final int difficultyLevel;
  final int order;
  final String muscleGroup;
  final int stage;
  final TrainingInfo training;

  ExerciseGroupModel({
    required this.uuid,
    required this.caption,
    required this.description,
    required this.exercises,
    required this.difficultyLevel,
    required this.order,
    required this.muscleGroup,
    required this.stage,
    required this.training,
  });

  factory ExerciseGroupModel.fromJson(Map<String, dynamic> json) {
    return ExerciseGroupModel(
      uuid: json['uuid'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      difficultyLevel: json['difficulty_level'] ?? 1,
      order: json['order'] ?? 0,
      muscleGroup: json['muscle_group'] ?? '',
      stage: json['stage'] ?? 1,
      training: TrainingInfo.fromJson(json['training'] ?? {}),
    );
  }
}
