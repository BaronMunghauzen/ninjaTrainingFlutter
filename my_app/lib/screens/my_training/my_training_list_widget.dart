import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
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
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _loadUserTrainings();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('user_token');
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
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Картинка тренировки
                            if (training.imageUuid != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  '${ApiService.baseUrl}/files/file/${training.imageUuid}',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  headers: _authToken != null
                                      ? {
                                          'Cookie':
                                              'users_access_token=$_authToken',
                                        }
                                      : {},
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.surface,
                                      child: const Icon(
                                        Icons.fitness_center,
                                        size: 60,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                  key: ValueKey(training.imageUuid),
                                ),
                              ),
                            // Полупрозрачный оверлей для лучшей читаемости текста
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.4, 1.0],
                                ),
                              ),
                            ),
                            // Текст поверх картинки
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      training.caption,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
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
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
