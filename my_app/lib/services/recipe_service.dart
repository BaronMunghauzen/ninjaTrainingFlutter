import '../models/recipe_model.dart';
import 'api_service.dart';

class RecipeService {
  /// Получить рецепты, сгруппированные по категориям
  static Future<RecipesGroupedByCategoryResponse> getRecipesGroupedByCategory({
    bool actual = true,
  }) async {
    try {
      final response = await ApiService.get(
        '/api/recipes/grouped-by-category',
        queryParams: {'actual': actual.toString()},
      );

      if (response.statusCode == 200) {
        final responseData = ApiService.decodeJson(response.body);
        // API возвращает данные в обертке {"data": {...}}
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
        return RecipesGroupedByCategoryResponse.fromJson(data);
      } else {
        throw Exception(
          'Ошибка загрузки рецептов: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки рецептов: $e');
    }
  }

  /// Получить рецепты для одной категории
  static Future<List<Recipe>> getRecipesByCategory({
    required String category,
    bool actual = true,
  }) async {
    try {
      final response = await ApiService.get(
        '/api/recipes/grouped-by-category',
        queryParams: {
          'category': category,
          'actual': actual.toString(),
        },
      );

      if (response.statusCode == 200) {
        final responseData = ApiService.decodeJson(response.body);
        // API возвращает данные в обертке {"data": {...}}
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
        
        // Извлекаем рецепты для указанной категории
        final grouped = RecipesGroupedByCategoryResponse.fromJson(data);
        return grouped.getCategoryRecipes(category);
      } else {
        throw Exception(
          'Ошибка загрузки рецептов: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки рецептов для категории $category: $e');
    }
  }

  /// Получить список рецептов с пагинацией
  static Future<RecipesListResponse> getRecipes({
    String? category,
    String? name,
    bool? actual,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null) {
        queryParams['category'] = category;
      }
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }
      if (actual != null) {
        queryParams['actual'] = actual.toString();
      }

      final response = await ApiService.get(
        '/api/recipes/grouped-by-category',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = ApiService.decodeJson(response.body);
        // API возвращает данные в обертке {"data": {...}, "pagination": {...}}
        Map<String, dynamic> data;
        Map<String, dynamic>? pagination;
        
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            data = responseData['data'] as Map<String, dynamic>;
          } else {
            data = responseData;
          }
          if (responseData.containsKey('pagination')) {
            pagination = responseData['pagination'] as Map<String, dynamic>;
          }
        } else {
          throw Exception('Неверный формат ответа API');
        }
        
        // Если передан category, возвращаем только эту категорию
        if (category != null) {
          final grouped = RecipesGroupedByCategoryResponse.fromJson(data);
          final categoryRecipes = grouped.getCategoryRecipes(category);
          
          // Используем информацию о пагинации из ответа API
          final totalCount = pagination?['total_count'] as int? ?? categoryRecipes.length;
          final totalPages = pagination?['total_pages'] as int? ?? ((totalCount / size).ceil());
          
          return RecipesListResponse(
            items: categoryRecipes,
            total: totalCount,
            page: page,
            size: size,
            totalPages: totalPages > 0 ? totalPages : 1,
          );
        } else {
          // Если категория не указана, объединяем все категории
          final grouped = RecipesGroupedByCategoryResponse.fromJson(data);
          final allRecipes = [
            ...grouped.breakfast,
            ...grouped.lunch,
            ...grouped.dinner,
            ...grouped.salad,
            ...grouped.snack,
            ...grouped.dessert,
            ...grouped.other,
          ];
          
          // Используем информацию о пагинации из ответа API
          final totalCount = pagination?['total_count'] as int? ?? allRecipes.length;
          final totalPages = pagination?['total_pages'] as int? ?? ((totalCount / size).ceil());
          
          return RecipesListResponse(
            items: allRecipes,
            total: totalCount,
            page: page,
            size: size,
            totalPages: totalPages > 0 ? totalPages : 1,
          );
        }
      } else {
        throw Exception(
          'Ошибка загрузки рецептов: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки рецептов: $e');
    }
  }

  /// Получить рецепт по UUID
  static Future<Recipe> getRecipe(String uuid) async {
    try {
      final response = await ApiService.get('/api/recipes/$uuid');

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return Recipe.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка загрузки рецепта: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки рецепта: $e');
    }
  }

  /// Создать рецепт (админская версия)
  static Future<Recipe> createRecipe({
    required String category,
    required String name,
    required Map<String, String> ingredients,
    required String recipe,
    required double caloriesPer100g,
    required double proteinsPer100g,
    required double fatsPer100g,
    required double carbsPer100g,
    required double caloriesPerPortion,
    required double proteinsPerPortion,
    required double fatsPerPortion,
    required double carbsPerPortion,
    required int portionsCount,
    required int cookingTime,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/recipes/add/',
        body: {
          'category': category,
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
          'cooking_time': cookingTime,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.decodeJson(response.body);
        return Recipe.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка создания рецепта: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка создания рецепта: $e');
    }
  }

  /// Создать рецепт (юзерская версия)
  static Future<Recipe> createUserRecipe({
    required String userUuid,
    required String category,
    required String name,
    required Map<String, String> ingredients,
    required String recipe,
    required double caloriesPer100g,
    required double proteinsPer100g,
    required double fatsPer100g,
    required double carbsPer100g,
    required double caloriesPerPortion,
    required double proteinsPerPortion,
    required double fatsPerPortion,
    required double carbsPerPortion,
    required int portionsCount,
    required int cookingTime,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/recipes/add/',
        body: {
          'user_uuid': userUuid,
          'category': category,
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
          'cooking_time': cookingTime,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = ApiService.decodeJson(response.body);
        return Recipe.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка создания рецепта: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка создания рецепта: $e');
    }
  }

  /// Обновить рецепт
  static Future<Recipe> updateRecipe({
    required String recipeUuid,
    required String category,
    required String name,
    required Map<String, String> ingredients,
    required String recipe,
    required double caloriesPer100g,
    required double proteinsPer100g,
    required double fatsPer100g,
    required double carbsPer100g,
    required double caloriesPerPortion,
    required double proteinsPerPortion,
    required double fatsPerPortion,
    required double carbsPerPortion,
    required int portionsCount,
    required int cookingTime,
    String? userUuid,
  }) async {
    try {
      final body = <String, dynamic>{
        'category': category,
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
        'cooking_time': cookingTime,
      };

      if (userUuid != null) {
        body['user_uuid'] = userUuid;
      }

      final response = await ApiService.put(
        '/api/recipes/update/$recipeUuid',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return Recipe.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Ошибка обновления рецепта: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка обновления рецепта: $e');
    }
  }

  /// Удалить рецепт
  static Future<bool> deleteRecipe(String recipeUuid) async {
    try {
      final response = await ApiService.delete(
        '/api/recipes/delete/$recipeUuid',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Ошибка удаления рецепта: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка удаления рецепта: $e');
    }
  }

  /// Добавить рецепт в избранное
  static Future<bool> addToFavorites(String recipeUuid) async {
    try {
      final response = await ApiService.post(
        '/api/recipes/$recipeUuid/favorite',
        body: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
          'Ошибка добавления в избранное: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка добавления в избранное: $e');
    }
  }

  /// Удалить рецепт из избранного
  static Future<bool> removeFromFavorites(String recipeUuid) async {
    try {
      final response = await ApiService.delete(
        '/api/recipes/$recipeUuid/favorite',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Ошибка удаления из избранного: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }
}

