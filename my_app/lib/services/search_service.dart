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
  static Future<search_models.ExerciseReferenceSearchResult>
  searchExerciseReferencesByCaption(
    String userUuid,
    String caption, {
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/available/$userUuid/search/by-caption',
        queryParams: {'caption': caption, 'page': page, 'size': size},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return search_models.ExerciseReferenceSearchResult.fromJson(data);
      }
      return search_models.ExerciseReferenceSearchResult(
        items: [],
        total: 0,
        page: page,
        size: size,
        pages: 0,
      );
    } catch (e) {
      print('Error searching exercise references by caption: $e');
      return search_models.ExerciseReferenceSearchResult(
        items: [],
        total: 0,
        page: page,
        size: size,
        pages: 0,
      );
    }
  }

  /// Поиск упражнений по названию для админов
  static Future<search_models.ExerciseReferenceSearchResult>
  searchAdminExerciseReferencesByCaption(
    String caption, {
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/search/by-caption',
        queryParams: {
          'caption': caption,
          'exercise_type': 'system',
          'page': page,
          'size': size,
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return search_models.ExerciseReferenceSearchResult.fromJson(data);
      }
      return search_models.ExerciseReferenceSearchResult(
        items: [],
        total: 0,
        page: page,
        size: size,
        pages: 0,
      );
    } catch (e) {
      print(
        '❌ SearchService: Ошибка поиска админских упражнений по названию: $e',
      );
      return search_models.ExerciseReferenceSearchResult(
        items: [],
        total: 0,
        page: page,
        size: size,
        pages: 0,
      );
    }
  }
}
