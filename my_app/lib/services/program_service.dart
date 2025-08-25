import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/program_model.dart';
import '../models/user_training_model.dart';
import 'api_service.dart';

class ProgramService {
  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static String baseUrl() {
    return ApiConstants.baseUrl;
  }

  static dynamic decodeJson(String jsonString) {
    return ApiService.decodeJson(jsonString);
  }

  static Future<List<Program>> getActualPrograms() async {
    try {
      final response = await ApiService.get(
        '/programs/',
        queryParams: {'program_type': 'system', 'actual': 'true'},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          return data.map((json) => Program.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading actual programs: $e');
      rethrow;
    }
  }

  static Future<List<Program>> getPrograms() async {
    try {
      final response = await ApiService.get(
        '/programs/',
        queryParams: {'program_type': 'system'},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          final programs = data.map((json) => Program.fromJson(json)).toList();
          // Сортируем по полю order
          programs.sort((a, b) => a.order.compareTo(b.order));
          return programs;
        }
      }
      return [];
    } catch (e) {
      print('Error loading programs: $e');
      rethrow;
    }
  }

  static Future<Program?> getProgramById(String programUuid) async {
    try {
      final response = await ApiService.get('/programs/$programUuid');

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return Program.fromJson(data);
      } else {
        print('Failed to load program: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading program: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserPrograms(
    String userUuid, {
    String? programUuid,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_uuid': userUuid,
        'status': 'active',
      };

      if (programUuid != null) {
        queryParams['program_uuid'] = programUuid;
      }

      final response = await ApiService.get(
        '/user_programs/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        return {'status': 200, 'data': data};
      } else if (response.statusCode == 404) {
        return {'status': 404, 'data': null};
      } else {
        print('Failed to load user programs: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading user programs: $e');
      rethrow;
    }
  }

  static Future<bool> finishUserProgram(String userProgramId) async {
    try {
      final response = await ApiService.post(
        '/user_programs/finish/$userProgramId',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error finishing user program: $e');
      rethrow;
    }
  }

  static Future<String?> addUserProgram(
    String programUuid,
    String userUuid,
    String? caption,
  ) async {
    try {
      // Если caption не передан, получаем его из программы
      String programCaption = caption ?? '';
      if (caption == null) {
        final program = await getProgramById(programUuid);
        if (program != null) {
          programCaption = program.caption;
        }
      }

      final body = {
        'program_uuid': programUuid,
        'user_uuid': userUuid,
        'caption': programCaption,
      };

      final response = await ApiService.post('/user_programs/add/', body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = ApiService.decodeJson(response.body);
        return data['uuid'];
      } else {
        print('Failed to add user program: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error adding user program: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProgramById(
    String userProgramUuid,
  ) async {
    try {
      final response = await ApiService.get('/user_programs/$userProgramUuid');

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      } else {
        print('Failed to load user program: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading user program: $e');
      rethrow;
    }
  }

  static Future<List<UserTrainingModel>?> getUserTrainings(
    String userProgramUuid,
    String userUuid,
  ) async {
    try {
      final queryParams = {
        'user_program_uuid': userProgramUuid,
        'user_uuid': userUuid,
      };

      final response = await ApiService.get(
        '/user_trainings/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          return data.map((json) => UserTrainingModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading user trainings: $e');
      rethrow;
    }
  }

  static Future<bool> finishUserTraining(String userTrainingUuid) async {
    try {
      final response = await ApiService.post(
        '/user_trainings/finish/$userTrainingUuid',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error finishing user training: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserTrainingById(
    String userTrainingUuid,
  ) async {
    try {
      final response = await ApiService.get(
        '/user_trainings/$userTrainingUuid',
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      } else {
        print('Failed to load user training: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading user training: $e');
      rethrow;
    }
  }

  static Future<bool> updateUserTrainingStage(
    String userTrainingUuid,
    int newStage,
  ) async {
    try {
      final body = {'stage': newStage};
      final response = await ApiService.put(
        '/user_trainings/$userTrainingUuid',
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user training stage: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTrainings(
    String programUuid,
  ) async {
    try {
      final queryParams = {'program_uuid': programUuid};
      final response = await ApiService.get(
        '/trainings/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error loading trainings: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getTrainingById(
    String trainingUuid,
  ) async {
    try {
      final response = await ApiService.get('/trainings/$trainingUuid');

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      } else {
        print('Failed to load training: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading training: $e');
      rethrow;
    }
  }

  static Future<bool> deleteTraining(String trainingUuid) async {
    try {
      final response = await ApiService.delete('/trainings/$trainingUuid');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting training: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getExerciseGroups(
    String trainingUuid,
  ) async {
    try {
      final queryParams = {'training_uuid': trainingUuid};
      final response = await ApiService.get(
        '/exercise-groups/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          final groups = data.cast<Map<String, dynamic>>();
          return groups;
        }
      }
      return [];
    } catch (e) {
      print('Error loading exercise groups: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getExerciseGroupById(
    String exerciseGroupUuid,
  ) async {
    try {
      final response = await ApiService.get(
        '/exercise-groups/$exerciseGroupUuid',
      );

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      } else {
        print('Failed to load exercise group: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading exercise group: $e');
      rethrow;
    }
  }

  static Future<bool> deleteExerciseGroup(String exerciseGroupUuid) async {
    try {
      final response = await ApiService.delete(
        '/exercise-groups/$exerciseGroupUuid',
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting exercise group: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getExercises(
    String exerciseGroupUuid,
  ) async {
    try {
      final queryParams = {'exercise_group_uuid': exerciseGroupUuid};
      final response = await ApiService.get(
        '/exercises/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error loading exercises: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getExerciseById(
    String exerciseUuid,
  ) async {
    try {
      final response = await ApiService.get('/exercises/$exerciseUuid');

      if (response.statusCode == 200) {
        return ApiService.decodeJson(response.body);
      } else {
        print('Failed to load exercise: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading exercise: $e');
      rethrow;
    }
  }

  static Future<bool> deleteExercise(String exerciseUuid) async {
    try {
      final response = await ApiService.delete(
        '/exercises/delete/$exerciseUuid',
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting exercise: $e');
      rethrow;
    }
  }

  static Future<bool> createProgram({
    required String caption,
    required String description,
    String? categoryUuid,
    required int weeksCount,
    required String imageUrl,
    bool? actual,
    String? programType,
    int? difficultyLevel,
    int? order,
    String? scheduleType,
    String? trainingDays,
  }) async {
    try {
      final body = <String, dynamic>{
        'caption': caption,
        'description': description,
        'weeks_count': weeksCount,
      };

      // Добавляем image_url только если он не пустой
      if (imageUrl.isNotEmpty) {
        body['image_url'] = imageUrl;
      }

      if (categoryUuid != null && categoryUuid.isNotEmpty) {
        body['category_uuid'] = categoryUuid;
      }

      if (actual != null) body['actual'] = actual;
      if (programType != null) body['program_type'] = programType;
      if (difficultyLevel != null) body['difficulty_level'] = difficultyLevel;
      if (order != null) body['order'] = order;
      if (scheduleType != null) body['schedule_type'] = scheduleType;
      if (trainingDays != null) body['training_days'] = trainingDays;

      print('Creating program with body: $body');
      print('Body type: ${body.runtimeType}');
      print('Body keys: ${body.keys.toList()}');

      final response = await ApiService.post('/programs/add/', body: body);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      // Проверяем различные успешные статусы
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print(
          'Failed to create program. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error creating program: $e');
      return false;
    }
  }

  static Future<bool> updateProgramPartial({
    required String programUuid,
    String? caption,
    String? description,
    String? categoryUuid,
    int? weeksCount,
    String? imageUrl,
    Map<String, dynamic>? changedParameters,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (changedParameters != null) {
        body.addAll(changedParameters);
      } else {
        if (caption != null) body['caption'] = caption;
        if (description != null) body['description'] = description;
        if (categoryUuid != null) body['category_uuid'] = categoryUuid;
        if (weeksCount != null) body['weeks_count'] = weeksCount;
        if (imageUrl != null) body['image_url'] = imageUrl;
      }

      final response = await ApiService.put(
        '/programs/update/$programUuid',
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating program: $e');
      return false;
    }
  }
}
