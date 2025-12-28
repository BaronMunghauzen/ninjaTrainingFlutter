class UserAchievementType {
  final String uuid;
  final String name;
  final String description;
  final String category;
  final String? subcategory;
  final String requirements;
  final String? icon;
  final int points;
  final bool isActive;
  final String? imageUuid;
  final String status; // "earned" or "not_earned"
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAchievementType({
    required this.uuid,
    required this.name,
    required this.description,
    required this.category,
    this.subcategory,
    required this.requirements,
    this.icon,
    required this.points,
    required this.isActive,
    this.imageUuid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAchievementType.fromJson(Map<String, dynamic> json) {
    return UserAchievementType(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      requirements: json['requirements'] ?? '',
      icon: json['icon'],
      points: json['points'] ?? 0,
      isActive: json['is_active'] ?? true,
      imageUuid: json['image_uuid'],
      status: json['status'] ?? 'not_earned',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  bool get isEarned => status == 'earned';
}

