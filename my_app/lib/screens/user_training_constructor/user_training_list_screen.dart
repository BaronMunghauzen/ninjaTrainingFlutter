import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/training_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import 'user_training_create_screen.dart';
import 'user_training_detail_screen.dart';
import 'user_training_edit_screen.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

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
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка загрузки тренировок: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  Future<void> _archiveTraining(Training training) async {
    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Архивирование тренировки',
      children: [
        Text(
          'Вы уверены, что хотите архивировать эту тренировку?',
          style: NinjaText.body,
        ),
        const SizedBox(height: 8),
        Text(
          'После архивирования тренировка не будет отображаться на главной странице.',
          style: NinjaText.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(false),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Архивировать',
                onPressed: () => Navigator.of(context).pop(true),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
              ),
            ),
          ],
        ),
      ],
    );

    if (confirmed == true) {
      try {
        final success = await UserTrainingService.archiveTraining(
          training.uuid,
        );
        if (success) {
          _loadUserTrainings();
          if (mounted) {
            MetalMessage.show(
              context: context,
              message: 'Тренировка успешно архивирована',
              type: MetalMessageType.success,
            );
          }
        } else {
          if (mounted) {
            MetalMessage.show(
              context: context,
              message: 'Ошибка архивирования тренировки',
              type: MetalMessageType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка архивирования тренировки: $e',
            type: MetalMessageType.error,
          );
        }
      }
    }
  }

  Future<void> _restoreTraining(Training training) async {
    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Восстановление тренировки',
      children: [
        Text(
          'Вы уверены, что хотите восстановить эту тренировку из архива?',
          style: NinjaText.body,
        ),
        const SizedBox(height: 8),
        Text(
          'После восстановления тренировка станет видна на главной странице.',
          style: NinjaText.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: NinjaSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MetalButton(
                label: 'Отмена',
                onPressed: () => Navigator.of(context).pop(false),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.first,
              ),
            ),
            Expanded(
              child: MetalButton(
                label: 'Восстановить',
                onPressed: () => Navigator.of(context).pop(true),
                height: 56,
                fontSize: 16,
                position: MetalButtonPosition.last,
              ),
            ),
          ],
        ),
      ],
    );

    if (confirmed == true) {
      try {
        final success = await UserTrainingService.restoreTraining(
          training.uuid,
        );
        if (success) {
          _loadUserTrainings();
          if (mounted) {
            MetalMessage.show(
              context: context,
              message: 'Тренировка успешно восстановлена',
              type: MetalMessageType.success,
            );
          }
        } else {
          if (mounted) {
            MetalMessage.show(
              context: context,
              message: 'Ошибка восстановления тренировки',
              type: MetalMessageType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка восстановления тренировки: $e',
            type: MetalMessageType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              )
            : userTrainings.isEmpty
            ? Center(
                child: Text(
                  'У вас пока нет тренировок',
                  style: NinjaText.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: userTrainings.length,
                itemBuilder: (context, index) {
                  final training = userTrainings[index];
                  final isFirst = index == 0;
                  final isLast = index == userTrainings.length - 1;

                  return MetalListItem(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AuthImageWidget(
                        imageUuid: training.imageUuid,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      training.caption,
                      style: NinjaText.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(training.muscleGroup, style: NinjaText.caption),
                        const SizedBox(height: 4),
                        Text(
                          training.actual ? 'Активна' : 'Архив',
                          style: NinjaText.caption,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: AppColors.textSecondary,
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
                            color: AppColors.textSecondary,
                            onPressed: () => _archiveTraining(training),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.unarchive),
                            color: AppColors.textSecondary,
                            onPressed: () => _restoreTraining(training),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserTrainingDetailScreen(
                            training: training,
                            onDataChanged: () {
                              // Обновляем список тренировок
                              _loadUserTrainings();
                              // Обновляем родительскую страницу
                              widget.onDataChanged?.call();
                            },
                          ),
                        ),
                      );
                      // Обновляем данные после возврата
                      _loadUserTrainings();
                    },
                    isFirst: isFirst,
                    isLast: isLast,
                    removeSpacing: true,
                  );
                },
              ),
        // Кнопка добавления в правом нижнем углу
        Positioned(
          right: 24,
          bottom: 24,
          child: SizedBox(
            width: 56,
            height: 56,
            child: MetalButton(
              label: '',
              icon: Icons.add,
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
              height: 56,
            ),
          ),
        ),
      ],
    );
  }
}
