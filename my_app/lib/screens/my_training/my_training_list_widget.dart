import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../user_training_constructor/user_training_constructor_screen.dart';
import '../system_training/system_training_list_screen.dart';

class MyTrainingListWidget extends StatefulWidget {
  const MyTrainingListWidget({Key? key}) : super(key: key);

  @override
  State<MyTrainingListWidget> createState() => _MyTrainingListWidgetState();
}

class _MyTrainingListWidgetState extends State<MyTrainingListWidget> {
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
        actual: true,
      );
      setState(() {
        userTrainings = trainings;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user trainings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок "Мои программы" с кнопкой "+"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Мои тренировки',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Добавить тренировку',
              color: AppColors.textPrimary,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UserTrainingConstructorScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Горизонтальный список программ
        SizedBox(
          height: 140,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textPrimary,
                  ),
                )
              : userTrainings.isEmpty
              ? const Center(
                  child: Text(
                    'У вас пока нет программ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: userTrainings.length,
                  itemBuilder: (context, index) {
                    final training = userTrainings[index];
                    return GestureDetector(
                      onTap: () {
                        // Переход на экран тренировок из папки system_training
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SystemTrainingListScreen(
                              trainingUuid: training.uuid,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  color: AppColors.textPrimary,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  training.caption,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  training.muscleGroup,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
