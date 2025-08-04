import '../models/search_result_model.dart';
import 'api_service.dart';

class SearchService {
  static Future<SearchResult?> search(
    String userUuid,
    String searchQuery,
  ) async {
    try {
      final response = await ApiService.get(
        '/service/search/?user_uuid=$userUuid&search_query=$searchQuery',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return SearchResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error searching: $e');
      return null;
    }
  }
}
