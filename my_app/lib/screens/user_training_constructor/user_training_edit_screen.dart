import 'package:flutter/material.dart';
import '../../models/training_model.dart';
import '../../services/user_training_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

class UserTrainingEditScreen extends StatefulWidget {
  final Training training;

  const UserTrainingEditScreen({super.key, required this.training});

  @override
  State<UserTrainingEditScreen> createState() => _UserTrainingEditScreenState();
}

class _UserTrainingEditScreenState extends State<UserTrainingEditScreen> {
  late final TextEditingController _captionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _muscleGroupController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры с текущими значениями
    _captionController = TextEditingController(text: widget.training.caption);
    _descriptionController = TextEditingController(
      text: widget.training.description,
    );
    _muscleGroupController = TextEditingController(
      text: widget.training.muscleGroup,
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  Future<void> _updateTraining() async {
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
      final result = await UserTrainingService.updateUserTraining(
        trainingUuid: widget.training.uuid,
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
            message: 'Тренировка обновлена',
            type: MetalMessageType.success,
          );
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при обновлении тренировки',
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
                        'Редактировать тренировку',
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
                        label: 'Сохранить изменения',
                        onPressed: _isLoading ? null : _updateTraining,
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
