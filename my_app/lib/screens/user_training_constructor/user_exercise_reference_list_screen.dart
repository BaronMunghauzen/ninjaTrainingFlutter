import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import 'user_exercise_reference_create_screen.dart';
import 'user_exercise_reference_detail_screen.dart';

class UserExerciseReferenceListScreen extends StatefulWidget {
  const UserExerciseReferenceListScreen({Key? key}) : super(key: key);

  @override
  State<UserExerciseReferenceListScreen> createState() =>
      _UserExerciseReferenceListScreenState();
}

class _UserExerciseReferenceListScreenState
    extends State<UserExerciseReferenceListScreen> {
  List<ExerciseReference> userExercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserExercises();
  }

  Future<void> _loadUserExercises() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final exercises = await UserTrainingService.getUserExerciseReferences(
        userUuid,
      );
      setState(() {
        userExercises = exercises;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user exercises: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            )
          : userExercises.isEmpty
          ? const Center(
              child: Text(
                'У вас пока нет упражнений',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userExercises.length,
              itemBuilder: (context, index) {
                final exercise = userExercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.fitness_center,
                      color: AppColors.textPrimary,
                    ),
                    title: Text(
                      exercise.caption,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Группа мышц: ${exercise.muscleGroup}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // TODO: Реализовать редактирование
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Удаление упражнения'),
                                content: const Text(
                                  'Вы уверены, что хотите удалить это упражнение?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
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

                            if (confirmed == true) {
                              final success =
                                  await UserTrainingService.deleteExerciseReference(
                                    exercise.uuid,
                                  );
                              if (success) {
                                _loadUserExercises();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Упражнение удалено'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              UserExerciseReferenceDetailScreen(
                                exercise: exercise,
                              ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UserExerciseReferenceCreateScreen(),
            ),
          );
          if (result == true) {
            _loadUserExercises();
          }
        },
        backgroundColor: AppColors.buttonPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
