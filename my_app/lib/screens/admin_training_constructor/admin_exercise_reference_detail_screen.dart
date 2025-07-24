import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
                ],
              ),
            ),
    );
  }
}
