import '../../../../services/api_service.dart';
import '../models/calorie_calculator_model.dart';

class CalorieCalculatorService {
  /// Получить последний расчет
  static Future<CalorieCalculation?> getLast() async {
    try {
      final response = await ApiService.get('/api/calorie-calculator/last');

      if (response.statusCode == 200) {
        final responseData = ApiService.decodeJson(response.body);
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
        return CalorieCalculation.fromJson(data);
      } else if (response.statusCode == 404) {
        // Нет последнего расчета
        return null;
      } else {
        throw Exception(
          'Ошибка загрузки последнего расчета: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка загрузки последнего расчета: $e');
    }
  }

  /// Рассчитать норму потребления
  static Future<CalorieCalculation> calculate({
    required String goal,
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activityCoefficient,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/calorie-calculator/calculate',
        body: {
          'goal': goal,
          'gender': gender,
          'weight': weight,
          'height': height,
          'age': age,
          'activity_coefficient': activityCoefficient,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = ApiService.decodeJson(response.body);
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
        return CalorieCalculation.fromJson(data);
      } else {
        throw Exception(
          'Ошибка расчета: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка расчета: $e');
    }
  }

  /// Деактивировать расчет
  static Future<bool> deactivate(String calculationUuid) async {
    try {
      final response = await ApiService.put(
        '/api/calorie-calculator/$calculationUuid/deactivate',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        throw Exception(
          'Ошибка деактивации расчета: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Ошибка деактивации расчета: $e');
    }
  }
}

