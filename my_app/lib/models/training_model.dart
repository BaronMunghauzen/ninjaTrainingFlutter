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
  final String? imageUuid;

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
    this.imageUuid,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      uuid: json['uuid'] ?? '',
      trainingType: json['training_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficulty_level'] is int
          ? json['difficulty_level']
          : int.tryParse(json['difficulty_level']?.toString() ?? '0') ?? 0,
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      muscleGroup: json['muscle_group'] ?? '',
      stage: json['stage'] is int
          ? json['stage']
          : int.tryParse(json['stage']?.toString() ?? '0') ?? 0,
      program: json['program'] != null
          ? Program.fromJson(json['program'])
          : Program(
              uuid: '',
              actual: false,
              programType: '',
              caption: '',
              description: '',
              difficultyLevel: 0,
              order: 0,
            ),
      user: json['user'],
      imageUuid: json['image_uuid'],
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
      'image_uuid': imageUuid,
    };
  }
}
