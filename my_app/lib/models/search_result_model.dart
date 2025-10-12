import 'program_model.dart';

export 'exercise_model.dart';

class SearchResult {
  final List<dynamic> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  SearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  // Геттер для упражнений
  List<ExerciseReference> get exerciseReferences {
    return items.whereType<ExerciseReference>().toList();
  }

  // Геттер для программ
  List<Program> get programs {
    return items.whereType<Program>().toList();
  }

  // Геттер для тренировок
  List<Training> get trainings {
    return items.whereType<Training>().toList();
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    List<dynamic> parsedItems = [];

    // Вариант 1: универсальный массив items
    if (json['items'] is List) {
      for (final item in (json['items'] as List)) {
        if (item is Map<String, dynamic>) {
          if (item.containsKey('exercise_type')) {
            parsedItems.add(ExerciseReference.fromJson(item));
          } else if (item.containsKey('program_type')) {
            parsedItems.add(Program.fromJson(item));
          } else if (item.containsKey('training_type')) {
            parsedItems.add(Training.fromJson(item));
          } else {
            parsedItems.add(item);
          }
        } else {
          parsedItems.add(item);
        }
      }
    }

    // Вариант 2: раздельные коллекции по типам
    if (json['exercise_references'] is List) {
      for (final item in (json['exercise_references'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(ExerciseReference.fromJson(item));
        }
      }
    }

    if (json['programs'] is List) {
      for (final item in (json['programs'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(Program.fromJson(item));
        }
      }
    }

    if (json['trainings'] is List) {
      for (final item in (json['trainings'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(Training.fromJson(item));
        }
      }
    }

    final int computedTotal = parsedItems.length;
    final int total = (json['total'] is int)
        ? json['total'] as int
        : computedTotal;
    final int size = (json['size'] is int)
        ? json['size'] as int
        : computedTotal;
    final int page = (json['page'] is int) ? json['page'] as int : 1;
    final int pages = (json['pages'] is int)
        ? json['pages'] as int
        : (size == 0 ? 0 : 1);

    return SearchResult(
      items: parsedItems,
      total: total,
      page: page,
      size: size,
      pages: pages,
    );
  }
}

class ExerciseReferenceSearchResult {
  final List<ExerciseReference> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  ExerciseReferenceSearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory ExerciseReferenceSearchResult.fromJson(Map<String, dynamic> json) {
    return ExerciseReferenceSearchResult(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ExerciseReference.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
      pages: json['pages'] ?? 0,
    );
  }
}

class ExerciseReference {
  final String exerciseType;
  final int? id; // Делаем id опциональным, так как API не возвращает это поле
  final String caption;
  final int? imageId;
  final String uuid;
  final dynamic userId;
  final String description;
  final String muscleGroup;
  final String? techniqueDescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic user;
  final dynamic image; // Может быть строкой, Map или null
  final dynamic video; // Может быть строкой, Map или null
  final dynamic gif; // Может быть строкой, Map или null

  ExerciseReference({
    required this.exerciseType,
    this.id, // Теперь id опциональный
    required this.caption,
    this.imageId,
    required this.uuid,
    this.userId,
    required this.description,
    required this.muscleGroup,
    this.techniqueDescription,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.image,
    this.video,
    this.gif,
  });

  static int? _parseImageId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  factory ExerciseReference.fromJson(Map<String, dynamic> json) {
    return ExerciseReference(
      exerciseType: json['exercise_type'] ?? '',
      id: json['id'], // Теперь id может быть null
      caption: json['caption'] ?? '',
      imageId: _parseImageId(json['image_id']),
      uuid: json['uuid'] ?? '',
      userId: json['user_id'],
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      techniqueDescription: json['technique_description']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'],
      image: json['image_uuid'] ?? json['image'],
      video: json['video_uuid'] ?? json['video'],
      gif: json['gif_uuid'],
    );
  }
}

class Training {
  final String trainingType;
  final int?
  id; // Делаем id опциональным, так как API может не возвращать это поле
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
    this.id, // Теперь id опциональный
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
    return null;
  }

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      trainingType: json['training_type'] ?? '',
      id: json['id'], // Теперь id может быть null
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
