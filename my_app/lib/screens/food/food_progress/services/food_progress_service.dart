import '../../../../services/api_service.dart';
import '../models/food_progress_model.dart';

class FoodProgressService {
  /// Получить сводку по прогрессу за день
  /// [targetDate] - дата в формате "2026-01-08" (гггг-мм-дд). Если не указана, используется текущая дата.
  static Future<FoodProgressSummary> getDailySummary({String? targetDate}) async {
    try {
      // Форматируем дату: если не указана, используем текущую дату
      final date = targetDate ?? 
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      
      final response = await ApiService.get('/api/food-progress/meals/daily/$date');

      if (response.statusCode == 200) {
        final responseData = ApiService.decodeJson(response.body);
        // API может возвращать данные в обертке {"data": {...}}
        Map<String, dynamic> data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            data = responseData['data'] as Map<String, dynamic>;
          } else {
            data = responseData;
          }
        } else {
          throw Exception('Неверный формат ответа API');
        }
        return FoodProgressSummary.fromJson(data);
      } else {
        throw Exception(
          'Ошибка загрузки сводки: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки сводки: $e');
    }
  }

  /// Добавить цель
  static Future<FoodProgressTarget> addTarget({
    required double targetCalories,
    required double targetProteins,
    required double targetFats,
    required double targetCarbs,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/food-progress/targets/add/',
        body: {
          'target_calories': targetCalories,
          'target_proteins': targetProteins,
          'target_fats': targetFats,
          'target_carbs': targetCarbs,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.decodeJson(response.body);
        return FoodProgressTarget.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка создания цели: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка создания цели: $e');
    }
  }

  /// Добавить прием пищи
  static Future<FoodProgressMeal> addMeal({
    required DateTime mealDatetime,
    required String name,
    required double calories,
    double? proteins,
    double? fats,
    double? carbs,
  }) async {
    try {
      final body = <String, dynamic>{
        'meal_datetime': mealDatetime.toIso8601String(),
        'name': name,
        'calories': calories,
      };

      if (proteins != null) body['proteins'] = proteins;
      if (fats != null) body['fats'] = fats;
      if (carbs != null) body['carbs'] = carbs;

      final response = await ApiService.post(
        '/api/food-progress/meals/add/',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.decodeJson(response.body);
        return FoodProgressMeal.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка добавления в дневнике питания: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка добавления в дневнике питания: $e');
    }
  }

  /// Получить список приемов пищи
  /// [userUuid] - UUID пользователя
  /// [page] - номер страницы (по умолчанию 1)
  /// [size] - размер страницы (по умолчанию 10)
  static Future<FoodProgressMealsListResponse> getMeals({
    required String userUuid,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '/api/food-progress/meals/',
        queryParams: {
          'user_uuid': userUuid,
          'actual': 'true',
          'sort_by': 'meal_datetime',
          'page': page.toString(),
          'size': size.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is Map<String, dynamic>) {
          return FoodProgressMealsListResponse.fromJson(data);
        } else {
          throw Exception('Неверный формат ответа API');
        }
      } else {
        throw Exception(
          'Ошибка загрузки приемов пищи: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки приемов пищи: $e');
    }
  }

  /// Удалить прием пищи
  /// [mealUuid] - UUID приема пищи
  static Future<void> deleteMeal({
    required String mealUuid,
  }) async {
    try {
      final response = await ApiService.delete(
        '/api/food-progress/meals/delete/$mealUuid',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Ошибка удаления в дневнике питания: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка удаления в дневнике питания: $e');
    }
  }

  /// Обновить прием пищи
  /// [mealUuid] - UUID приема пищи
  static Future<FoodProgressMeal> updateMeal({
    required String mealUuid,
    required DateTime mealDatetime,
    required String name,
    double? proteins,
    double? fats,
    double? carbs,
  }) async {
    try {
      final body = <String, dynamic>{
        'meal_datetime': mealDatetime.toIso8601String(),
        'name': name,
      };

      if (proteins != null) body['proteins'] = proteins;
      if (fats != null) body['fats'] = fats;
      if (carbs != null) body['carbs'] = carbs;

      final response = await ApiService.put(
        '/api/food-progress/meals/update/$mealUuid',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return FoodProgressMeal.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка обновления в дневнике питания: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка обновления в дневнике питания: $e');
    }
  }
}

