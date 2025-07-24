import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_button.dart';
import 'admin_exercise_edit_screen.dart';
import '../../services/api_service.dart';

class AdminExerciseDetailScreen extends StatefulWidget {
  final String exerciseUuid;
  final Map<String, dynamic>? exerciseData;

  const AdminExerciseDetailScreen({
    Key? key,
    required this.exerciseUuid,
    this.exerciseData,
  }) : super(key: key);

  @override
  State<AdminExerciseDetailScreen> createState() =>
      _AdminExerciseDetailScreenState();
}

class _AdminExerciseDetailScreenState extends State<AdminExerciseDetailScreen> {
  Map<String, dynamic>? exerciseData;
  bool isLoading = true;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseData != null) {
      exerciseData = widget.exerciseData;
      isLoading = false;
    } else {
      _loadExerciseData();
    }
  }

  Future<void> _loadExerciseData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/exercises/${widget.exerciseUuid}',
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          exerciseData = data;
          isLoading = false;
        });
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

  Future<void> _deleteExercise() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: const Text('Вы уверены, что хотите удалить это упражнение?'),
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
        '/exercises/${widget.exerciseUuid}',
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

  void _editExercise() {
    if (exerciseData == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AdminExerciseEditScreen(
              exerciseUuid: widget.exerciseUuid,
              initialData: exerciseData!,
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadExerciseData();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (exerciseData == null) {
      return const Scaffold(
        body: Center(child: Text('Не удалось загрузить упражнение')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали упражнения'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editExercise,
            tooltip: 'Редактировать',
          ),
          IconButton(
            icon: isDeleting
                ? const CircularProgressIndicator()
                : const Icon(Icons.delete),
            onPressed: isDeleting ? null : _deleteExercise,
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
              exerciseData!['caption'] ?? 'Без названия',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              exerciseData!['description'] ?? 'Без описания',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Сложность',
              '${exerciseData!['difficulty_level'] ?? '-'}',
            ),
            _buildInfoRow(
              'Продолжительность',
              '${exerciseData!['duration'] ?? '-'} мин',
            ),
            _buildInfoRow('Порядок', '${exerciseData!['order'] ?? '-'}'),
            _buildInfoRow('Группа мышц', exerciseData!['muscle_group'] ?? '-'),
            _buildInfoRow('Повторения', '${exerciseData!['reps'] ?? '-'}'),
            _buildInfoRow('Подходы', '${exerciseData!['sets'] ?? '-'}'),
            const Spacer(),
            CustomButton(text: 'Редактировать', onPressed: _editExercise),
            const SizedBox(height: 8),
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
