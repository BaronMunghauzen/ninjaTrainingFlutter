import 'api_service.dart';
import '../models/user_training_model.dart';

class TrainingService {
  // Кэш для тренировок пользователя
  // static final Map<String, List<Map<String, dynamic>>> _trainingsCache = {}; // Удаляем кэш
  static final Map<String, List<Map<String, dynamic>>> _exerciseGroupsCache =
      {};

  // Оптимизация: индексы для быстрого поиска тренировок
  static final Map<String, Map<String, Map<String, dynamic>>>
  _trainingsIndexCache = {};
  static final Map<String, Map<String, dynamic>?> _activeTrainingCache = {};

  static Future<List<Map<String, dynamic>>> getUserTrainings(
    String userProgramUuid,
  ) async {
    // Не используем кэш
    try {
      final response = await ApiService.get(
        '/user_trainings/',
        queryParams: {'user_program_uuid': userProgramUuid},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        List trainings;
        if (data is Map && data.containsKey('data')) {
          trainings = data['data'] as List;
        } else if (data is List) {
          trainings = data;
        } else {
          trainings = [];
        }
        final trainingsList = trainings.cast<Map<String, dynamic>>();
        // _trainingsCache[userProgramUuid] = trainingsList; // Не сохраняем в кэш
        // Оптимизация: строим индекс для быстрого поиска
        _buildTrainingsIndex(userProgramUuid, trainingsList);
        return trainingsList;
      }
      return [];
    } catch (e) {
      print('Error loading user trainings: $e');
      rethrow;
    }
  }

  // Оптимизация: создание индекса тренировок для быстрого поиска
  static void _buildTrainingsIndex(
    String userProgramUuid,
    List<Map<String, dynamic>> trainings,
  ) {
    final index = <String, Map<String, dynamic>>{};

    for (final training in trainings) {
      final week = training['week']?.toString() ?? '';
      final weekday = training['weekday']?.toString() ?? '';
      final key = '$week:$weekday';
      index[key] = training;
    }

    _trainingsIndexCache[userProgramUuid] = index;

    // Очищаем кэш активной тренировки при обновлении данных
    _activeTrainingCache.remove(userProgramUuid);
  }

  static Future<List<Map<String, dynamic>>> getExerciseGroups(
    String trainingUuid,
  ) async {
    // Проверяем кэш
    if (_exerciseGroupsCache.containsKey(trainingUuid)) {
      return _exerciseGroupsCache[trainingUuid]!;
    }

    try {
      final response = await ApiService.get(
        '/exercise-groups/',
        queryParams: {'training_uuid': trainingUuid},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          final groups = data.cast<Map<String, dynamic>>();
          // Сохраняем в кэш
          _exerciseGroupsCache[trainingUuid] = groups;
          return groups;
        }
      }
      return [];
    } catch (e) {
      print('Error loading exercise groups: $e');
      rethrow;
    }
  }

  static Future<bool> finishUserProgram(String userProgramUuid) async {
    try {
      final response = await ApiService.post(
        '/user_programs/finish/$userProgramUuid',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error finishing user program: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> skipUserTrainingWithResponse(
    String userTrainingUuid,
  ) async {
    try {
      final response = await ApiService.post(
        '/user_trainings/$userTrainingUuid/skip',
      );
      if (response.statusCode == 200) {
        _trainingsIndexCache.clear();
        _activeTrainingCache.clear();
        final data = ApiService.decodeJson(response.body);
        return {
          'success': true,
          'next_stage_created': data['next_stage_created'] == true,
        };
      }
      return {'success': false, 'next_stage_created': false};
    } catch (e) {
      print('Error skipping user training: $e');
      return {'success': false, 'next_stage_created': false};
    }
  }

  static Future<Map<String, dynamic>> passUserTrainingWithResponse(
    String userTrainingUuid,
  ) async {
    try {
      final response = await ApiService.post(
        '/user_trainings/$userTrainingUuid/pass',
      );
      if (response.statusCode == 200) {
        _trainingsIndexCache.clear();
        _activeTrainingCache.clear();
        final data = ApiService.decodeJson(response.body);
        return {
          'success': true,
          'next_stage_created': data['next_stage_created'] == true,
        };
      }
      return {'success': false, 'next_stage_created': false};
    } catch (e) {
      print('Error passing user training: $e');
      return {'success': false, 'next_stage_created': false};
    }
  }

  static Future<bool> refreshUserProgramAndSchedule({
    required String userProgramUuid,
    required String userUuid,
    required String programUuid,
  }) async {
    try {
      // Получить user_program (активную)
      final userProgramResponse = await ApiService.get(
        '/user_programs/',
        queryParams: {
          'user_uuid': userUuid,
          'status': 'active',
          'program_uuid': programUuid,
        },
      );
      if (userProgramResponse.statusCode != 200) return false;
      // Получить расписание по user_program
      final trainings = await getUserTrainings(userProgramUuid);
      return trainings.isNotEmpty;
    } catch (e) {
      print('Error refreshing user program and schedule: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getActiveUserProgram({
    required String userUuid,
    required String programUuid,
  }) async {
    try {
      final response = await ApiService.get(
        '/user_programs/',
        queryParams: {
          'user_uuid': userUuid,
          'status': 'active',
          'program_uuid': programUuid,
        },
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List && data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting active user program: $e');
      return null;
    }
  }

  // Метод для получения текущей активной тренировки
  static Map<String, dynamic>? getCurrentTraining(
    List<Map<String, dynamic>> trainings,
  ) {
    // Сначала ищем тренировку со статусом 'active'
    for (final training in trainings) {
      if (training['status'] == 'active') {
        return training;
      }
    }

    // Если нет активной, ищем тренировку на сегодня
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final training in trainings) {
      final trainingDate = DateTime.parse(training['training_date']);
      final trainingDay = DateTime(
        trainingDate.year,
        trainingDate.month,
        trainingDate.day,
      );

      if (trainingDay.isAtSameMomentAs(today)) {
        return training;
      }
    }
    return null;
  }

  // Оптимизация: получение тренировки по неделе и дню O(1)
  static Map<String, dynamic>? getTrainingByWeekAndDay(
    List<Map<String, dynamic>> trainings,
    int week,
    int day,
  ) {
    // Если у нас есть кэшированные тренировки, используем индекс
    for (final entry in _trainingsIndexCache.entries) {
      if (entry.value == trainings) {
        final userProgramUuid = entry.key;
        final index = _trainingsIndexCache[userProgramUuid];
        if (index != null) {
          final key = '$week:$day';
          return index[key];
        }
        break;
      }
    }

    // Fallback: линейный поиск (если индекс недоступен)
    for (final training in trainings) {
      if (training['week'] == week && training['weekday'] == day) {
        return training;
      }
    }
    return null;
  }

  // Оптимизация: получение активной тренировки с кэшированием
  static Map<String, dynamic>? getActiveTraining(
    List<Map<String, dynamic>> trainings,
  ) {
    // Если у нас есть кэшированные тренировки, используем кэш активной тренировки
    for (final entry in _trainingsIndexCache.entries) {
      if (entry.value == trainings) {
        final userProgramUuid = entry.key;

        // Проверяем кэш активной тренировки
        if (_activeTrainingCache.containsKey(userProgramUuid)) {
          return _activeTrainingCache[userProgramUuid];
        }

        // Ищем активную тренировку и кэшируем результат
        for (final training in trainings) {
          if (training['status'] == 'active') {
            _activeTrainingCache[userProgramUuid] = training;
            return training;
          }
        }

        // Если не нашли активную, кэшируем null
        _activeTrainingCache[userProgramUuid] = null;
        return null;
      }
    }

    // Fallback: обычный поиск
    for (final training in trainings) {
      if (training['status'] == 'active') {
        return training;
      }
    }
    return null;
  }

  // Метод для очистки кэша тренировок при обновлении статуса
  static void clearTrainingsCache(String userProgramUuid) {
    // Не делаем ничего, кэш не используется
  }

  // Метод для очистки кэша групп упражнений
  static void clearExerciseGroupsCache(String trainingUuid) {
    _exerciseGroupsCache.remove(trainingUuid);
  }

  // Метод для очистки всего кэша
  static void clearAllCache() {
    // _trainingsCache.clear(); // Удаляем кэш
    _trainingsIndexCache.clear();
    _activeTrainingCache.clear();
    _exerciseGroupsCache.clear();
  }
}
