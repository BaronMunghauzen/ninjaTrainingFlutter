import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class TrainingDetailScreen extends StatefulWidget {
  final String trainingUuid;
  final Map<String, dynamic>? trainingData;

  const TrainingDetailScreen({
    Key? key,
    required this.trainingUuid,
    this.trainingData,
  }) : super(key: key);

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  Map<String, dynamic>? trainingData;
  List<dynamic> exerciseGroups = [];
  bool isLoading = true;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.trainingData != null) {
      trainingData = widget.trainingData;
      _loadExerciseGroups();
    } else {
      _loadTrainingData();
    }
  }

  Future<void> _loadTrainingData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/trainings/${widget.trainingUuid}',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          trainingData = data;
          isLoading = false;
        });
        _loadExerciseGroups();
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

  Future<void> _loadExerciseGroups() async {
    try {
      final queryParams = {'training_uuid': widget.trainingUuid};
      final response = await ApiService.get(
        '/exercise-groups/',
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          setState(() {
            exerciseGroups = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      print('Error fetching exercise groups: $e');
    }
  }

  Future<void> _deleteTraining() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку?'),
        content: const Text('Вы уверены, что хотите удалить эту тренировку?'),
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
        '/trainings/${widget.trainingUuid}',
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

    if (trainingData == null) {
      return const Scaffold(
        body: Center(child: Text('Не удалось загрузить тренировку')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали тренировки'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: isDeleting
                ? const CircularProgressIndicator()
                : const Icon(Icons.delete),
            onPressed: isDeleting ? null : _deleteTraining,
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
              trainingData!['caption'] ?? 'Без названия',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              trainingData!['description'] ?? 'Без описания',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Сложность',
              '${trainingData!['difficulty_level'] ?? '-'}',
            ),
            _buildInfoRow(
              'Продолжительность',
              '${trainingData!['duration'] ?? '-'} мин',
            ),
            _buildInfoRow('Порядок', '${trainingData!['order'] ?? '-'}'),
            _buildInfoRow('Группа мышц', trainingData!['muscle_group'] ?? '-'),
            _buildInfoRow('Этап', '${trainingData!['stage'] ?? '-'}'),
            const SizedBox(height: 24),
            const Text(
              'Группы упражнений:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: exerciseGroups.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      itemCount: exerciseGroups.length,
                      itemBuilder: (context, index) {
                        final group = exerciseGroups[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(group['caption'] ?? ''),
                            subtitle: Text(group['description'] ?? ''),
                            trailing: Text(
                              'Порядок: ${group['order'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Удалить тренировку',
              onPressed: isDeleting ? null : _deleteTraining,
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
