class FoodProgressTarget {
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double targetCalories;
  final double targetProteins;
  final double targetFats;
  final double targetCarbs;

  FoodProgressTarget({
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.targetCalories,
    required this.targetProteins,
    required this.targetFats,
    required this.targetCarbs,
  });

  factory FoodProgressTarget.fromJson(Map<String, dynamic> json) {
    return FoodProgressTarget(
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      targetCalories: (json['target_calories'] as num).toDouble(),
      targetProteins: (json['target_proteins'] as num).toDouble(),
      targetFats: (json['target_fats'] as num).toDouble(),
      targetCarbs: (json['target_carbs'] as num).toDouble(),
    );
  }
}

class FoodProgressMeal {
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime mealDatetime;
  final String name;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  FoodProgressMeal({
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.mealDatetime,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  factory FoodProgressMeal.fromJson(Map<String, dynamic> json) {
    return FoodProgressMeal(
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      mealDatetime: DateTime.parse(json['meal_datetime'] as String),
      name: json['name'] as String? ?? '',
      calories: (json['calories'] as num).toDouble(),
      proteins: (json['proteins'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }
}

class FoodProgressSummary {
  final String date;
  final double eatenCalories;
  final double eatenProteins;
  final double eatenFats;
  final double eatenCarbs;
  final double targetCalories;
  final double targetProteins;
  final double targetFats;
  final double targetCarbs;
  final double remainingCalories;
  final double remainingProteins;
  final double remainingFats;
  final double remainingCarbs;

  FoodProgressSummary({
    required this.date,
    required this.eatenCalories,
    required this.eatenProteins,
    required this.eatenFats,
    required this.eatenCarbs,
    required this.targetCalories,
    required this.targetProteins,
    required this.targetFats,
    required this.targetCarbs,
    required this.remainingCalories,
    required this.remainingProteins,
    required this.remainingFats,
    required this.remainingCarbs,
  });

  factory FoodProgressSummary.fromJson(Map<String, dynamic> json) {
    return FoodProgressSummary(
      date: json['date'] as String? ?? '',
      eatenCalories: (json['eaten_calories'] as num?)?.toDouble() ?? 0.0,
      eatenProteins: (json['eaten_proteins'] as num?)?.toDouble() ?? 0.0,
      eatenFats: (json['eaten_fats'] as num?)?.toDouble() ?? 0.0,
      eatenCarbs: (json['eaten_carbs'] as num?)?.toDouble() ?? 0.0,
      targetCalories: (json['target_calories'] as num?)?.toDouble() ?? 0.0,
      targetProteins: (json['target_proteins'] as num?)?.toDouble() ?? 0.0,
      targetFats: (json['target_fats'] as num?)?.toDouble() ?? 0.0,
      targetCarbs: (json['target_carbs'] as num?)?.toDouble() ?? 0.0,
      remainingCalories:
          (json['remaining_calories'] as num?)?.toDouble() ?? 0.0,
      remainingProteins:
          (json['remaining_proteins'] as num?)?.toDouble() ?? 0.0,
      remainingFats: (json['remaining_fats'] as num?)?.toDouble() ?? 0.0,
      remainingCarbs: (json['remaining_carbs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Геттеры для обратной совместимости
  double get totalCalories => eatenCalories;
  double get totalProteins => eatenProteins;
  double get totalFats => eatenFats;
  double get totalCarbs => eatenCarbs;

  // Расчет прогресса: eaten / target
  double get caloriesProgress => targetCalories > 0
      ? (eatenCalories / targetCalories).clamp(0.0, 1.0)
      : 0.0;

  double get proteinsProgress => targetProteins > 0
      ? (eatenProteins / targetProteins).clamp(0.0, 1.0)
      : 0.0;

  double get fatsProgress =>
      targetFats > 0 ? (eatenFats / targetFats).clamp(0.0, 1.0) : 0.0;

  double get carbsProgress =>
      targetCarbs > 0 ? (eatenCarbs / targetCarbs).clamp(0.0, 1.0) : 0.0;
}

class FoodProgressMealsListResponse {
  final List<FoodProgressMeal> items;
  final Pagination pagination;

  FoodProgressMealsListResponse({
    required this.items,
    required this.pagination,
  });

  factory FoodProgressMealsListResponse.fromJson(Map<String, dynamic> json) {
    return FoodProgressMealsListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => FoodProgressMeal.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

class Pagination {
  final int page;
  final int size;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.page,
    required this.size,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      size: json['size'] as int,
      totalCount: json['total_count'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrev: json['has_prev'] as bool,
    );
  }
}

/// Формула расчета калорий: калории = белки * 4 + жиры * 9 + углеводы * 4
double calculateCaloriesFromMacros({
  required double proteins,
  required double fats,
  required double carbs,
}) {
  return (proteins * 4) + (fats * 9) + (carbs * 4);
}
