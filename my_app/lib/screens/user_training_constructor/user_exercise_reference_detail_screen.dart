import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/search_result_model.dart' as search_models;
import '../../widgets/gif_widget.dart';
import 'user_exercise_reference_edit_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserExerciseReferenceDetailScreen extends StatefulWidget {
  final search_models.ExerciseReference exercise;

  const UserExerciseReferenceDetailScreen({super.key, required this.exercise});

  @override
  State<UserExerciseReferenceDetailScreen> createState() =>
      _UserExerciseReferenceDetailScreenState();
}

class _UserExerciseReferenceDetailScreenState
    extends State<UserExerciseReferenceDetailScreen> {
  search_models.ExerciseReference? _exercise;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _fetchExercise();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _authToken = prefs.getString('user_token');
      });
    }
  }

  Future<void> _fetchExercise() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '/exercise_reference/${widget.exercise.uuid}',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          _exercise = search_models.ExerciseReference.fromJson(data);
          _isLoading = false;
        });
      } else {
        // Если запрос не удался, используем переданные данные
        setState(() {
          _exercise = widget.exercise;
          _isLoading = false;
        });
      }
    } catch (e) {
      // В случае ошибки используем переданные данные
      setState(() {
        _exercise = widget.exercise;
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите источник'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickAndUploadImage(source);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      setState(() {
        _isUploadingImage = true;
      });

      final exercise = _exercise ?? widget.exercise;

      final response = await ApiService.multipart(
        '/exercise_reference/${exercise.uuid}/upload-image',
        fileField: 'file',
        filePath: image.path,
        mimeType: 'image/jpeg',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение успешно загружено')),
        );
        await _fetchExercise();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка загрузки изображения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить изображение?'),
        content: const Text('Вы уверены, что хотите удалить изображение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final exercise = _exercise ?? widget.exercise;

    try {
      final response = await ApiService.delete(
        '/exercise_reference/${exercise.uuid}/delete-image',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Изображение успешно удалено')),
        );
        await _fetchExercise();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Ошибка удаления изображения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteExercise() async {
    final exercise = _exercise ?? widget.exercise;

    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: Text(
          'Вы уверены, что хотите удалить упражнение "${exercise.caption}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Сохраняем ссылки на navigator и messenger
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await ApiService.delete(
        '/exercise_reference/delete/${exercise.uuid}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Упражнение успешно удалено')),
        );
        navigator.pop(true); // Возвращаемся назад с результатом
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Ошибка при удалении упражнения'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.exercise.caption,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final exercise = _exercise ?? widget.exercise;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.caption,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (exercise.exerciseType == 'user') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserExerciseReferenceEditScreen(exercise: exercise),
                  ),
                );

                // Если упражнение было обновлено, обновляем экран
                if (result == true) {
                  _fetchExercise();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteExercise(),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название упражнения и индикатор типа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.caption,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exercise.exerciseType == 'user' ? 'Мое' : 'Системное',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Описание
            Text(
              'Описание:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Изображение (для пользовательских упражнений)
            if (exercise.exerciseType == 'user') ...[
              Text(
                'Изображение:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_isUploadingImage)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (exercise.image != null)
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Builder(
                          builder: (context) {
                            String? imageUuid;
                            final dynamic image = exercise.image;

                            if (image is String && image.isNotEmpty) {
                              imageUuid = image;
                            } else if (image is Map<String, dynamic>) {
                              imageUuid = image['uuid'] as String?;
                            }

                            if (imageUuid == null || imageUuid.isEmpty) {
                              return Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Нет изображения',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Image.network(
                              '${ApiService.baseUrl}/files/file/$imageUuid',
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              headers: _authToken != null
                                  ? {'Cookie': 'users_access_token=$_authToken'}
                                  : {},
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.inputBorder,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _deleteImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          tooltip: 'Удалить изображение',
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.inputBorder,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Добавьте изображение',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Гифка (только для системных упражнений)
            if (exercise.exerciseType == 'system')
              Builder(
                builder: (context) {
                  String? gifUuid;
                  final dynamic gif = exercise.gif;

                  // API может возвращать gif_uuid как строку или как объект
                  if (gif is String && gif.isNotEmpty) {
                    gifUuid = gif;
                  } else if (gif is Map<String, dynamic>) {
                    gifUuid = gif['uuid'] as String?;
                  }

                  if (gifUuid == null || gifUuid.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return GifWidget(
                    gifUuid: gifUuid,
                    height: 250,
                    width: double.infinity,
                  );
                },
              ),
            const SizedBox(height: 24),

            // Техника выполнения (если есть)
            if (exercise.techniqueDescription != null &&
                exercise.techniqueDescription!.isNotEmpty) ...[
              Text(
                'Техника выполнения:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.techniqueDescription!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Группа мышц
            Text(
              'Группа мышц:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.muscleGroup,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
