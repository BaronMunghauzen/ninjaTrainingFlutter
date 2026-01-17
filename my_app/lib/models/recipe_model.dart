class Recipe {
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool actual;
  final String? userUuid;
  final String
  category; // breakfast, lunch, dinner, salad, snack, dessert, other
  final String? type;
  final String name;
  final Map<String, String> ingredients; // {"Яйцо": "1 шт"}
  final String recipe;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final double caloriesPerPortion;
  final double proteinsPerPortion;
  final double fatsPerPortion;
  final double carbsPerPortion;
  final int portionsCount;
  final String? imageUuid;
  final int cookingTime; // в минутах
  final bool isFavorite; // в избранном

  Recipe({
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.actual,
    this.userUuid,
    required this.category,
    this.type,
    required this.name,
    required this.ingredients,
    required this.recipe,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
    required this.carbsPer100g,
    required this.caloriesPerPortion,
    required this.proteinsPerPortion,
    required this.fatsPerPortion,
    required this.carbsPerPortion,
    required this.portionsCount,
    this.imageUuid,
    required this.cookingTime,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      actual: json['actual'] as bool,
      userUuid: json['user_uuid'] as String?,
      category: json['category'] as String,
      type: json['type'] as String?,
      name: json['name'] as String,
      ingredients: Map<String, String>.from(
        json['ingredients'] as Map<dynamic, dynamic>,
      ),
      recipe: json['recipe'] as String,
      caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
      proteinsPer100g: (json['proteins_per_100g'] as num).toDouble(),
      fatsPer100g: (json['fats_per_100g'] as num).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num).toDouble(),
      caloriesPerPortion: (json['calories_per_portion'] as num).toDouble(),
      proteinsPerPortion: (json['proteins_per_portion'] as num).toDouble(),
      fatsPerPortion: (json['fats_per_portion'] as num).toDouble(),
      carbsPerPortion: (json['carbs_per_portion'] as num).toDouble(),
      portionsCount: json['portions_count'] as int,
      imageUuid: json['image_uuid'] as String?,
      cookingTime: json['cooking_time'] as int,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'actual': actual,
      'user_uuid': userUuid,
      'category': category,
      'type': type,
      'name': name,
      'ingredients': ingredients,
      'recipe': recipe,
      'calories_per_100g': caloriesPer100g,
      'proteins_per_100g': proteinsPer100g,
      'fats_per_100g': fatsPer100g,
      'carbs_per_100g': carbsPer100g,
      'calories_per_portion': caloriesPerPortion,
      'proteins_per_portion': proteinsPerPortion,
      'fats_per_portion': fatsPerPortion,
      'carbs_per_portion': carbsPerPortion,
      'portions_count': portionsCount,
      'image_uuid': imageUuid,
      'cooking_time': cookingTime,
      'is_favorite': isFavorite,
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case 'breakfast':
        return 'Завтрак';
      case 'lunch':
        return 'Обед';
      case 'dinner':
        return 'Ужин';
      case 'salad':
        return 'Салаты';
      case 'snack':
        return 'Перекус';
      case 'dessert':
        return 'Десерты';
      case 'other':
        return 'Другое';
      default:
        return category;
    }
  }
}

class RecipesGroupedByCategoryResponse {
  final List<Recipe> breakfast;
  final List<Recipe> lunch;
  final List<Recipe> dinner;
  final List<Recipe> salad;
  final List<Recipe> snack;
  final List<Recipe> dessert;
  final List<Recipe> other;

  RecipesGroupedByCategoryResponse({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.salad,
    required this.snack,
    required this.dessert,
    required this.other,
  });

  factory RecipesGroupedByCategoryResponse.fromJson(Map<String, dynamic> json) {
    return RecipesGroupedByCategoryResponse(
      breakfast:
          (json['breakfast'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lunch:
          (json['lunch'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dinner:
          (json['dinner'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      salad:
          (json['salad'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      snack:
          (json['snack'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dessert:
          (json['dessert'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      other:
          (json['other'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  List<Recipe> getCategoryRecipes(String category) {
    switch (category) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'salad':
        return salad;
      case 'snack':
        return snack;
      case 'dessert':
        return dessert;
      case 'other':
        return other;
      default:
        return [];
    }
  }
}

class RecipesListResponse {
  final List<Recipe> items;
  final int total;
  final int page;
  final int size;
  final int totalPages;

  RecipesListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.totalPages,
  });

  factory RecipesListResponse.fromJson(Map<String, dynamic> json) {
    return RecipesListResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      size: json['size'] as int? ?? 10,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}
