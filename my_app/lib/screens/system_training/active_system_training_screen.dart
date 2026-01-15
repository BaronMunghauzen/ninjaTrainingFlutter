import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../services/training_service.dart';
import '../../services/api_service.dart';
import 'system_exercise_group_screen.dart';
import '../../widgets/subscription_error_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/exercise_group_list_item.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

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

  @override
  void initState() {
    super.initState();
    print('🚀 initState() вызван');
    print('🚀 userTraining данные: ${widget.userTraining}');
    print('🚀 training данные: ${widget.userTraining['training']}');
    print('🚀 training UUID: ${widget.userTraining['training']?['uuid']}');

    // Проверяем подписку при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscription();
    });

    print('🚀 Вызываем _loadExerciseGroups...');
    _loadExerciseGroups();
    print('🚀 initState() завершен');
  }

  void _checkSubscription() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile != null && userProfile.subscriptionStatus != 'active') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SubscriptionErrorDialog(
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
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

  Future<ImageProvider?> _loadExerciseGroupImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      return await ApiService.getImageProvider(imageUuid);
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
  }

  String? _getImageUuid(Map<String, dynamic> group) {
    final imageUuid = group['image_uuid'];
    if (imageUuid is String && imageUuid.isNotEmpty) return imageUuid;
    return null;
  }

  Future<void> _skipTraining() async {
    try {
      final response = await TrainingService.skipUserTrainingWithResponse(
        widget.userTraining['uuid'],
      );
      if (response['success'] == true) {
        MetalMessage.show(
          context: context,
          message: 'Тренировка успешно пропущена',
          type: MetalMessageType.success,
          title: 'Тренировка пропущена',
          description: 'Тренировка успешно пропущена',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        MetalMessage.show(
          context: context,
          message: 'Не удалось пропустить тренировку',
          type: MetalMessageType.error,
          title: 'Ошибка',
          description: 'Ошибка пропуска тренировки',
        );
      }
    } catch (e) {
      MetalMessage.show(
        context: context,
        message: e.toString(),
        type: MetalMessageType.error,
        title: 'Ошибка',
        description: 'Произошла ошибка при пропуске тренировки',
      );
    }
  }

  Future<void> _passTraining() async {
    try {
      final response = await TrainingService.passUserTrainingWithResponse(
        widget.userTraining['uuid'],
      );
      if (response['success'] == true) {
        MetalMessage.show(
          context: context,
          message: 'Тренировка успешно завершена',
          type: MetalMessageType.success,
          title: 'Тренировка завершена',
          description: 'Тренировка успешно завершена',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        MetalMessage.show(
          context: context,
          message: 'Не удалось завершить тренировку',
          type: MetalMessageType.error,
          title: 'Ошибка',
          description: 'Ошибка завершения тренировки',
        );
      }
    } catch (e) {
      MetalMessage.show(
        context: context,
        message: e.toString(),
        type: MetalMessageType.error,
        title: 'Ошибка',
        description: 'Произошла ошибка при завершении тренировки',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.userTraining['training'] ?? {};
    final isRestDay = widget.userTraining['is_rest_day'] ?? false;
    final status =
        widget.userTraining['status']?.toString().toLowerCase() ?? '';
    final isActiveTraining = status == 'active';

    print('🏗️ Build вызван: isRestDay=$isRestDay, status=$status');
    print('🏗️ Загружаются группы: $_isLoadingGroups');
    print('🏗️ Количество групп: ${_exerciseGroups.length}');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхняя панель с кнопкой назад и названием тренировки
                Row(
                  children: [
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text(
                        training['caption'] ?? 'Активная тренировка',
                        style: NinjaText.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    // Пустое место для симметрии
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                if (isRestDay)
                  _buildRestDayContent()
                else ...[
                  // Группы упражнений
                  Expanded(
                    child: _isLoadingGroups
                        ? const Center(child: CircularProgressIndicator())
                        : _exerciseGroups.isEmpty
                        ? const Center(
                            child: Text(
                              'Нет групп упражнений',
                              style: NinjaText.body,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _exerciseGroups.length,
                            itemBuilder: (context, index) {
                              final group = _exerciseGroups[index];
                              final isFirst = index == 0;
                              final isLast =
                                  index == _exerciseGroups.length - 1;
                              return ExerciseGroupListItem(
                                group: group,
                                isActive: isActiveTraining,
                                isFirst: isFirst,
                                isLast: isLast,
                                onTap: () {
                                  if (!isActiveTraining) {
                                    MetalMessage.show(
                                      context: context,
                                      message:
                                          'Выполните тренировку в назначенное время.',
                                      type: MetalMessageType.warning,
                                      title: 'Тренировка не активна',
                                      description:
                                          'Выполните тренировку в назначенное время.',
                                    );
                                    return;
                                  }
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
                                loadImage: _loadExerciseGroupImage,
                                getImageUuid: _getImageUuid,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Кнопки управления тренировкой или статус
                  if (status == 'active')
                    Row(
                      children: [
                        Expanded(
                          child: MetalButton(
                            label: 'Пропустить',
                            onPressed: _skipTraining,
                            height: 56,
                            fontSize: 16,
                            position: MetalButtonPosition.first,
                            topColor: Colors.red,
                          ),
                        ),
                        Expanded(
                          child: MetalButton(
                            label: 'Завершить',
                            onPressed: _passTraining,
                            height: 56,
                            fontSize: 16,
                            position: MetalButtonPosition.last,
                            topColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  // Сообщения о статусе отображаются через MetalMessage.show в методах _passTraining и _skipTraining
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
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
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: MetalButton(
            label: 'Завершить',
            onPressed: _passTraining,
            height: 56,
            fontSize: 16,
            topColor: Colors.green,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
