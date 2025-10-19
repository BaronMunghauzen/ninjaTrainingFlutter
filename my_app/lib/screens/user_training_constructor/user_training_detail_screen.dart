import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import '../../widgets/auth_image_widget.dart';
import 'user_exercise_group_create_screen.dart';
import 'user_exercise_group_detail_screen.dart';
import 'user_training_edit_screen.dart';

class UserTrainingDetailScreen extends StatefulWidget {
  final Training training;
  final VoidCallback? onDataChanged;

  const UserTrainingDetailScreen({
    super.key,
    required this.training,
    this.onDataChanged,
  });

  @override
  State<UserTrainingDetailScreen> createState() =>
      _UserTrainingDetailScreenState();
}

class _UserTrainingDetailScreenState extends State<UserTrainingDetailScreen> {
  late Training _training;
  List<ExerciseGroup> exerciseGroups = [];
  Map<String, Map<String, dynamic>> exerciseData =
      {}; // UUID группы -> данные упражнения
  bool isLoading = true;
  String? _imageUuid; // UUID изображения тренировки

  @override
  void initState() {
    super.initState();
    _training = widget.training;
    _imageUuid = _training.imageUuid; // Инициализируем UUID изображения
    _loadExerciseGroups();
  }

  Future<void> _loadExerciseGroups() async {
    try {
      final groups = await UserTrainingService.getExerciseGroupsForTraining(
        _training.uuid,
      );

      // Загружаем данные для каждого упражнения в группах
      Map<String, Map<String, dynamic>> exerciseDataMap = {};
      for (final group in groups) {
        if (group.exercises.isNotEmpty) {
          try {
            final response = await ApiService.get(
              '/exercises/${group.exercises.first}',
            );
            if (response.statusCode == 200) {
              final data = ApiService.decodeJson(response.body);
              exerciseDataMap[group.uuid] = data;
            }
          } catch (e) {
            print('Error loading exercise data for group ${group.uuid}: $e');
            // Устанавливаем значения по умолчанию
            exerciseDataMap[group.uuid] = {
              'sets_count': 3,
              'reps_count': 12,
              'rest_time': 60,
              'with_weight': true,
            };
          }
        }
      }

      setState(() {
        exerciseGroups = groups;
        exerciseData = exerciseDataMap;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading exercise groups: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Обновляет данные тренировки после редактирования
  Future<void> _refreshTrainingData() async {
    try {
      final updatedTraining = await UserTrainingService.getUserTrainingByUuid(
        _training.uuid,
      );

      if (updatedTraining != null) {
        setState(() {
          // Обновляем локальную переменную состояния
          _training = updatedTraining;
        });
      }
    } catch (e) {
      print('Error refreshing training data: $e');
    }
  }

  Future<void> _uploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        requestFullMetadata:
            false, // Отключаем метаданные для лучшей производительности
      );

      if (image != null) {
        print('Загружаем изображение: ${image.path}');
        // Создаем multipart request для загрузки файла
        final uri = Uri.parse(
          '${ApiService.baseUrl}/trainings/${_training.uuid}/upload-image',
        );
        final request = http.MultipartRequest('POST', uri);

        // Добавляем заголовки авторизации
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('user_token');
        if (token != null) {
          request.headers['Cookie'] = 'users_access_token=$token';
        }

        // Добавляем файл с правильным Content-Type
        final fileExtension = image.path.split('.').last.toLowerCase();
        String contentType;

        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          default:
            contentType = 'image/jpeg'; // По умолчанию
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            contentType: MediaType.parse(contentType),
          ),
        );

        // Отправляем запрос
        print('Отправляем запрос на: $uri');
        print('Заголовки: ${request.headers}');
        print('Файлы: ${request.files.map((f) => f.field).toList()}');
        print('Content-Type файла: $contentType');
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        print('Ответ сервера: ${response.statusCode}');
        print('Тело ответа: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['image_uuid'] != null) {
            setState(() {
              _imageUuid = responseData['image_uuid'];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Изображение успешно загружено')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка: не получен UUID изображения'),
              ),
            );
          }
        } else {
          final errorBody = response.body;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка загрузки (${response.statusCode}): ${errorBody.isNotEmpty ? errorBody : 'Неизвестная ошибка'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteImage() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удаление изображения'),
          content: const Text(
            'Вы уверены, что хотите удалить изображение тренировки?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final response = await ApiService.delete(
          '/trainings/${_training.uuid}/delete-image',
        );

        if (response.statusCode == 200) {
          setState(() {
            _imageUuid = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Изображение успешно удалено')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _training.caption,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      UserTrainingEditScreen(training: _training),
                ),
              );
              if (result == true) {
                // Обновляем данные тренировки
                await _refreshTrainingData();
                // Обновляем список групп упражнений
                _loadExerciseGroups();
              }
            },
          ),
          if (_training.actual)
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Архивирование тренировки'),
                    content: const Text(
                      'Вы уверены, что хотите архивировать эту тренировку?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Архивировать'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final success = await UserTrainingService.archiveTraining(
                    _training.uuid,
                  );
                  if (success) {
                    // Вызываем callback для обновления данных на родительской странице
                    print(
                      'UserTrainingDetailScreen: Вызываем callback после архивации',
                    );
                    widget.onDataChanged?.call();
                    Navigator.of(context).pop();
                  }
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.unarchive),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Восстановление тренировки'),
                    content: const Text(
                      'Вы уверены, что хотите восстановить эту тренировку из архива?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Восстановить'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final success = await UserTrainingService.restoreTraining(
                    _training.uuid,
                  );
                  if (success) {
                    // Вызываем callback для обновления данных на родительской странице
                    print(
                      'UserTrainingDetailScreen: Вызываем callback после восстановления',
                    );
                    widget.onDataChanged?.call();
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Информация о тренировке
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Изображение тренировки
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        child: _imageUuid != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Builder(
                                  builder: (context) {
                                    try {
                                      return AuthImageWidget(
                                        imageUuid: _imageUuid!,
                                        width: 80,
                                        height: 80,
                                      );
                                    } catch (e) {
                                      // Если ошибка декодирования, показываем заглушку
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: AppColors.textSecondary,
                                          size: 32,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: AppColors.textSecondary,
                                  size: 32,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _training.caption,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _training.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Кнопки управления изображением
                      Column(
                        children: [
                          IconButton(
                            onPressed: _uploadImage,
                            icon: const Icon(Icons.add_photo_alternate),
                            tooltip: 'Загрузить изображение',
                          ),
                          if (_imageUuid != null)
                            IconButton(
                              onPressed: _deleteImage,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Удалить изображение',
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Группа мышц: ${_training.muscleGroup}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Уровень сложности: ${_training.difficultyLevel}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Заголовок списка упражнений
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Упражнения',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          // Список групп упражнений
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                    ),
                  )
                : exerciseGroups.isEmpty
                ? const Center(
                    child: Text(
                      'В этой тренировке пока нет упражнений',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exerciseGroups.length,
                    itemBuilder: (context, index) {
                      final group = exerciseGroups[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            group.caption,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Информация о подходах, повторениях, времени отдыха и весе
                              Row(
                                children: [
                                  _buildInfoChip(
                                    'Подходы',
                                    exerciseData[group.uuid]?['sets_count']
                                            ?.toString() ??
                                        '3',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    'Повторения',
                                    exerciseData[group.uuid]?['reps_count']
                                            ?.toString() ??
                                        '12',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    'Отдых',
                                    '${exerciseData[group.uuid]?['rest_time'] ?? 60}с',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    'Вес',
                                    (exerciseData[group.uuid]?['with_weight'] ??
                                            true)
                                        ? 'С весом'
                                        : 'Без веса',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserExerciseGroupDetailScreen(
                                      exerciseGroup: group,
                                      onDataChanged: () {
                                        // Обновляем данные на этой странице
                                        _loadExerciseGroups();
                                        // Вызываем callback родительской страницы
                                        widget.onDataChanged?.call();
                                      },
                                    ),
                              ),
                            );
                            // Обновляем данные после возврата (на случай если не было удаления)
                            if (result == true) {
                              _loadExerciseGroups();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  UserExerciseGroupCreateScreen(trainingUuid: _training.uuid),
            ),
          );
          if (result == true) {
            _loadExerciseGroups();
          }
        },
        backgroundColor: AppColors.buttonPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
