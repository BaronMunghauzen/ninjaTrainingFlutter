import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import 'user_training_create_screen.dart';
import 'user_training_detail_screen.dart';
import 'user_training_edit_screen.dart';

class UserTrainingListScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const UserTrainingListScreen({super.key, this.onDataChanged});

  @override
  State<UserTrainingListScreen> createState() => _UserTrainingListScreenState();
}

class _UserTrainingListScreenState extends State<UserTrainingListScreen> {
  List<Training> userTrainings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserTrainings();
  }

  Future<void> _loadUserTrainings() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final trainings = await UserTrainingService.getUserTrainings(
        userUuid,
        actual: false,
      );
      setState(() {
        userTrainings = trainings;
        isLoading = false;
      });

      // Вызываем callback для обновления данных на родительской странице
      widget.onDataChanged?.call();
    } catch (e) {
      print('Error loading user trainings: $e');
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
          : userTrainings.isEmpty
          ? const Center(
              child: Text(
                'У вас пока нет тренировок',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userTrainings.length,
              itemBuilder: (context, index) {
                final training = userTrainings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      training.caption,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          training.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Группа мышц: ${training.muscleGroup}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: training.actual
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: training.actual
                                      ? Colors.green
                                      : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                training.actual ? 'Активна' : 'Архив',
                                style: TextStyle(
                                  color: training.actual
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserTrainingEditScreen(training: training),
                              ),
                            );
                            if (result == true) {
                              _loadUserTrainings();
                            }
                          },
                        ),
                        if (training.actual)
                          IconButton(
                            icon: const Icon(Icons.archive),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Архивирование тренировки'),
                                  content: const Text(
                                    'Вы уверены, что хотите архивировать эту тренировку?',
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
                                      child: const Text('Архивировать'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                final success =
                                    await UserTrainingService.archiveTraining(
                                      training.uuid,
                                    );
                                if (success) {
                                  _loadUserTrainings();
                                }
                              }
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.unarchive),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Восстановление тренировки',
                                  ),
                                  content: const Text(
                                    'Вы уверены, что хотите восстановить эту тренировку из архива?',
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
                                      child: const Text('Восстановить'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                final success =
                                    await UserTrainingService.restoreTraining(
                                      training.uuid,
                                    );
                                if (success) {
                                  _loadUserTrainings();
                                }
                              }
                            },
                          ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserTrainingDetailScreen(
                            training: training,
                            onDataChanged: widget.onDataChanged,
                          ),
                        ),
                      );
                      // Обновляем данные после возврата
                      _loadUserTrainings();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UserTrainingCreateScreen(),
            ),
          );
          if (result == true) {
            _loadUserTrainings();
          }
        },
        backgroundColor: AppColors.buttonPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
