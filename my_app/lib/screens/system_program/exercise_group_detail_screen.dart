import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class ExerciseGroupDetailScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  final Map<String, dynamic>? exerciseGroupData;

  const ExerciseGroupDetailScreen({
    Key? key,
    required this.exerciseGroupUuid,
    this.exerciseGroupData,
  }) : super(key: key);

  @override
  State<ExerciseGroupDetailScreen> createState() =>
      _ExerciseGroupDetailScreenState();
}

class _ExerciseGroupDetailScreenState extends State<ExerciseGroupDetailScreen> {
  Map<String, dynamic>? exerciseGroupData;
  List<dynamic> exercises = [];
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
    try {
      final queryParams = {'exercise_group_uuid': widget.exerciseGroupUuid};
      final response = await ApiService.get(
        '/exercises/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          setState(() {
            exercises = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      print('Error fetching exercises: $e');
    }
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
        '/exercise-groups/${widget.exerciseGroupUuid}',
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
            const Text(
              'Упражнения:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            title: Text(exercise['caption'] ?? ''),
                            subtitle: Text(exercise['description'] ?? ''),
                            trailing: Column(
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
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
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
