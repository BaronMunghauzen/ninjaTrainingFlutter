import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_button.dart';
import 'admin_exercise_group_edit_screen.dart';
import 'admin_exercise_create_screen.dart';
import 'admin_exercise_detail_screen.dart';
import '../../services/api_service.dart';

class AdminExerciseGroupDetailScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  final Map<String, dynamic>? exerciseGroupData;

  const AdminExerciseGroupDetailScreen({
    Key? key,
    required this.exerciseGroupUuid,
    this.exerciseGroupData,
  }) : super(key: key);

  @override
  State<AdminExerciseGroupDetailScreen> createState() =>
      _AdminExerciseGroupDetailScreenState();
}

class _AdminExerciseGroupDetailScreenState
    extends State<AdminExerciseGroupDetailScreen> {
  Map<String, dynamic>? exerciseGroupData;
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseGroupData != null) {
      exerciseGroupData = widget.exerciseGroupData;
      _loadExercises();
    } else {
      _loadExerciseGroupData();
    }
  }

  Future<void> _loadExerciseGroupData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/exercise-groups/${widget.exerciseGroupUuid}',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          exerciseGroupData = data;
          isLoading = false;
        });
        _loadExercises();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _loadExercises() async {
    // Новый способ: получаем uuid из exerciseGroupData['exercises']
    if (exerciseGroupData == null || exerciseGroupData!['exercises'] == null) {
      setState(() {
        exercises = [];
      });
      return;
    }
    final List exUuids = exerciseGroupData!['exercises'];
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
    });
  }

  Future<void> _deleteExerciseGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить группу упражнений?'),
        content: const Text(
          'Вы уверены, что хотите удалить эту группу упражнений?',
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

    if (confirm != true) return;

    setState(() {
      isDeleting = true;
    });

    try {
      final response = await ApiService.delete(
        '/exercise-groups/delete/${widget.exerciseGroupUuid}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        isDeleting = false;
      });
    }
  }

  void _editExerciseGroup() {
    if (exerciseGroupData == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ExerciseGroupEditScreen(
              exerciseGroupUuid: widget.exerciseGroupUuid,
              initialData: exerciseGroupData!,
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadExerciseGroupData();
          }
        });
  }

  void _addExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ExerciseCreateScreen(exerciseGroupUuid: widget.exerciseGroupUuid),
      ),
    );
    // result теперь должен быть uuid нового упражнения (если pop(true) заменить на pop(uuid) в ExerciseCreateScreen)
    if (result is String && result.isNotEmpty) {
      await ApiService.post(
        '/exercise-groups/${widget.exerciseGroupUuid}/add-exercise',
        body: {'exercise_uuid': result},
      );
      await _loadExerciseGroupData();
    } else if (result == true) {
      // fallback: если result == true, старое поведение (на всякий случай)
      await _loadExerciseGroupData();
    }
  }

  void _openExerciseDetail(Map<String, dynamic> exercise) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AdminExerciseDetailScreen(exerciseUuid: exercise['uuid']),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadExercises();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (exerciseGroupData == null) {
      return const Scaffold(
        body: Center(child: Text('Не удалось загрузить группу упражнений')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Группа упражнений'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editExerciseGroup,
            tooltip: 'Редактировать',
          ),
          IconButton(
            icon: isDeleting
                ? const CircularProgressIndicator()
                : const Icon(Icons.delete),
            onPressed: isDeleting ? null : _deleteExerciseGroup,
            tooltip: 'Удалить',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseGroupData!['caption'] ?? 'Без названия',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              exerciseGroupData!['description'] ?? 'Без описания',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Порядок', '${exerciseGroupData!['order'] ?? '-'}'),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Упражнения:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addExercise,
                  tooltip: 'Добавить упражнение',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: exercises.isEmpty
                  ? const Center(child: Text('Нет упражнений'))
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () => _openExerciseDetail(exercise),
                            title: Text(exercise['caption'] ?? ''),
                            subtitle: Text(exercise['description'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${exercise['sets'] ?? 0} x ${exercise['reps'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Порядок: ${exercise['order'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Удалить упражнение из группы',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Удалить упражнение?',
                                        ),
                                        content: const Text(
                                          'Вы уверены, что хотите удалить это упражнение из группы?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('Отмена'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ApiService.post(
                                        '/exercise-groups/${widget.exerciseGroupUuid}/remove-exercise',
                                        body: {
                                          'exercise_uuid': exercise['uuid'],
                                        },
                                      );
                                      await _loadExerciseGroupData();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            CustomButton(text: 'Добавить упражнение', onPressed: _addExercise),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Удалить группу',
              onPressed: isDeleting ? null : _deleteExerciseGroup,
              isLoading: isDeleting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
