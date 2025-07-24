import 'program_model.dart';

class Training {
  final String uuid;
  final String trainingType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final int duration;
  final int order;
  final String muscleGroup;
  final int stage;
  final Program program;
  final dynamic user;

  Training({
    required this.uuid,
    required this.trainingType,
    required this.caption,
    required this.description,
    required this.difficultyLevel,
    required this.duration,
    required this.order,
    required this.muscleGroup,
    required this.stage,
    required this.program,
    this.user,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      uuid: json['uuid'] ?? '',
      trainingType: json['training_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 0,
      duration: json['duration'] ?? 0,
      order: json['order'] ?? 0,
      muscleGroup: json['muscle_group'] ?? '',
      stage: json['stage'] ?? 0,
      program: Program.fromJson(json['program'] ?? {}),
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'training_type': trainingType,
      'caption': caption,
      'description': description,
      'difficulty_level': difficultyLevel,
      'duration': duration,
      'order': order,
      'muscle_group': muscleGroup,
      'stage': stage,
      'program': program.toJson(),
      'user': user,
    };
  }
}
