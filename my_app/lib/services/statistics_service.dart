import '../models/user_training_model.dart';
import '../models/measurement_type_model.dart';
import '../models/measurement_model.dart';
import '../models/training_detail_model.dart';
import '../models/exercise_model.dart';
import '../models/exercise_statistics_model.dart';
import 'api_service.dart';

class StatisticsService {
  /// Получить тренировки пользователя для календаря
  static Future<List<UserTrainingModel>?> getUserTrainingsForCalendar(
    String userUuid,
  ) async {
    try {
      final response = await ApiService.get(
        '/user_trainings',
        queryParams: {
          'user_uuid': userUuid,
          'status': 'PASSED',
          'is_rest_day': 'false',
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);

        // Получаем список тренировок
        List<dynamic> items = [];
        if (data['items'] != null) {
          items = data['items'] as List<dynamic>? ?? [];
        } else if (data['data'] != null) {
          items = data['data'] as List<dynamic>? ?? [];
        }

        final trainings = items
            .map((item) => UserTrainingModel.fromJson(item))
            .toList();

        return trainings;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Получить количество проведенных тренировок
  static Future<int?> getCompletedTrainingsCount(String userUuid) async {
    try {
      final response = await ApiService.get(
        '/user_trainings',
        queryParams: {
          'user_uuid': userUuid,
          'status': 'PASSED',
          'is_rest_day': 'false',
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);

        // Проверяем разные возможные структуры ответа
        int? totalCount;

        // Вариант 1: pagination.total_count
        final pagination = data['pagination'];
        if (pagination != null && pagination['total_count'] != null) {
          totalCount = pagination['total_count'];
        }

        // Вариант 2: data.total_count
        if (totalCount == null && data['total_count'] != null) {
          totalCount = data['total_count'];
        }

        // Вариант 3: если есть data array, считаем его длину
        if (totalCount == null && data['data'] != null) {
          final dataArray = data['data'] as List?;
          totalCount = dataArray?.length ?? 0;
        }

        final result = totalCount ?? 0;
        return result;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить детали тренировки с упражнениями
  static Future<TrainingDetailModel?> getTrainingDetails(
    String trainingUuid,
    String userUuid,
    String trainingDate,
  ) async {
    try {
      final response = await ApiService.get(
        '/user_exercises/',
        queryParams: {
          'training_uuid': trainingUuid,
          'user_uuid': userUuid,
          'training_date': trainingDate,
        },
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);

        // Проверяем, что data - это объект, а не массив
        if (data is Map<String, dynamic>) {
          return TrainingDetailModel.fromJson(data);
        } else if (data is List) {
          // Если массив упражнений - создаем TrainingDetailModel с упражнениями
          if (data.isEmpty) {
            // Если пустой массив - возвращаем null (нет упражнений)
            return null;
          } else {
            // Создаем TrainingDetailModel из массива упражнений
            final exercises = data
                .map((exercise) => UserExerciseModel.fromJson(exercise))
                .toList();
            return TrainingDetailModel(
              trainingDate: trainingDate,
              trainingCaption:
                  '', // Заголовок тренировки не приходит в этом API
              trainingDuration:
                  0, // Длительность тренировки не приходит в этом API
              trainingMuscleGroup: '', // Группа мышц не приходит в этом API
              exercises: exercises,
            );
          }
        } else {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить типы измерений
  static Future<List<MeasurementTypeModel>?> getMeasurementTypes({
    String? dataType,
    String? caption,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dataType != null) queryParams['data_type'] = dataType;
      if (caption != null) queryParams['caption'] = caption;

      final response = await ApiService.get(
        '/measurement-types/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body) as List<dynamic>;
        return data.map((item) => MeasurementTypeModel.fromJson(item)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить пользовательские типы измерений
  static Future<List<MeasurementTypeModel>?> getUserMeasurementTypes() async {
    try {
      final response = await ApiService.get('/measurement-types/user/');

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body) as List<dynamic>;
        return data.map((item) => MeasurementTypeModel.fromJson(item)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить измерения пользователя
  static Future<MeasurementResponseModel?> getUserMeasurements(
    String measurementTypeUuid, {
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'measurement_type_uuid': measurementTypeUuid,
      };
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await ApiService.get(
        '/measurements/user/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return MeasurementResponseModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Добавить измерение
  static Future<bool> addMeasurement({
    required String userUuid,
    required String measurementTypeUuid,
    required String measurementDate,
    required double value,
  }) async {
    try {
      final response = await ApiService.post(
        '/measurements/add/',
        body: {
          'user_uuid': userUuid,
          'measurement_type_uuid': measurementTypeUuid,
          'measurement_date': measurementDate,
          'value': value,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Обновить измерение
  static Future<bool> updateMeasurement({
    required String measurementUuid,
    required String measurementDate,
    required double value,
  }) async {
    try {
      final response = await ApiService.put(
        '/measurements/update/$measurementUuid',
        body: {'measurement_date': measurementDate, 'value': value},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Удалить измерение
  static Future<bool> deleteMeasurement(String measurementUuid) async {
    try {
      final response = await ApiService.delete(
        '/measurements/delete/$measurementUuid',
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Добавить тип измерения
  static Future<bool> addMeasurementType({
    required String userUuid,
    required String caption,
  }) async {
    try {
      final response = await ApiService.post(
        '/measurement-types/add/',
        body: {
          'data_type': 'custom',
          'user_uuid': userUuid,
          'caption': caption,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Обновить тип измерения
  static Future<bool> updateMeasurementType({
    required String measurementTypeUuid,
    required String caption,
  }) async {
    try {
      final response = await ApiService.put(
        '/measurement-types/update/$measurementTypeUuid',
        body: {'caption': caption},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Удалить тип измерения
  static Future<bool> deleteMeasurementType(String measurementTypeUuid) async {
    try {
      final response = await ApiService.post(
        '/measurement-types/archive/$measurementTypeUuid',
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Получить список упражнений с возможностью поиска
  static Future<List<ExerciseModel>?> getExerciseReferences({
    String? caption,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (caption != null && caption.isNotEmpty) {
        queryParams['caption'] = caption;
      }

      final response = await ApiService.get(
        '/exercise_reference/passed/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body) as List<dynamic>;
        return data.map((item) => ExerciseModel.fromJson(item)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить статистику упражнения
  static Future<ExerciseStatisticsModel?> getExerciseStatistics({
    required String exerciseReferenceUuid,
    required String userUuid,
  }) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/$exerciseReferenceUuid/statistics/$userUuid',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return ExerciseStatisticsModel.fromJson(data);
      } else {}
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить детали упражнения по UUID
  static Future<ExerciseModel?> getExerciseDetails(String exerciseUuid) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/$exerciseUuid',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return ExerciseModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
