import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/user_training_service.dart';
import '../user_training_constructor/user_training_constructor_screen.dart';
import '../system_training/active_system_training_screen.dart';
import '../system_training/system_training_detail_screen.dart';

class MyTrainingListWidget extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const MyTrainingListWidget({Key? key, this.onDataChanged}) : super(key: key);

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

  Future<ImageProvider?> _loadTrainingImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      // Используем метод кэширования ApiService
      return await ApiService.getImageProvider(imageUuid);
    } catch (e) {
      print('[MyTrainingListWidget] Ошибка загрузки изображения: $e');
      return null;
    }
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

      final trainings = await UserTrainingService.getUserTrainings(userUuid);
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
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserTrainingConstructorScreen(
                      onDataChanged: widget.onDataChanged,
                    ),
                  ),
                );
                // Обновляем данные после возврата
                _loadUserTrainings();
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
                      onTap: () async {
                        // Проверяем активна ли тренировка
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final userUuid = authProvider.userUuid;
                        if (userUuid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ошибка: не найден userUuid'),
                            ),
                          );
                          return;
                        }

                        final response = await ApiService.get(
                          '/user_trainings/',
                          queryParams: {
                            'user_uuid': userUuid,
                            'status': 'active',
                            'training_uuid': training.uuid,
                          },
                        );

                        if (response.statusCode == 200) {
                          final data = ApiService.decodeJson(response.body);
                          final trainingsList =
                              (data is Map && data['data'] is List)
                              ? data['data']
                              : null;
                          if (trainingsList != null &&
                              trainingsList.isNotEmpty) {
                            // Если есть активная тренировка - переходим на экран активной тренировки
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ActiveSystemTrainingScreen(
                                      userTraining: trainingsList[0],
                                    ),
                              ),
                            );
                            return;
                          }
                        }

                        // Если нет активной тренировки — открываем карточку тренировки
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SystemTrainingDetailScreen(
                              training: _trainingToMap(training),
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
                        child: FutureBuilder<ImageProvider?>(
                          future: _loadTrainingImage(training.imageUuid),
                          builder: (context, snapshot) {
                            final image = snapshot.data;
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // Картинка тренировки
                                if (image != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image(
                                      image: image,
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  Container(
                                    color: AppColors.surface,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    color: AppColors.surface,
                                    child: const Icon(
                                      Icons.fitness_center,
                                      size: 60,
                                      color: AppColors.textSecondary,
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
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<String, dynamic> _trainingToMap(Training training) {
    return {
      'uuid': training.uuid,
      'caption': training.caption,
      'muscle_group': training.muscleGroup,
      'description': training.description,
      'image_uuid': training.imageUuid,
      'difficulty_level': training.difficultyLevel,
      'duration': training.duration,
      'training_type': training.trainingType,
    };
  }
}
