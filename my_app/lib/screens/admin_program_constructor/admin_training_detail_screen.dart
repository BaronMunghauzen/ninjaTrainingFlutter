import 'package:flutter/material.dart';
import 'dart:ui';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_button.dart';
import 'admin_training_edit_screen.dart';
import '../../services/api_service.dart';
import 'admin_exercise_group_create_screen.dart';
import 'admin_exercise_group_detail_screen.dart';

class AdminTrainingDetailScreen extends StatefulWidget {
  final String trainingUuid;
  final Map<String, dynamic>? trainingData;

  const AdminTrainingDetailScreen({
    Key? key,
    required this.trainingUuid,
    this.trainingData,
  }) : super(key: key);

  @override
  State<AdminTrainingDetailScreen> createState() =>
      _AdminTrainingDetailScreenState();
}

class _AdminTrainingDetailScreenState extends State<AdminTrainingDetailScreen> {
  Map<String, dynamic>? trainingData;
  bool isLoading = true;
  bool isDeleting = false;
  List<Map<String, dynamic>> exerciseGroups = [];
  bool isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    if (widget.trainingData != null) {
      trainingData = widget.trainingData;
      isLoading = false;
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
          SnackBar(content: Text('Ошибка загрузки:  {response.statusCode}')),
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
    if (trainingData == null) return;
    setState(() {
      isLoadingGroups = true;
    });
    try {
      final resp = await ApiService.get(
        '/exercise-groups/',
        queryParams: {'training_uuid': trainingData!['uuid']},
      );
      if (resp.statusCode == 200) {
        final data = ApiService.decodeJson(resp.body);
        if (data is List) {
          setState(() {
            exerciseGroups = List<Map<String, dynamic>>.from(data);
            isLoadingGroups = false;
          });
        }
      } else {
        setState(() {
          isLoadingGroups = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingGroups = false;
      });
    }
  }

  Future<ImageProvider?> _loadExerciseGroupImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      final response = await ApiService.get('/files/file/$imageUuid');
      if (response.statusCode == 200) {
        return MemoryImage(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
  }

  String? _getImageUuid(Map<String, dynamic> group) {
    final imageUuid = group['image_uuid'];
    if (imageUuid is String && imageUuid.isNotEmpty) return imageUuid;
    return null;
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
        '/trainings/delete/${widget.trainingUuid}',
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

  void _editTraining() {
    if (trainingData == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => TrainingEditScreen(
              trainingUuid: widget.trainingUuid,
              initialData: trainingData!,
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadTrainingData();
          }
        });
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
            icon: const Icon(Icons.edit),
            onPressed: _editTraining,
            tooltip: 'Редактировать',
          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Группы упражнений:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                  tooltip: 'Добавить группу',
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExerciseGroupCreateScreen(
                          trainingUuid: trainingData!['uuid'],
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadExerciseGroups();
                    }
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
                        leading: FutureBuilder<ImageProvider?>(
                          future: _loadExerciseGroupImage(_getImageUuid(group)),
                          builder: (context, snapshot) {
                            final image = snapshot.data;
                            return Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 1,
                                ),
                                image: image != null
                                    ? DecorationImage(
                                        image: image,
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.5),
                                          BlendMode.darken,
                                        ),
                                      )
                                    : null,
                              ),
                              child: image == null
                                  ? const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 24,
                                    )
                                  : null,
                            );
                          },
                        ),
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
            const Spacer(),
            CustomButton(text: 'Редактировать', onPressed: _editTraining),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Удалить',
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
