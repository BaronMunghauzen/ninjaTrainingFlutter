import '../models/user_achievement_type_model.dart';
import 'api_service.dart';
import 'dart:convert';

class UserAchievementService {
  /// Получить достижения пользователя
  static Future<List<UserAchievementType>> getUserAchievements(
    String userUuid,
  ) async {
    try {
      final response = await ApiService.get('/achievements/user/$userUuid');
      
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final List<dynamic> achievementTypes = data['achievement_types'] ?? [];
        
        return achievementTypes
            .map((json) => UserAchievementType.fromJson(json))
            .toList();
      } else {
        print('Ошибка получения достижений: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Ошибка при загрузке достижений пользователя: $e');
      return [];
    }
  }
}

