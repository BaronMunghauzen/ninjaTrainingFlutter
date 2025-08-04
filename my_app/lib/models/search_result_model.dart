import 'program_model.dart';

class SearchResult {
  final List<ExerciseReference> exerciseReferences;
  final List<Program> programs;
  final List<Training> trainings;
  final int totalResults;

  SearchResult({
    required this.exerciseReferences,
    required this.programs,
    required this.trainings,
    required this.totalResults,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      exerciseReferences:
          (json['exercise_references'] as List?)
              ?.map((e) => ExerciseReference.fromJson(e))
              .toList() ??
          [],
      programs:
          (json['programs'] as List?)
              ?.map((e) => Program.fromJson(e))
              .toList() ??
          [],
      trainings:
          (json['trainings'] as List?)
              ?.map((e) => Training.fromJson(e))
              .toList() ??
          [],
      totalResults: json['total_results'] ?? 0,
    );
  }
}

class ExerciseReference {
  final String exerciseType;
  final int id;
  final String caption;
  final int? imageId;
  final String uuid;
  final dynamic userId;
  final String description;
  final String muscleGroup;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic user;
  final dynamic
  image; // Changed from String? to dynamic to handle both String and Map

  ExerciseReference({
    required this.exerciseType,
    required this.id,
    required this.caption,
    this.imageId,
    required this.uuid,
    this.userId,
    required this.description,
    required this.muscleGroup,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.image,
  });

  static int? _parseImageId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    print(
      'Warning: Could not parse imageId: $value (type: ${value.runtimeType})',
    );
    return null;
  }

  factory ExerciseReference.fromJson(Map<String, dynamic> json) {
    // Отладочная информация
    print(
      'ExerciseReference.fromJson - image field: ${json['image']} (type: ${json['image']?.runtimeType})',
    );

    return ExerciseReference(
      exerciseType: json['exercise_type'] ?? '',
      id: json['id'] ?? 0,
      caption: json['caption'] ?? '',
      imageId: _parseImageId(json['image_id']),
      uuid: json['uuid'] ?? '',
      userId: json['user_id'],
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'],
      image: json['image'],
    );
  }
}

class Training {
  final String trainingType;
  final int id;
  final String caption;
  final int? imageId;
  final String uuid;
  final dynamic userId;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic user;
  final dynamic
  image; // Changed from String? to dynamic to handle both String and Map

  Training({
    required this.trainingType,
    required this.id,
    required this.caption,
    this.imageId,
    required this.uuid,
    this.userId,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.image,
  });

  static int? _parseImageId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    print(
      'Warning: Could not parse imageId: $value (type: ${value.runtimeType})',
    );
    return null;
  }

  factory Training.fromJson(Map<String, dynamic> json) {
    // Отладочная информация
    print(
      'Training.fromJson - image field: ${json['image']} (type: ${json['image']?.runtimeType})',
    );

    return Training(
      trainingType: json['training_type'] ?? '',
      id: json['id'] ?? 0,
      caption: json['caption'] ?? '',
      imageId: _parseImageId(json['image_id']),
      uuid: json['uuid'] ?? '',
      userId: json['user_id'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'],
      image: json['image'],
    );
  }
}
