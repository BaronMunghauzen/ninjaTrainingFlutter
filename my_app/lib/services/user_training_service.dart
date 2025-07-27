import '../constants/api_constants.dart';
import 'api_service.dart';
import '../models/training_model.dart';
import '../models/exercise_model.dart';

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

  /// Получение пользовательских упражнений
  static Future<List<ExerciseReference>> getUserExerciseReferences(
    String userUuid,
  ) async {
    try {
      final response = await ApiService.get('/exercise_reference/');

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        // API возвращает данные напрямую как массив
        if (data is List) {
          return data.map((json) => ExerciseReference.fromJson(json)).toList();
        }
        // Альтернативный формат с полем data
        if (data is Map && data['status'] == 200 && data['data'] != null) {
          final List<dynamic> exercisesJson = data['data'];
          return exercisesJson
              .map((json) => ExerciseReference.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading user exercise references: $e');
      return [];
    }
  }

  /// Создание пользовательского упражнения
  static Future<Map<String, dynamic>?> createUserExercise({
    required String userUuid,
    required String caption,
    required String description,
    required String muscleGroup,
  }) async {
    try {
      final response = await ApiService.post(
        '/exercise_reference/add/',
        body: {
          'exercise_type': 'user',
          'user_uuid': userUuid,
          'caption': caption,
          'description': description,
          'muscle_group': muscleGroup,
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

  /// Создание пользовательской тренировки
  static Future<Map<String, dynamic>?> createUserTraining({
    required String userUuid,
    required String caption,
    required String description,
    required int difficultyLevel,
    required String muscleGroup,
  }) async {
    try {
      final response = await ApiService.post(
        '/trainings/add/',
        body: {
          'training_type': 'user',
          'user_uuid': userUuid,
          'caption': caption,
          'description': description,
          'difficulty_level': difficultyLevel,
          'muscle_group': muscleGroup,
        },
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
}

// Модели для упражнений и групп упражнений
class ExerciseReference {
  final String uuid;
  final String exerciseType;
  final String caption;
  final String description;
  final String muscleGroup;
  final String userUuid;

  ExerciseReference({
    required this.uuid,
    required this.exerciseType,
    required this.caption,
    required this.description,
    required this.muscleGroup,
    required this.userUuid,
  });

  factory ExerciseReference.fromJson(Map<String, dynamic> json) {
    return ExerciseReference(
      uuid: json['uuid'] ?? '',
      exerciseType: json['exercise_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      userUuid: json['user_uuid'] ?? '',
    );
  }
}

class ExerciseGroup {
  final String uuid;
  final String trainingUuid;
  final String caption;
  final String description;
  final String muscleGroup;
  final List<Exercise> exercises;

  ExerciseGroup({
    required this.uuid,
    required this.trainingUuid,
    required this.caption,
    required this.description,
    required this.muscleGroup,
    required this.exercises,
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
              ?.map((e) => Exercise.fromJson(e))
              .toList() ??
          [],
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
