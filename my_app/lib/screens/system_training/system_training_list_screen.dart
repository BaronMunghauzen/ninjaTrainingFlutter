import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../services/user_training_service.dart';
import 'system_training_detail_screen.dart';

class SystemTrainingListScreen extends StatefulWidget {
  final String trainingUuid;

  const SystemTrainingListScreen({Key? key, required this.trainingUuid})
    : super(key: key);

  @override
  State<SystemTrainingListScreen> createState() =>
      _SystemTrainingListScreenState();
}

class _SystemTrainingListScreenState extends State<SystemTrainingListScreen> {
  Training? training;
  List<ExerciseGroup> exerciseGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainingDetails();
  }

  Future<void> _loadTrainingDetails() async {
    try {
      // Получаем группы упражнений для тренировки
      final groups = await UserTrainingService.getExerciseGroupsForTraining(
        widget.trainingUuid,
      );
      setState(() {
        exerciseGroups = groups;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading training details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Детали тренировки',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            )
          : exerciseGroups.isEmpty
          ? const Center(
              child: Text(
                'В этой тренировке пока нет упражнений',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exerciseGroups.length,
              itemBuilder: (context, index) {
                final group = exerciseGroups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.fitness_center,
                      color: AppColors.textPrimary,
                    ),
                    title: Text(
                      group.caption,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Упражнений: ${group.exercises.length}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SystemTrainingDetailScreen(
                            training: {
                              'uuid': widget.trainingUuid,
                              'caption': group.caption,
                              'description': group.description,
                              'difficulty_level': 1,
                              'duration': 30,
                              'muscle_group': group.muscleGroup,
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
