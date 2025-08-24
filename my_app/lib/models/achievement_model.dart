import 'dart:convert';

enum AchievementType {
  general,
  training,
  exercise,
  streak,
  time,
  social,
  weight,
  distance,
  calories,
}

class AchievementModel {
  final String uuid;
  final String title;
  final String description;
  final AchievementType type;
  final String category;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;
  final String? rewardDescription;
  final DateTime? createdAt;
  final DateTime? unlockedAt;
  final String icon;

  AchievementModel({
    required this.uuid,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.isUnlocked,
    this.rewardDescription,
    this.createdAt,
    this.unlockedAt,
    required this.icon,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      uuid: json['uuid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: AchievementType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AchievementType.general,
      ),
      category: json['category'] ?? 'Общие',
      targetValue: json['target_value'] ?? 0,
      currentValue: json['current_value'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      rewardDescription: json['reward_description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'])
          : null,
      icon: json['icon'] ?? '⭐',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_unlocked': isUnlocked,
      'reward_description': rewardDescription,
      'created_at': createdAt?.toIso8601String(),
      'unlocked_at': unlockedAt?.toIso8601String(),
      'icon': icon,
    };
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  bool get isNearCompletion {
    return progressPercentage >= 0.8 && !isUnlocked;
  }

  AchievementModel copyWith({
    String? uuid,
    String? title,
    String? description,
    AchievementType? type,
    String? category,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    String? rewardDescription,
    DateTime? createdAt,
    DateTime? unlockedAt,
    String? icon,
  }) {
    return AchievementModel(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      createdAt: createdAt ?? this.createdAt,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      icon: icon ?? this.icon,
    );
  }

  @override
  String toString() {
    return 'AchievementModel(uuid: $uuid, title: $title, type: $type, isUnlocked: $isUnlocked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AchievementModel && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

