import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

class UserTrainingCreateScreen extends StatefulWidget {
  const UserTrainingCreateScreen({Key? key}) : super(key: key);

  @override
  State<UserTrainingCreateScreen> createState() =>
      _UserTrainingCreateScreenState();
}

class _UserTrainingCreateScreenState extends State<UserTrainingCreateScreen> {
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  Future<void> _createTraining() async {
    // Валидация - обязательное только название
    if (_captionController.text.trim().isEmpty) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, введите название тренировки',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка: не найден userUuid',
            type: MetalMessageType.error,
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await UserTrainingService.createUserTraining(
        userUuid: userUuid,
        caption: _captionController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        muscleGroup: _muscleGroupController.text.trim().isEmpty
            ? null
            : _muscleGroupController.text.trim(),
      );

      if (result != null) {
        if (mounted) {
          Navigator.of(context).pop(true);
          MetalMessage.show(
            context: context,
            message: 'Тренировка создана',
            type: MetalMessageType.success,
          );
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при создании тренировки',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: $e',
          type: MetalMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхний раздел с кнопкой назад и названием
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text(
                        'Создать тренировку',
                        style: NinjaText.title,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    // Пустое место для симметрии
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Форма
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MetalTextField(
                        controller: _captionController,
                        hint: 'Название тренировки',
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
                      MetalTextField(
                        controller: _descriptionController,
                        hint: 'Описание (не обязательно)',
                        maxLines: 3,
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
                      MetalTextField(
                        controller: _muscleGroupController,
                        hint: 'Группа мышц (не обязательно)',
                      ),
                      const SizedBox(height: NinjaSpacing.xl),
                      MetalButton(
                        label: 'Создать тренировку',
                        onPressed: _isLoading ? null : _createTraining,
                        height: 56,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
