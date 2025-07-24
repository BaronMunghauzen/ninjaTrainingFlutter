import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_exercise_create_screen.dart';
import 'admin_exercise_edit_screen.dart';

class AdminExerciseGroupDetailScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  const AdminExerciseGroupDetailScreen({
    Key? key,
    required this.exerciseGroupUuid,
  }) : super(key: key);

  @override
  State<AdminExerciseGroupDetailScreen> createState() =>
      _AdminExerciseGroupDetailScreenState();
}

class _AdminExerciseGroupDetailScreenState
    extends State<AdminExerciseGroupDetailScreen> {
  Map<String, dynamic>? group;
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  bool isLoadingExercises = false;

  @override
  void initState() {
    super.initState();
    _fetchGroup();
  }

  Future<void> _fetchGroup() async {
    setState(() => isLoading = true);
    final resp = await ApiService.get(
      '/exercise-groups/${widget.exerciseGroupUuid}',
    );
    if (resp.statusCode == 200) {
      setState(() {
        group = ApiService.decodeJson(resp.body);
        isLoading = false;
      });
      _fetchExercises();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchExercises() async {
    if (group == null || group!['exercises'] == null) {
      setState(() => exercises = []);
      return;
    }
    setState(() => isLoadingExercises = true);
    final List exUuids = group!['exercises'];
    List<Map<String, dynamic>> loaded = [];
    for (final uuid in exUuids) {
      try {
        final resp = await ApiService.get('/exercises/$uuid');
        if (resp.statusCode == 200) {
          final exJson = ApiService.decodeJson(resp.body);
          loaded.add(exJson);
        }
      } catch (_) {}
    }
    setState(() {
      exercises = loaded;
      isLoadingExercises = false;
    });
  }

  Future<void> _deleteExercise(String uuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: const Text(
          'Вы уверены, что хотите удалить это упражнение из группы?',
        ),
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
      await ApiService.post(
        '/exercise-groups/${widget.exerciseGroupUuid}/remove-exercise',
        body: {'exercise_uuid': uuid},
      );
      _fetchGroup();
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить группу упражнений?'),
        content: const Text(
          'Вы уверены, что хотите удалить эту группу упражнений?',
        ),
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
        '/exercise-groups/delete/${widget.exerciseGroupUuid}',
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группа упражнений'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Удалить группу',
            onPressed: _deleteGroup,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : group == null
          ? const Center(child: Text('Ошибка загрузки'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group!['caption'] ?? 'Без названия',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group!['description'] ?? 'Без описания',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text('Порядок: ${group!['order'] ?? '-'}'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Упражнения:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AdminExerciseCreateScreen(
                                exerciseGroupUuid: widget.exerciseGroupUuid,
                              ),
                            ),
                          );
                          if (result == true) _fetchGroup();
                        },
                        tooltip: 'Добавить упражнение',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: isLoadingExercises
                        ? const Center(child: CircularProgressIndicator())
                        : exercises.isEmpty
                        ? const Center(child: Text('Нет упражнений'))
                        : ListView.builder(
                            itemCount: exercises.length,
                            itemBuilder: (context, index) {
                              final exercise = exercises[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdminExerciseEditScreen(
                                              exerciseUuid: exercise['uuid'],
                                            ),
                                      ),
                                    );
                                  },
                                  title: Text(exercise['caption'] ?? ''),
                                  subtitle: Text(exercise['description'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteExercise(exercise['uuid']),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
