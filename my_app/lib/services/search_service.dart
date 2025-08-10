import '../models/search_result_model.dart' as search_models;
import 'api_service.dart';
import 'user_training_service.dart';

class SearchService {
  static Future<search_models.SearchResult?> search(
    String userUuid,
    String searchQuery,
  ) async {
    try {
      final response = await ApiService.get(
        '/service/search/?user_uuid=$userUuid&search_query=$searchQuery',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return search_models.SearchResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error searching: $e');
      return null;
    }
  }

  /// Поиск упражнений по названию
  static Future<List<ExerciseReference>> searchExerciseReferencesByCaption(
    String userUuid,
    String caption,
  ) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/available/$userUuid/search/by-caption?caption=$caption',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          return data.map((json) => ExerciseReference.fromJson(json)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error searching exercise references by caption: $e');
      return [];
    }
  }

  /// Поиск упражнений по названию для админов
  static Future<List<ExerciseReference>> searchAdminExerciseReferencesByCaption(
    String caption,
  ) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/search/by-caption',
        queryParams: {'caption': caption, 'exercise_type': 'system'},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);

        if (data is List) {
          final results = data
              .map((json) => ExerciseReference.fromJson(json))
              .toList();
          return results;
        }
        return [];
      }
      return [];
    } catch (e) {
      print(
        '❌ SearchService: Ошибка поиска админских упражнений по названию: $e',
      );
      return [];
    }
  }
}
