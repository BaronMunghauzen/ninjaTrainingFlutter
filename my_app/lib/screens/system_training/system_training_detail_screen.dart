import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'active_system_training_screen.dart';

class SystemTrainingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> training;
  const SystemTrainingDetailScreen({Key? key, required this.training})
    : super(key: key);

  @override
  State<SystemTrainingDetailScreen> createState() =>
      _SystemTrainingDetailScreenState();
}

class _SystemTrainingDetailScreenState
    extends State<SystemTrainingDetailScreen> {
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('user_token');
    });
  }

  Future<void> _startTraining(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: не найден userUuid')),
      );
      return;
    }
    final now = DateTime.now();
    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final body = {
      'training_uuid': widget.training['uuid'],
      'user_uuid': userUuid,
      'training_date': dateStr,
      'status': 'ACTIVE',
      'is_rest_day': false,
    };
    try {
      final response = await ApiService.post(
        '/user_trainings/add/',
        body: body,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = ApiService.decodeJson(response.body);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ActiveSystemTrainingScreen(userTraining: data),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка тренировки'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фоновое изображение с сильным затемнением
          if (widget.training['image_uuid'] != null)
            Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  '${ApiService.baseUrl}/files/file/${widget.training['image_uuid']}',
                  fit: BoxFit.cover,
                  headers: _authToken != null
                      ? {'Cookie': 'users_access_token=$_authToken'}
                      : {},
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 100,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                  key: ValueKey(widget.training['image_uuid']),
                ),
                // Темная накладка для очень сильного затемнения
                Container(color: Colors.black.withOpacity(0.7)),
              ],
            )
          else
            Container(
              color: AppColors.background,
              child: const Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 100,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          // Темный оверлей для читаемости
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Контент
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.training['caption'] ?? '',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (widget.training['description'] != null &&
                          widget.training['description'].toString().isNotEmpty)
                        Text(
                          widget.training['description'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 24),
                      // Информационные блоки с фоном
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.fitness_center,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Сложность: ${widget.training['difficulty_level'] ?? '-'}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Длительность: ${widget.training['duration'] ?? '-'} мин',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.accessibility_new,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Группа мышц: ${widget.training['muscle_group'] ?? '-'}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startTraining(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                          ),
                          child: const Text(
                            'Начать',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
