import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../system_training/system_training_detail_screen.dart';
import '../system_training/active_system_training_screen.dart';

class SystemTrainingListWidget extends StatefulWidget {
  const SystemTrainingListWidget({Key? key}) : super(key: key);

  @override
  State<SystemTrainingListWidget> createState() =>
      _SystemTrainingListWidgetState();
}

class _SystemTrainingListWidgetState extends State<SystemTrainingListWidget> {
  List<Map<String, dynamic>> trainings = [];
  bool isLoading = true;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _loadTrainings();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('user_token');
  }

  Future<void> _loadTrainings() async {
    try {
      final response = await ApiService.get(
        '/trainings/',
        queryParams: {'training_type': 'system_training', 'actual': 'true'},
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          setState(() {
            trainings = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
          return;
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (trainings.isEmpty) {
      return const Center(child: Text('Тренировки не найдены'));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: trainings.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final training = trainings[index];
        return GestureDetector(
          onTap: () async {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            final userUuid = authProvider.userUuid;
            if (userUuid == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка: не найден userUuid')),
              );
              return;
            }
            final response = await ApiService.get(
              '/user_trainings/',
              queryParams: {
                'user_uuid': userUuid,
                'status': 'active',
                'training_uuid': training['uuid'],
              },
            );
            if (response.statusCode == 200) {
              final data = ApiService.decodeJson(response.body);
              final trainingsList = (data is Map && data['data'] is List)
                  ? data['data']
                  : null;
              if (trainingsList != null && trainingsList.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveSystemTrainingScreen(
                      userTraining: trainingsList[0],
                    ),
                  ),
                );
                return;
              }
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    SystemTrainingDetailScreen(training: training),
              ),
            );
          },
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Картинка тренировки
                if (training['image_uuid'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiService.baseUrl}/files/file/${training['image_uuid']}',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      headers: _authToken != null
                          ? {'Cookie': 'users_access_token=$_authToken'}
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
                      key: ValueKey(training['image_uuid']),
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
                    child: Text(
                      training['caption'] ?? '',
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
