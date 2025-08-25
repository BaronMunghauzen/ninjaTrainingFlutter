class Category {
  final String uuid;
  final String caption;
  final String description;
  final int order;

  Category({
    required this.uuid,
    required this.caption,
    required this.description,
    required this.order,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

class Program {
  final String uuid;
  final bool actual;
  final String programType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final int order;
  final String? scheduleType;
  final String? trainingDays;
  final String? imageUuid;
  final Category? category;
  final dynamic user; // null в данном случае

  Program({
    required this.uuid,
    required this.actual,
    required this.programType,
    required this.caption,
    required this.description,
    required this.difficultyLevel,
    required this.order,
    this.scheduleType,
    this.trainingDays,
    this.imageUuid,
    this.category,
    this.user,
  });

  static String? _parseImageUuid(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    if (value is int) return value.toString();
    return null;
  }

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      uuid: json['uuid'] ?? '',
      actual: json['actual'] ?? false,
      programType: json['program_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 0,
      order: json['order'] ?? 0,
      scheduleType: json['schedule_type'],
      trainingDays: json['training_days'],
      imageUuid: _parseImageUuid(json['image_uuid']),
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'actual': actual,
      'program_type': programType,
      'caption': caption,
      'description': description,
      'difficulty_level': difficultyLevel,
      'order': order,
      'schedule_type': scheduleType,
      'training_days': trainingDays,
      'image_uuid': imageUuid,
      'category': category != null
          ? {
              'uuid': category!.uuid,
              'caption': category!.caption,
              'description': category!.description,
              'order': category!.order,
            }
          : null,
      'user': user,
    };
  }
}
