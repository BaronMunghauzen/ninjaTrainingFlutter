import 'api_service.dart';
import '../models/training_model.dart';
import '../models/search_result_model.dart' as search_models;

class UserTrainingService {
  /// Получение пользовательских тренировок
  static Future<List<Training>> getUserTrainings(
    String userUuid, {
    bool actual = true,
  }) async {
    try {
      final response = await ApiService.get(
        '/trainings/',
        queryParams: {
          'training_type': 'user',
          'user_uuid': userUuid,
          if (actual) 'actual': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        // API возвращает данные напрямую как массив
        if (data is List) {
          return data.map((json) => Training.fromJson(json)).toList();
        }
        // Альтернативный формат с полем data
        if (data is Map && data['status'] == 200 && data['data'] != null) {
          final List<dynamic> trainingsJson = data['data'];
          return trainingsJson.map((json) => Training.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading user trainings: $e');
      return [];
    }
  }

  /// Получение доступных упражнений для пользователя
  static Future<search_models.ExerciseReferenceSearchResult>
  getUserExerciseReferences(
    String userUuid, {
    int page = 1,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/available/$userUuid',
        queryParams: {'page': page, 'size': size},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);

        // Проверяем, есть ли пагинация в ответе
        if (data is Map && data['items'] != null) {
          // Новый формат с пагинацией
          return search_models.ExerciseReferenceSearchResult.fromJson(
            Map<String, dynamic>.from(data),
          );
        } else if (data is List) {
          // Старый формат без пагинации (для обратной совместимости)
          final items = data
              .map((json) => search_models.ExerciseReference.fromJson(json))
              .toList();
          return search_models.ExerciseReferenceSearchResult(
            items: items,
            total: items.length,
            page: page,
            size: size,
            pages: 1,
          );
        }
      }

      // Возвращаем пустой результат в случае ошибки
      return search_models.ExerciseReferenceSearchResult(
        items: [],
        total: 0,
        page: page,
        size: size,
        pages: 0,
      );
    } catch (e) {
      print('Error loading available exercise references: $e');
      return search_models.ExerciseReferenceSearchResult(
        items: [],
        total: 0,
        page: page,
        size: size,
        pages: 0,
      );
    }
  }

  /// Создание пользовательского упражнения
  static Future<Map<String, dynamic>?> createUserExercise({
    required String userUuid,
    required String caption,
    String? description,
    required String muscleGroup,
    String? equipmentName,
  }) async {
    try {
      final response = await ApiService.post(
        '/exercise_reference/add/',
        body: {
          'exercise_type': 'user',
          'user_uuid': userUuid,
          'caption': caption,
          'description': description ?? '',
          'muscle_group': muscleGroup,
          'equipment_name': equipmentName ?? 'Без оборудования',
        },
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating user exercise: $e');
      return null;
    }
  }

  /// Обновление пользовательского упражнения
  static Future<Map<String, dynamic>?> updateUserExercise({
    required String exerciseUuid,
    required String userUuid,
    required String caption,
    required String description,
    required String muscleGroup,
    String? equipmentName,
  }) async {
    try {
      final response = await ApiService.put(
        '/exercise_reference/update/$exerciseUuid',
        body: {
          'exercise_type': 'user',
          'user_uuid': userUuid,
          'caption': caption,
          'description': description,
          'muscle_group': muscleGroup,
          'equipment_name': equipmentName ?? 'Без оборудования',
        },
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      }
      return null;
    } catch (e) {
      print('Error updating user exercise: $e');
      return null;
    }
  }

  /// Создание пользовательской тренировки
  static Future<Map<String, dynamic>?> createUserTraining({
    required String userUuid,
    required String caption,
    String? description,
    int? difficultyLevel,
    String? muscleGroup,
  }) async {
    try {
      final body = <String, dynamic>{
        'training_type': 'user',
        'user_uuid': userUuid,
        'caption': caption,
        'actual': true,
      };
      // Добавляем описание только если оно заполнено
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      // Добавляем группу мышц только если она заполнена
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        body['muscle_group'] = muscleGroup;
      }
      // difficulty_level не отправляется на бэк
      
      final response = await ApiService.post(
        '/trainings/add/',
        body: body,
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating user training: $e');
      return null;
    }
  }

  /// Обновление пользовательской тренировки
  static Future<Map<String, dynamic>?> updateUserTraining({
    required String trainingUuid,
    required String caption,
    String? description,
    String? muscleGroup,
  }) async {
    try {
      final body = {
        'caption': caption,
        // Отправляем явно null, если поля пустые
        'description': (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : null,
        'muscle_group': (muscleGroup != null && muscleGroup.trim().isNotEmpty)
            ? muscleGroup.trim()
            : null,
      };
      
      // difficulty_level больше не отправляется
      
      final response = await ApiService.put(
        '/trainings/update/$trainingUuid',
        body: body,
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      }
      return null;
    } catch (e) {
      print('Error updating user training: $e');
      return null;
    }
  }

  /// Получение групп упражнений для тренировки
  static Future<List<ExerciseGroup>> getExerciseGroupsForTraining(
    String trainingUuid,
  ) async {
    try {
      final response = await ApiService.get(
        '/exercise-groups/',
        queryParams: {'training_uuid': trainingUuid},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        // API возвращает данные напрямую как массив
        if (data is List) {
          return data.map((json) => ExerciseGroup.fromJson(json)).toList();
        }
        // Альтернативный формат с полем data
        if (data is Map && data['status'] == 200 && data['data'] != null) {
          final List<dynamic> groupsJson = data['data'];
          return groupsJson
              .map((json) => ExerciseGroup.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading exercise groups: $e');
      return [];
    }
  }

  /// Создание упражнения
  static Future<Map<String, dynamic>?> createExercise({
    required String userUuid,
    required String caption,
    required String description,
    required String muscleGroup,
    required int setsCount,
    required int repsCount,
    required int restTime,
    required bool withWeight,
    required double weight,
    required String exerciseReferenceUuid,
  }) async {
    try {
      final response = await ApiService.post(
        '/exercises/add/',
        body: {
          'exercise_type': 'user',
          'user_uuid': userUuid,
          'caption': caption,
          'description': description,
          'muscle_group': muscleGroup,
          'sets_count': setsCount,
          'reps_count': repsCount,
          'rest_time': restTime,
          'with_weight': withWeight,
          'weight': weight,
          'exercise_reference_uuid': exerciseReferenceUuid,
        },
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating exercise: $e');
      return null;
    }
  }

  /// Создание группы упражнений
  static Future<Map<String, dynamic>?> createExerciseGroup({
    required String trainingUuid,
    required String caption,
    required String description,
    required String muscleGroup,
    required List<String> exercises,
  }) async {
    try {
      final response = await ApiService.post(
        '/exercise-groups/add/',
        body: {
          'training_uuid': trainingUuid,
          'caption': caption,
          'description': description,
          'muscle_group': muscleGroup,
          'exercises': exercises,
        },
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating exercise group: $e');
      return null;
    }
  }

  /// Удаление упражнения
  static Future<bool> deleteExercise(String exerciseUuid) async {
    try {
      final response = await ApiService.delete(
        '/exercises/delete/$exerciseUuid',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting exercise: $e');
      return false;
    }
  }

  /// Удаление группы упражнений
  static Future<bool> deleteExerciseGroup(String exerciseGroupUuid) async {
    try {
      final response = await ApiService.delete(
        '/exercise-groups/delete/$exerciseGroupUuid',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting exercise group: $e');
      return false;
    }
  }

  /// Удаление тренировки
  static Future<bool> deleteTraining(String trainingUuid) async {
    try {
      final response = await ApiService.delete(
        '/trainings/delete/$trainingUuid',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting training: $e');
      return false;
    }
  }

  /// Архивирование тренировки
  static Future<bool> archiveTraining(String trainingUuid) async {
    try {
      final response = await ApiService.post(
        '/trainings/$trainingUuid/archive',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error archiving training: $e');
      return false;
    }
  }

  /// Восстановление тренировки из архива
  static Future<bool> restoreTraining(String trainingUuid) async {
    try {
      final response = await ApiService.post(
        '/trainings/$trainingUuid/restore',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error restoring training: $e');
      return false;
    }
  }

  /// Удаление упражнения из справочника
  static Future<bool> deleteExerciseReference(
    String exerciseReferenceUuid,
  ) async {
    try {
      final response = await ApiService.delete(
        '/exercise_reference/delete/$exerciseReferenceUuid',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting exercise reference: $e');
      return false;
    }
  }

  /// Получение пользовательской тренировки по UUID
  static Future<Training?> getUserTrainingByUuid(String trainingUuid) async {
    try {
      final response = await ApiService.get('/trainings/$trainingUuid');

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is Map<String, dynamic>) {
          return Training.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error loading user training: $e');
      return null;
    }
  }

  /// Добавить упражнение в избранное
  static Future<bool> addToFavorites(String exerciseUuid) async {
    try {
      final response = await ApiService.post(
        '/exercise_reference/$exerciseUuid/favorite',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding exercise to favorites: $e');
      return false;
    }
  }

  /// Удалить упражнение из избранного
  static Future<bool> removeFromFavorites(String exerciseUuid) async {
    try {
      final response = await ApiService.delete(
        '/exercise_reference/$exerciseUuid/favorite',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing exercise from favorites: $e');
      return false;
    }
  }
}

// Модели для упражнений и групп упражнений
class ExerciseReference {
  final String uuid;
  final String exerciseType;
  final String caption;
  final String description;
  final String muscleGroup;
  final String? userUuid;
  final String? imageUuid;
  final String? videoUuid;
  final String createdAt;
  final String updatedAt;

  ExerciseReference({
    required this.uuid,
    required this.exerciseType,
    required this.caption,
    required this.description,
    required this.muscleGroup,
    this.userUuid,
    this.imageUuid,
    this.videoUuid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseReference.fromJson(Map<String, dynamic> json) {
    return ExerciseReference(
      uuid: json['uuid'] ?? '',
      exerciseType: json['exercise_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      userUuid: json['user_uuid'],
      imageUuid: json['image_uuid'],
      videoUuid: json['video_uuid'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ExerciseGroup {
  final String uuid;
  final String trainingUuid;
  final String caption;
  final String description;
  final String muscleGroup;
  final List<String> exercises; // Изменено на List<String> для UUID
  final int? setsCount;
  final int? repsCount;
  final int? restTime;
  final bool? withWeight;

  ExerciseGroup({
    required this.uuid,
    required this.trainingUuid,
    required this.caption,
    required this.description,
    required this.muscleGroup,
    required this.exercises,
    this.setsCount,
    this.repsCount,
    this.restTime,
    this.withWeight,
  });

  factory ExerciseGroup.fromJson(Map<String, dynamic> json) {
    return ExerciseGroup(
      uuid: json['uuid'] ?? '',
      trainingUuid: json['training_uuid'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      setsCount: json['sets_count'],
      repsCount: json['reps_count'],
      restTime: json['rest_time'],
      withWeight: json['with_weight'],
    );
  }
}

class Exercise {
  final String uuid;
  final String exerciseType;
  final String userUuid;
  final String caption;
  final String description;
  final String muscleGroup;
  final int setsCount;
  final int repsCount;
  final int restTime;
  final bool withWeight;
  final double weight;
  final String exerciseReferenceUuid;

  Exercise({
    required this.uuid,
    required this.exerciseType,
    required this.userUuid,
    required this.caption,
    required this.description,
    required this.muscleGroup,
    required this.setsCount,
    required this.repsCount,
    required this.restTime,
    required this.withWeight,
    required this.weight,
    required this.exerciseReferenceUuid,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      uuid: json['uuid'] ?? '',
      exerciseType: json['exercise_type'] ?? '',
      userUuid: json['user_uuid'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      setsCount: json['sets_count'] ?? 0,
      repsCount: json['reps_count'] ?? 0,
      restTime: json['rest_time'] ?? 0,
      withWeight: json['with_weight'] ?? false,
      weight: (json['weight'] ?? 0).toDouble(),
      exerciseReferenceUuid: json['exercise_reference_uuid'] ?? '',
    );
  }
}
