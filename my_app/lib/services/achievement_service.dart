import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/achievement_model.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class AchievementService {
  // Получить достижения пользователя
  static Future<List<AchievementModel>> getUserAchievements() async {
    try {
      final response = await ApiService.get('http://10.0.2.2:8000/achievements/user');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AchievementModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки достижений пользователя: $e');
    }
  }

  // Получить достижения пользователя по UUID
  static Future<List<AchievementModel>> getUserAchievementsByUuid(String userUuid) async {
    try {
      print('Получаем достижения пользователя $userUuid...');
      final response = await ApiService.get('http://10.0.2.2:8000/achievements/user/$userUuid');
      
      print('Статус ответа: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('API вернул пустой ответ для пользователя, возвращаем пустой список');
          return [];
        }
        
        print('Тело ответа: ${response.body}');
        
        try {
          final List<dynamic> data = json.decode(response.body);
          print('Получено ${data.length} достижений пользователя');
          return data.map((json) => AchievementModel.fromJson(json)).toList();
        } catch (parseError) {
          print('Ошибка парсинга JSON: $parseError');
          return [];
        }
      } else {
        print('API вернул статус ${response.statusCode}, возвращаем пустой список');
        return [];
      }
    } catch (e) {
      print('Ошибка получения достижений пользователя: $e');
      print('Используем mock данные для демонстрации');
      return _getMockUserAchievements();
    }
  }

  // Mock данные для достижений пользователя (для демонстрации)
  static List<AchievementModel> _getMockUserAchievements() {
    return [
      // Пользователь получил эти достижения
      AchievementModel(
        uuid: '2', // Регистрация
        title: 'Регистрация',
        description: 'Зарегистрируйтесь в приложении',
        category: 'Общие',
        type: AchievementType.general,
        targetValue: 1,
        currentValue: 1,
        isUnlocked: true,
        rewardDescription: 'Доступ к функциям',
        unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        icon: '✅',
      ),
      AchievementModel(
        uuid: '4', // Неделя тренировок
        title: 'Неделя тренировок',
        description: 'Тренируйтесь 7 дней подряд',
        category: 'Тренировки',
        type: AchievementType.training,
        targetValue: 7,
        currentValue: 7,
        isUnlocked: true,
        rewardDescription: 'Бонус выносливости',
        unlockedAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        icon: '📅',
      ),
      AchievementModel(
        uuid: '6', // Мастер техники
        title: 'Мастер техники',
        description: 'Выполните 100 повторений',
        category: 'Упражнения',
        type: AchievementType.exercise,
        targetValue: 100,
        currentValue: 100,
        isUnlocked: true,
        rewardDescription: 'Улучшение техники',
        unlockedAt: DateTime.now().subtract(const Duration(hours: 6)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        icon: '🎯',
      ),
    ];
  }

  // Получить все достижения
  static Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final response = await ApiService.get('http://10.0.2.2:8000/achievements');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AchievementModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки всех достижений: $e');
    }
  }

  // Получить достижения из таблицы achievement_types
  static Future<List<AchievementModel>> getAchievementsFromTypesTable() async {
    try {
      print('Пытаемся получить достижения из API...');
      
      // Пробуем простой endpoint для получения всех достижений
      const String endpoint = 'http://10.0.2.2:8000/achievements/types';
      print('Пробуем endpoint: $endpoint');

      final response = await ApiService.get(endpoint);
      print('Статус ответа: ${response.statusCode}');
      
      // Проверяем HTTP статус
      if (response.statusCode != 200) {
        print('API вернул статус ${response.statusCode}, используем mock данные');
        return _getMockAchievements();
      }
      
      // Проверяем, что ответ не пустой
      if (response.body.isEmpty) {
        print('API вернул пустой ответ, используем mock данные');
        return _getMockAchievements();
      }
      
      print('Тело ответа: ${response.body}');
      
      try {
        final dynamic responseData = json.decode(response.body);
        print('API Response type: ${responseData.runtimeType}');
        
        List<dynamic> data;
        if (responseData is Map<String, dynamic>) {
          // Ищем ключ с данными
          if (responseData.containsKey('data')) {
            data = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('achievements')) {
            data = responseData['achievements'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            data = responseData['results'] as List<dynamic>;
          } else if (responseData.containsKey('items')) {
            data = responseData['items'] as List<dynamic>;
          } else if (responseData.containsKey('content')) {
            data = responseData['content'] as List<dynamic>;
          } else {
            print('API вернул Map без списка достижений, используем mock данные');
            return _getMockAchievements();
          }
        } else if (responseData is List<dynamic>) {
          data = responseData;
        } else {
          print('Неожиданный тип данных от API, используем mock данные');
          return _getMockAchievements();
        }
        
        print('Найдено ${data.length} достижений в API');
        return data.map((json) => AchievementModel.fromJson(json)).toList();
        
      } catch (parseError) {
        print('Ошибка парсинга JSON: $parseError, используем mock данные');
        return _getMockAchievements();
      }
      
    } catch (e) {
      print('API недоступен, используем mock данные. Ошибка: $e');
      return _getMockAchievements();
    }
  }

  // Получить достижения по конкретному UUID типа достижения
  static Future<List<AchievementModel>> getAchievementsByTypeUuid(String achievementTypeUuid) async {
    try {
      final String endpoint = 'http://10.0.2.2:8000/achievements/types/$achievementTypeUuid';
      
      print('Запрашиваем достижения типа с UUID: $achievementTypeUuid');
      print('Endpoint: $endpoint');

      final response = await ApiService.get(endpoint);
      print('Статус ответа: ${response.statusCode}');
      print('Заголовки ответа: ${response.headers}');
      
      // Проверяем HTTP статус
      if (response.statusCode != 200) {
        print('Тело ответа с ошибкой: ${response.body}');
        throw Exception('API вернул статус ${response.statusCode}: ${response.body}');
      }
      
      print('Тело ответа (первые 500 символов): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
      
      // Проверяем, что ответ не пустой
      if (response.body.isEmpty) {
        throw Exception('API вернул пустой ответ');
      }
      
      // Проверяем Content-Type
      final contentType = response.headers['content-type'] ?? '';
      print('Content-Type: $contentType');
      
      final dynamic responseData = json.decode(response.body);
      
      // Проверяем, что получили от API
      print('API Response type: ${responseData.runtimeType}');
      print('API Response: $responseData');
      
      List<dynamic> data;
      if (responseData is Map<String, dynamic>) {
        // Если API возвращает Map, ищем ключ с данными
        if (responseData.containsKey('data')) {
          data = responseData['data'] as List<dynamic>;
        } else if (responseData.containsKey('achievements')) {
          data = responseData['achievements'] as List<dynamic>;
        } else if (responseData.containsKey('results')) {
          data = responseData['results'] as List<dynamic>;
        } else if (responseData.containsKey('items')) {
          data = responseData['items'] as List<dynamic>;
        } else if (responseData.containsKey('content')) {
          data = responseData['content'] as List<dynamic>;
        } else {
          // Если нет стандартных ключей, пробуем найти любой List
          final listValues = responseData.values.where((value) => value is List).toList();
          if (listValues.isNotEmpty) {
            data = listValues.first as List<dynamic>;
            print('Найден список в ключе: ${responseData.keys.firstWhere((key) => responseData[key] == data)}');
          } else {
            // Выводим все ключи для отладки
            print('Доступные ключи в ответе: ${responseData.keys.toList()}');
            print('Типы значений: ${responseData.values.map((v) => '${v.runtimeType}: $v').toList()}');
            print('Полный ответ API: $responseData');
            
            // Если есть ключ 'detail', выводим его содержимое
            if (responseData.containsKey('detail')) {
              print('Детали ошибки: ${responseData['detail']}');
            }
            
            throw Exception('API вернул Map, но не содержит список достижений. Доступные ключи: ${responseData.keys.toList()}');
          }
        }
      } else if (responseData is List<dynamic>) {
        data = responseData;
      } else {
        throw Exception('Неожиданный тип данных от API: ${responseData.runtimeType}');
      }
      
      print('Найдено ${data.length} достижений для типа $achievementTypeUuid');
      return data.map((json) => AchievementModel.fromJson(json)).toList();
      
    } catch (e) {
      print('Ошибка при получении достижений по UUID типа: $e');
      throw Exception('Ошибка загрузки достижений по UUID типа $achievementTypeUuid: $e');
    }
  }

  // Получить список всех типов достижений
  static Future<List<Map<String, dynamic>>> getAchievementTypes() async {
    try {
      // Пробуем разные endpoints для получения типов достижений
      final List<String> endpoints = [
        'http://10.0.2.2:8000/achievements/types',
        'http://10.0.2.2:8000/api/achievement_types',
        'http://10.0.2.2:8000/achievement_types',
      ];
      
      String endpoint = '';
      http.Response? response;
      
      for (final String ep in endpoints) {
        try {
          print('Пробуем endpoint: $ep');
          response = await ApiService.get(ep);
          if (response.statusCode == 200) {
            endpoint = ep;
            break;
          }
        } catch (e) {
          print('Ошибка для endpoint $ep: $e');
          continue;
        }
      }
      
      if (response == null || response!.statusCode != 200) {
        throw Exception('Не удалось получить данные ни с одного endpoint');
      }
      
      print('Успешно получили ответ с endpoint: $endpoint');
      print('Статус ответа: ${response!.statusCode}');
      print('Заголовки ответа: ${response.headers}');
      
      // Проверяем, что ответ не пустой
      if (response.body.isEmpty) {
        throw Exception('API вернул пустой ответ');
      }
      
      print('Тело ответа (первые 500 символов): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
      
      final dynamic responseData = json.decode(response.body);
      
      // Проверяем, что получили от API
      print('API Response type: ${responseData.runtimeType}');
      print('API Response: $responseData');
      
      List<dynamic> data;
      if (responseData is Map<String, dynamic>) {
        // Если API возвращает Map, ищем ключ с данными
        if (responseData.containsKey('data')) {
          data = responseData['data'] as List<dynamic>;
        } else if (responseData.containsKey('types')) {
          data = responseData['types'] as List<dynamic>;
        } else if (responseData.containsKey('results')) {
          data = responseData['results'] as List<dynamic>;
        } else if (responseData.containsKey('items')) {
          data = responseData['items'] as List<dynamic>;
        } else if (responseData.containsKey('content')) {
          data = responseData['content'] as List<dynamic>;
        } else {
          // Если нет стандартных ключей, пробуем найти любой List
          final listValues = responseData.values.where((value) => value is List).toList();
          if (listValues.isNotEmpty) {
            data = listValues.first as List<dynamic>;
            print('Найден список в ключе: ${responseData.keys.firstWhere((key) => responseData[key] == data)}');
          } else {
            // Выводим все ключи для отладки
            print('Доступные ключи в ответе: ${responseData.keys.toList()}');
            print('Типы значений: ${responseData.values.map((v) => '${v.runtimeType}: $v').toList()}');
            print('Полный ответ API: $responseData');
            
            // Если есть ключ 'detail', выводим его содержимое
            if (responseData.containsKey('detail')) {
              print('Детали ошибки: ${responseData['detail']}');
            }
            
            throw Exception('API вернул Map, но не содержит список типов достижений. Доступные ключи: ${responseData.keys.toList()}');
          }
        }
      } else if (responseData is List<dynamic>) {
        data = responseData;
      } else {
        throw Exception('Неожиданный тип данных от API: ${responseData.runtimeType}');
      }
      
      print('Найдено ${data.length} типов достижений');
      return data.cast<Map<String, dynamic>>();
      
    } catch (e) {
      print('Ошибка при получении типов достижений: $e');
      throw Exception('Ошибка загрузки типов достижений: $e');
    }
  }

  // Временные mock данные для тестирования интерфейса
  static List<AchievementModel> _getMockAchievements() {
    return [
      // Общие достижения
      AchievementModel(
        uuid: '1',
        title: 'Первые шаги',
        description: 'Начните свой путь к успеху',
        category: 'Общие',
        type: AchievementType.general,
        targetValue: 1,
        currentValue: 0,
        isUnlocked: false,
        rewardDescription: 'Базовый опыт',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '⭐',
      ),
      AchievementModel(
        uuid: '2',
        title: 'Регистрация',
        description: 'Зарегистрируйтесь в приложении',
        category: 'Общие',
        type: AchievementType.general,
        targetValue: 1,
        currentValue: 1,
        isUnlocked: false, // Изменено на false для демонстрации
        rewardDescription: 'Доступ к функциям',
        unlockedAt: null, // Изменено на null для демонстрации
        createdAt: DateTime.now(),
        icon: '✅',
      ),
      
      // Тренировки
      AchievementModel(
        uuid: '3',
        title: 'Первая тренировка',
        description: 'Завершите первую тренировку',
        category: 'Тренировки',
        type: AchievementType.training,
        targetValue: 1,
        currentValue: 0,
        isUnlocked: false,
        rewardDescription: 'Опыт тренировок',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '💪',
      ),
      AchievementModel(
        uuid: '4',
        title: 'Неделя тренировок',
        description: 'Тренируйтесь 7 дней подряд',
        category: 'Тренировки',
        type: AchievementType.training,
        targetValue: 7,
        currentValue: 3,
        isUnlocked: false,
        rewardDescription: 'Бонус выносливости',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '📅',
      ),
      
      // Упражнения
      AchievementModel(
        uuid: '5',
        title: 'Разнообразие',
        description: 'Выполните 10 различных упражнений',
        category: 'Упражнения',
        type: AchievementType.exercise,
        targetValue: 10,
        currentValue: 6,
        isUnlocked: false,
        rewardDescription: 'Опыт упражнений',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '🏃',
      ),
      AchievementModel(
        uuid: '6',
        title: 'Мастер техники',
        description: 'Выполните 100 повторений',
        category: 'Упражнения',
        type: AchievementType.exercise,
        targetValue: 100,
        currentValue: 75,
        isUnlocked: false,
        rewardDescription: 'Улучшение техники',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '🎯',
      ),
      
      // Стреж
      AchievementModel(
        uuid: '7',
        title: 'Начало пути',
        description: 'Тренируйтесь 3 дня подряд',
        category: 'Стреж',
        type: AchievementType.streak,
        targetValue: 3,
        currentValue: 2,
        isUnlocked: false,
        rewardDescription: 'Бонус мотивации',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '🔥',
      ),
      
      // Время
      AchievementModel(
        uuid: '8',
        title: 'Выносливость',
        description: 'Тренируйтесь 30 минут подряд',
        category: 'Время',
        type: AchievementType.time,
        targetValue: 30,
        currentValue: 25,
        isUnlocked: false,
        rewardDescription: 'Повышение выносливости',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '⏱️',
      ),
      
      // Социальные
      AchievementModel(
        uuid: '9',
        title: 'Команда',
        description: 'Присоединитесь к группе',
        category: 'Социальные',
        type: AchievementType.social,
        targetValue: 1,
        currentValue: 0,
        isUnlocked: false,
        rewardDescription: 'Социальные бонусы',
        unlockedAt: null,
        createdAt: DateTime.now(),
        icon: '👥',
      ),
    ];
  }

  // Получить достижение по ID
  static Future<AchievementModel> getAchievementById(String id) async {
    try {
      final response = await ApiService.get('http://10.0.2.2:8000/achievements/$id');
      final Map<String, dynamic> data = json.decode(response.body);
      return AchievementModel.fromJson(data);
    } catch (e) {
      throw Exception('Ошибка загрузки достижения по ID: $e');
    }
  }

  // Обновить прогресс достижения
  static Future<AchievementModel> updateAchievementProgress(String achievementId, int newValue) async {
    try {
      final response = await ApiService.put(
        'http://10.0.2.2:8000/achievements/$achievementId/progress',
        body: {'current_value': newValue},
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return AchievementModel.fromJson(data);
    } catch (e) {
      throw Exception('Ошибка обновления прогресса достижения: $e');
    }
  }

  // Разблокировать достижение
  static Future<AchievementModel> unlockAchievement(String achievementId) async {
    try {
      final response = await ApiService.post(
        'http://10.0.2.2:8000/achievements/$achievementId/unlock',
        body: {},
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return AchievementModel.fromJson(data);
    } catch (e) {
      throw Exception('Ошибка разблокировки достижения: $e');
    }
  }

  // Получить достижения по типу
  static Future<List<AchievementModel>> getAchievementsByType(AchievementType type) async {
    try {
      final response = await ApiService.get('http://10.0.2.2:8000/achievements/type/${type.name}');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AchievementModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки достижений по типу: $e');
    }
  }

  // Получить статистику достижений
  static Future<Map<String, dynamic>> getAchievementsStats() async {
    try {
      final response = await ApiService.get('http://10.0.2.2:8000/achievements/stats');
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Ошибка загрузки статистики достижений: $e');
    }
  }

  // Проверить и обновить достижения
  static Future<void> checkAndUpdateAchievements() async {
    try {
      await ApiService.post('http://10.0.2.2:8000/achievements/check', body: {});
    } catch (e) {
      throw Exception('Ошибка проверки достижений: $e');
    }
  }

  // Получить недавно разблокированные достижения
  static Future<List<AchievementModel>> getRecentlyUnlockedAchievements() async {
    try {
      final response = await ApiService.get('http://10.0.2.2:8000/achievements/recent');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => AchievementModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки недавних достижений: $e');
    }
  }
}
