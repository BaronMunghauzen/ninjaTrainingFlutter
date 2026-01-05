class FoodRecognition {
  final String uuid;
  final String createdAt;
  final String updatedAt;
  final bool actual;
  final String imageUuid;
  final String userUuid;
  final String? comment;
  final Map<String, dynamic>? jsonResponse;
  final String name;
  final double confidence;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final double weightG;
  final double volumeMl;
  final String estimatedPortionSize;
  final double caloriesTotal;
  final double proteinsTotal;
  final double fatsTotal;
  final double carbsTotal;
  final List<Ingredient> ingredients;
  final List<Recommendation>? recommendationsTip;
  final List<Recommendation>? recommendationsAlternative;
  final List<Micronutrient> micronutrients;
  final String message;
  final double processingTimeSeconds;

  FoodRecognition({
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.actual,
    required this.imageUuid,
    required this.userUuid,
    this.comment,
    this.jsonResponse,
    required this.name,
    required this.confidence,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
    required this.carbsPer100g,
    required this.weightG,
    required this.volumeMl,
    required this.estimatedPortionSize,
    required this.caloriesTotal,
    required this.proteinsTotal,
    required this.fatsTotal,
    required this.carbsTotal,
    required this.ingredients,
    this.recommendationsTip,
    this.recommendationsAlternative,
    required this.micronutrients,
    required this.message,
    required this.processingTimeSeconds,
  });

  factory FoodRecognition.fromJson(Map<String, dynamic> json) {
    return FoodRecognition(
      uuid: json['uuid'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      actual: json['actual'] as bool,
      imageUuid: json['image_uuid'] as String,
      userUuid: json['user_uuid'] as String,
      comment: json['comment'] as String?,
      jsonResponse: json['json_response'] as Map<String, dynamic>?,
      name: json['name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
      proteinsPer100g: (json['proteins_per_100g'] as num).toDouble(),
      fatsPer100g: (json['fats_per_100g'] as num).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num).toDouble(),
      weightG: (json['weight_g'] as num).toDouble(),
      volumeMl: (json['volume_ml'] as num).toDouble(),
      estimatedPortionSize: json['estimated_portion_size'] as String,
      caloriesTotal: (json['calories_total'] as num).toDouble(),
      proteinsTotal: (json['proteins_total'] as num).toDouble(),
      fatsTotal: (json['fats_total'] as num).toDouble(),
      carbsTotal: (json['carbs_total'] as num).toDouble(),
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendationsTip: (json['recommendations_tip'] as List<dynamic>?)
          ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendationsAlternative:
          (json['recommendations_alternative'] as List<dynamic>?)
              ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
              .toList(),
      micronutrients: (json['micronutrients'] as List<dynamic>?)
              ?.map((e) => Micronutrient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'] as String,
      processingTimeSeconds: (json['processing_time_seconds'] as num).toDouble(),
    );
  }
}

class Ingredient {
  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final String? description;
  final double weightInPortionG;
  final double caloriesInPortion;
  final double proteinsInPortion;
  final double fatsInPortion;
  final double carbsInPortion;

  Ingredient({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
    required this.carbsPer100g,
    this.description,
    required this.weightInPortionG,
    required this.caloriesInPortion,
    required this.proteinsInPortion,
    required this.fatsInPortion,
    required this.carbsInPortion,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
      proteinsPer100g: (json['proteins_per_100g'] as num).toDouble(),
      fatsPer100g: (json['fats_per_100g'] as num).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num).toDouble(),
      description: json['description'] as String?,
      weightInPortionG: (json['weight_in_portion_g'] as num).toDouble(),
      caloriesInPortion: (json['calories_in_portion'] as num).toDouble(),
      proteinsInPortion: (json['proteins_in_portion'] as num).toDouble(),
      fatsInPortion: (json['fats_in_portion'] as num).toDouble(),
      carbsInPortion: (json['carbs_in_portion'] as num).toDouble(),
    );
  }
}

class Recommendation {
  final String type;
  final String title;
  final String description;
  final double? caloriesSaved;

  Recommendation({
    required this.type,
    required this.title,
    required this.description,
    this.caloriesSaved,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      caloriesSaved: json['calories_saved'] != null
          ? (json['calories_saved'] as num).toDouble()
          : null,
    );
  }
}

class Micronutrient {
  final String name;
  final double amount;
  final String unit;
  final double dailyValue;
  final double percentOfDailyValue;

  Micronutrient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.dailyValue,
    required this.percentOfDailyValue,
  });

  factory Micronutrient.fromJson(Map<String, dynamic> json) {
    return Micronutrient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      dailyValue: (json['daily_value'] as num).toDouble(),
      percentOfDailyValue: (json['percent_of_daily_value'] as num).toDouble(),
    );
  }
}

class FoodRecognitionListResponse {
  final List<FoodRecognition> items;
  final Pagination pagination;

  FoodRecognitionListResponse({
    required this.items,
    required this.pagination,
  });

  factory FoodRecognitionListResponse.fromJson(Map<String, dynamic> json) {
    return FoodRecognitionListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => FoodRecognition.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
          json['pagination'] as Map<String, dynamic>),
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

