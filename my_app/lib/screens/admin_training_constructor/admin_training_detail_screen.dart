import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/avatar_modal.dart';
import '../../constants/app_colors.dart';
import 'admin_training_edit_screen.dart';
import 'admin_exercise_group_detail_screen.dart';
import 'admin_exercise_group_create_screen.dart';

class AdminTrainingDetailScreen extends StatefulWidget {
  final String trainingUuid;
  const AdminTrainingDetailScreen({Key? key, required this.trainingUuid})
    : super(key: key);

  @override
  State<AdminTrainingDetailScreen> createState() =>
      _AdminTrainingDetailScreenState();
}

class _AdminTrainingDetailScreenState extends State<AdminTrainingDetailScreen> {
  Map<String, dynamic>? training;
  bool isLoading = true;
  List<Map<String, dynamic>> exerciseGroups = [];
  bool isLoadingGroups = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _fetchTraining();
    _fetchExerciseGroups();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('user_token');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Запрашивать список групп упражнений при каждом попадании на страницу
    final route = ModalRoute.of(context);
    if (route != null) {
      route.addScopedWillPopCallback(() async {
        _fetchExerciseGroups();
        return true;
      });
    }
    _fetchExerciseGroups();
  }

  Future<void> _fetchTraining() async {
    setState(() => isLoading = true);
    final response = await ApiService.get('/trainings/${widget.trainingUuid}');
    if (response.statusCode == 200) {
      setState(() {
        training = ApiService.decodeJson(response.body);
        isLoading = false;
      });
      _fetchExerciseGroups(); // Добавлено: всегда обновлять группы после загрузки тренировки
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTraining() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text('Вы уверены, что хотите удалить тренировку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.delete('/trainings/delete/${widget.trainingUuid}');
      Navigator.pop(context);
    }
  }

  Future<void> _fetchExerciseGroups() async {
    if (training == null) return;
    setState(() => isLoadingGroups = true);
    final resp = await ApiService.get(
      '/exercise-groups/',
      queryParams: {'training_uuid': training!['uuid']},
    );
    if (resp.statusCode == 200) {
      final data = ApiService.decodeJson(resp.body);
      setState(() {
        exerciseGroups = List<Map<String, dynamic>>.from(data);
        isLoadingGroups = false;
      });
    } else {
      setState(() => isLoadingGroups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка тренировки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: training == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminTrainingEditScreen(training: training!),
                      ),
                    );
                    _fetchTraining();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить',
            onPressed: _deleteTraining,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : training == null
          ? const Center(child: Text('Ошибка загрузки'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Картинка тренировки
                  Center(
                    child: GestureDetector(
                      onTap: () => _showImageModal(
                        context,
                        training!['image_uuid'] != null,
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: training!['image_uuid'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  '${ApiService.baseUrl}/files/file/${training!['image_uuid']}',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  headers: _authToken != null
                                      ? {
                                          'Cookie':
                                              'users_access_token=$_authToken',
                                        }
                                      : {},
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.fitness_center,
                                      size: 60,
                                      color: AppColors.textSecondary,
                                    );
                                  },
                                  key: ValueKey(training!['image_uuid']),
                                ),
                              )
                            : const Icon(
                                Icons.fitness_center,
                                size: 60,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Название: ${training!['caption'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Описание: ${training!['description'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text('Сложность: ${training!['difficulty_level'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text('Продолжительность: ${training!['duration'] ?? ''} мин'),
                  const SizedBox(height: 8),
                  Text('Порядок: ${training!['order'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text('Мышечная группа: ${training!['muscle_group'] ?? ''}'),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Группы упражнений:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        tooltip: 'Добавить группу',
                        onPressed: () async {
                          if (training == null) return;
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdminExerciseGroupCreateScreen(
                                    trainingUuid: training!['uuid'],
                                  ),
                            ),
                          );
                          if (result == true) _fetchExerciseGroups();
                        },
                      ),
                    ],
                  ),
                  isLoadingGroups
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : exerciseGroups.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Нет групп упражнений'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: exerciseGroups.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, idx) {
                            final group = exerciseGroups[idx];
                            return ListTile(
                              title: Text(group['caption'] ?? ''),
                              subtitle: Text(
                                'Порядок: ${group['order'] ?? '-'}, Мышцы: ${group['muscle_group'] ?? '-'}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminExerciseGroupDetailScreen(
                                          exerciseGroupUuid: group['uuid'],
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  // Метод для показа модального окна управления картинкой
  void _showImageModal(BuildContext context, bool hasImage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AvatarModal(
        hasAvatar: hasImage,
        onUploadPhoto: _handleTrainingImageUpload,
        onDeletePhoto: hasImage ? _handleTrainingImageDelete : null,
      ),
    );
  }

  Future<void> _handleTrainingImageUpload() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (result != null) {
      final fileBytes = await result.readAsBytes();
      final fileName = result.name;
      final error = await _uploadTrainingImage(fileBytes, fileName);

      if (mounted) {
        if (error == null) {
          setState(() {});
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Картинка успешно загружена',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              backgroundColor: AppColors.surface,
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleTrainingImageDelete() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final error = await _deleteTrainingImage();

    if (mounted) {
      if (error == null) {
        setState(() {});
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Картинка успешно удалена',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surface,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Загрузка картинки тренировки
  Future<String?> _uploadTrainingImage(
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      // Создаем временный файл
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);

      final response = await ApiService.uploadFile(
        '/trainings/${widget.trainingUuid}/upload-image',
        tempFile,
        'file',
      );

      // Удаляем временный файл
      await tempFile.delete();

      if (response.statusCode == 200) {
        // Обновляем данные тренировки
        await _fetchTraining();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка загрузки картинки';
      }
    } catch (e) {
      return 'Ошибка загрузки картинки: $e';
    }
  }

  // Удаление картинки тренировки
  Future<String?> _deleteTrainingImage() async {
    try {
      final response = await ApiService.delete(
        '/trainings/${widget.trainingUuid}/delete-image',
      );

      if (response.statusCode == 200) {
        // Обновляем данные тренировки
        await _fetchTraining();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка удаления картинки';
      }
    } catch (e) {
      return 'Ошибка удаления картинки: $e';
    }
  }
}
