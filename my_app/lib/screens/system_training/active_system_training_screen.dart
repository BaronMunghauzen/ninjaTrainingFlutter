import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/training_service.dart';
import '../../services/api_service.dart';
import 'system_exercise_group_screen.dart';

class ActiveSystemTrainingScreen extends StatefulWidget {
  final Map<String, dynamic> userTraining;
  const ActiveSystemTrainingScreen({Key? key, required this.userTraining})
    : super(key: key);

  @override
  State<ActiveSystemTrainingScreen> createState() =>
      _ActiveSystemTrainingScreenState();
}

class _ActiveSystemTrainingScreenState
    extends State<ActiveSystemTrainingScreen> {
  List<Map<String, dynamic>> _exerciseGroups = [];
  bool _isLoadingGroups = false;
  bool _showCongrats = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    print('🚀 initState() вызван');
    print('🚀 userTraining данные: ${widget.userTraining}');
    print('🚀 training данные: ${widget.userTraining['training']}');
    print('🚀 training UUID: ${widget.userTraining['training']?['uuid']}');
    _loadAuthToken();
    print('🚀 Вызываем _loadExerciseGroups...');
    _loadExerciseGroups();
    print('🚀 initState() завершен');
  }

  Future<void> _loadAuthToken() async {
    print('🔐 Начинаем загрузку токена...');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _authToken = prefs.getString('user_token');
    });
    print('🔐 Токен загружен: ${_authToken != null ? "есть" : "нет"}');
  }

  Future<void> _loadExerciseGroups() async {
    print('🔥 Начинаем загрузку групп упражнений...');
    setState(() {
      _isLoadingGroups = true;
    });
    try {
      final trainingUuid = widget.userTraining['training']['uuid'];
      print('🔥 Training UUID: $trainingUuid');

      // Очищаем кеш для принудительного обновления данных
      print('🗑️ Очищаем кеш групп упражнений...');
      TrainingService.clearExerciseGroupsCache(trainingUuid);

      final groups = await TrainingService.getExerciseGroups(trainingUuid);
      print('🔥 Получено групп упражнений: ${groups.length}');
      print('🔥 Данные групп: $groups');

      setState(() {
        _exerciseGroups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      print('❌ Ошибка при загрузке групп упражнений: $e');
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _skipTraining() async {
    try {
      final response = await TrainingService.skipUserTrainingWithResponse(
        widget.userTraining['uuid'],
      );
      if (response['success'] == true) {
        setState(() {
          _showCongrats = response['next_stage_created'] == true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка пропущена')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка пропуска тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _passTraining() async {
    try {
      final response = await TrainingService.passUserTrainingWithResponse(
        widget.userTraining['uuid'],
      );
      if (response['success'] == true) {
        setState(() {
          _showCongrats = response['next_stage_created'] == true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка завершена')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка завершения тренировки')),
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
    final training = widget.userTraining['training'] ?? {};
    final isRestDay = widget.userTraining['is_rest_day'] ?? false;
    final status =
        widget.userTraining['status']?.toString().toLowerCase() ?? '';

    print('🏗️ Build вызван: isRestDay=$isRestDay, status=$status');
    print('🏗️ Загружаются группы: $_isLoadingGroups');
    print('🏗️ Количество групп: ${_exerciseGroups.length}');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Активная тренировка')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              training['caption'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isRestDay)
              Column(
                children: [
                  Icon(Icons.bedtime, size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 20),
                  const Text(
                    'День отдыха',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Сегодня можно отдохнуть и восстановиться',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _passTraining,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Завершить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              )
            else ...[
              Expanded(
                child: _isLoadingGroups
                    ? const Center(child: CircularProgressIndicator())
                    : _exerciseGroups.isEmpty
                    ? const Center(child: Text('Нет групп упражнений'))
                    : ListView.separated(
                        itemCount: _exerciseGroups.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final group = _exerciseGroups[index];
                          print(
                            '🎨 Отображаем группу $index: ${group['caption']}, image_uuid: ${group['image_uuid']}',
                          );
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SystemExerciseGroupScreen(
                                        exerciseGroupUuid: group['uuid'],
                                        userTraining: widget.userTraining,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Фоновое изображение или цвет
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: group['image_uuid'] != null
                                          ? Image.network(
                                              '${ApiService.baseUrl}/files/file/${group['image_uuid']}',
                                              fit: BoxFit.cover,
                                              headers: _authToken != null
                                                  ? {
                                                      'Cookie':
                                                          'users_access_token=$_authToken',
                                                    }
                                                  : {},
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.fitness_center,
                                                          size: 40,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                              key: ValueKey(
                                                group['image_uuid'],
                                              ),
                                            )
                                          : Container(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.fitness_center,
                                                  size: 40,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  // Градиент для читаемости текста
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
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
                                  ),
                                  // Текст с названием группы
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Text(
                                      group['caption'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              if (status == 'active')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipTraining,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Пропустить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _passTraining,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Завершить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (status == 'passed')
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Тренировка завершена',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (status == 'skipped')
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Тренировка пропущена',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
