import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../widgets/gif_widget.dart';
import 'admin_exercise_reference_edit_screen.dart';

class AdminExerciseReferenceDetailScreen extends StatefulWidget {
  final String exerciseReferenceUuid;
  const AdminExerciseReferenceDetailScreen({
    Key? key,
    required this.exerciseReferenceUuid,
  }) : super(key: key);

  @override
  State<AdminExerciseReferenceDetailScreen> createState() =>
      _AdminExerciseReferenceDetailScreenState();
}

class _AdminExerciseReferenceDetailScreenState
    extends State<AdminExerciseReferenceDetailScreen> {
  Map<String, dynamic>? exercise;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercise();
  }

  Future<void> _fetchExercise() async {
    setState(() => isLoading = true);
    final response = await ApiService.get(
      '/exercise_reference/${widget.exerciseReferenceUuid}',
    );
    if (response.statusCode == 200) {
      setState(() {
        exercise = ApiService.decodeJson(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteExercise() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: const Text('Вы уверены, что хотите удалить упражнение?'),
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
      await ApiService.delete(
        '/exercise_reference/delete/${widget.exerciseReferenceUuid}',
      );
      Navigator.pop(context);
    }
  }

  // Функция для загрузки гифки
  Future<void> _uploadGif() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final File imageFile = File(image.path);
        final response = await ApiService.uploadFile(
          '/exercise_reference/${widget.exerciseReferenceUuid}/upload-gif',
          imageFile,
          'file',
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Гифка успешно загружена')),
          );
          _fetchExercise(); // Обновляем данные
        } else {
          // Пытаемся получить детали ошибки из ответа
          String errorMessage = 'Ошибка загрузки гифки: ${response.statusCode}';
          try {
            final errorData = ApiService.decodeJson(response.body);
            if (errorData is Map && errorData.containsKey('detail')) {
              errorMessage = errorData['detail'];
            }
          } catch (e) {
            // Если не удалось распарсить JSON, используем стандартное сообщение
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  // Функция для удаления гифки
  Future<void> _deleteGif() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить гифку?'),
        content: const Text('Вы уверены, что хотите удалить гифку?'),
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
      try {
        final response = await ApiService.delete(
          '/exercise_reference/${widget.exerciseReferenceUuid}/delete-gif',
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Гифка успешно удалена')),
          );
          _fetchExercise(); // Обновляем данные
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления гифки: ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Widget _buildFileManagementButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Управление гифкой',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _uploadGif,
                icon: const Icon(Icons.gif),
                label: const Text('Загрузить гифку'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: exercise!['gif_uuid'] != null ? _deleteGif : null,
                icon: const Icon(Icons.delete),
                label: const Text('Удалить гифку'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка упражнения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: exercise == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminExerciseReferenceEditScreen(
                          exercise: exercise!,
                        ),
                      ),
                    );
                    _fetchExercise();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить',
            onPressed: _deleteExercise,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercise == null
          ? const Center(child: Text('Ошибка загрузки'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    'Название: ${exercise!['caption'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Описание: ${exercise!['description'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text('Мышечная группа: ${exercise!['muscle_group'] ?? ''}'),
                  if (exercise!['technique_description'] != null &&
                      exercise!['technique_description']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Техника выполнения:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(exercise!['technique_description']),
                  ],
                  const SizedBox(height: 24),
                  // Гифка (отображаем только если есть gif_uuid)
                  if (exercise!['gif_uuid'] != null) ...[
                    GifWidget(gifUuid: exercise!['gif_uuid'], height: 250),
                    const SizedBox(height: 24),
                  ],
                  // Кнопки управления гифкой
                  _buildFileManagementButtons(),
                ],
              ),
            ),
    );
  }
}
