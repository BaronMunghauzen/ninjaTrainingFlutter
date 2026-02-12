class AchievementType {
  final String name;
  final String description;
  final String category;
  final String? subcategory;
  final String requirements;
  final String? icon;
  final int points;
  final bool isActive;
  final String? imageUuid;
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;

  AchievementType({
    required this.name,
    required this.description,
    required this.category,
    this.subcategory,
    required this.requirements,
    this.icon,
    required this.points,
    required this.isActive,
    this.imageUuid,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AchievementType.fromJson(Map<String, dynamic> json) {
    return AchievementType(
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      requirements: json['requirements'] as String,
      icon: json['icon'] as String?,
      points: json['points'] as int,
      isActive: json['is_active'] as bool,
      imageUuid: json['image_uuid'] as String?,
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
