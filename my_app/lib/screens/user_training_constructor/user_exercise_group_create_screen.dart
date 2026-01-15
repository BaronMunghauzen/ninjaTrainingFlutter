import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../models/search_result_model.dart' as search_models;
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_toggle_switch.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';
import 'user_exercise_selector_screen.dart';

class UserExerciseGroupCreateScreen extends StatefulWidget {
  final String trainingUuid;

  const UserExerciseGroupCreateScreen({Key? key, required this.trainingUuid})
    : super(key: key);

  @override
  State<UserExerciseGroupCreateScreen> createState() =>
      _UserExerciseGroupCreateScreenState();
}

class _UserExerciseGroupCreateScreenState
    extends State<UserExerciseGroupCreateScreen> {
  final _setsCountController = TextEditingController();
  final _repsCountController = TextEditingController();
  final _restTimeController = TextEditingController();

  ExerciseReference? selectedExercise;
  bool withWeight = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _setsCountController.dispose();
    _repsCountController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectExercise() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserExerciseSelectorScreen(),
      ),
    );

    if (result != null) {
      // Преобразуем ExerciseReference из search_result_model в ExerciseReference из user_training_service
      final searchExerciseRef = result as search_models.ExerciseReference;
      final userExerciseRef = ExerciseReference(
        uuid: searchExerciseRef.uuid,
        exerciseType: searchExerciseRef.exerciseType,
        caption: searchExerciseRef.caption,
        description: searchExerciseRef.description,
        muscleGroup: searchExerciseRef.muscleGroup,
        userUuid: searchExerciseRef.userId?.toString(),
        imageUuid: searchExerciseRef.image?.toString(),
        videoUuid: searchExerciseRef.video?.toString(),
        createdAt: searchExerciseRef.createdAt.toIso8601String(),
        updatedAt: searchExerciseRef.updatedAt.toIso8601String(),
      );

      setState(() {
        selectedExercise = userExerciseRef;
      });
    }
  }

  Future<void> _createExerciseGroup() async {
    // Валидация выбора упражнения
    if (selectedExercise == null) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, выберите упражнение',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    // Валидация полей
    if (_setsCountController.text.trim().isEmpty) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, введите количество подходов',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (_repsCountController.text.trim().isEmpty) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, введите количество повторений',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (_restTimeController.text.trim().isEmpty) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, введите время отдыха',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    // Проверка, что значения - числа
    final setsCount = int.tryParse(_setsCountController.text.trim());
    final repsCount = int.tryParse(_repsCountController.text.trim());
    final restTime = int.tryParse(_restTimeController.text.trim());

    if (setsCount == null) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Количество подходов должно быть числом',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (repsCount == null) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Количество повторений должно быть числом',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (restTime == null) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Время отдыха должно быть числом',
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

      // Используем данные из выбранного упражнения
      final caption = selectedExercise!.caption;
      final description = selectedExercise!.description;
      final muscleGroup = selectedExercise!.muscleGroup;

      // Создаем упражнение
      final exerciseResult = await UserTrainingService.createExercise(
        userUuid: userUuid,
        caption: caption,
        description: description,
        muscleGroup: muscleGroup,
        setsCount: setsCount,
        repsCount: repsCount,
        restTime: restTime,
        withWeight: withWeight,
        weight: 0,
        exerciseReferenceUuid: selectedExercise!.uuid,
      );

      if (exerciseResult != null && exerciseResult['uuid'] != null) {
        // Создаем группу упражнений
        final groupResult = await UserTrainingService.createExerciseGroup(
          trainingUuid: widget.trainingUuid,
          caption: caption,
          description: description,
          muscleGroup: muscleGroup,
          exercises: [exerciseResult['uuid']],
        );

        if (groupResult != null) {
          if (mounted) {
            Navigator.of(context).pop(true);
            MetalMessage.show(
              context: context,
              message: 'Группа упражнений создана',
              type: MetalMessageType.success,
            );
          }
        } else {
          if (mounted) {
            MetalMessage.show(
              context: context,
              message: 'Ошибка при создании группы упражнений',
              type: MetalMessageType.error,
            );
          }
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при создании упражнения',
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
                        'Добавить упражнение',
                        style: NinjaText.title,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    // Кнопка выбора упражнения справа
                    MetalBackButton(
                      icon: Icons.search,
                      onTap: _selectExercise,
                    ),
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
                      // Выбор упражнения из справочника
                      GestureDetector(
                        onTap: _selectExercise,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedExercise != null
                                      ? selectedExercise!.caption
                                      : 'Выберите упражнение',
                                  style: selectedExercise != null
                                      ? NinjaText.body
                                      : NinjaText.body.copyWith(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                ),
                              ),
                              if (selectedExercise != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedExercise = null;
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
                      // Количество подходов и повторений в одной строке
                      Row(
                        children: [
                          Expanded(
                            child: MetalTextField(
                              controller: _setsCountController,
                              hint: 'Подходы',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: NinjaSpacing.md),
                          Expanded(
                            child: MetalTextField(
                              controller: _repsCountController,
                              hint: 'Повторения',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
                      MetalTextField(
                        controller: _restTimeController,
                        hint: 'Время отдыха (секунды)',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
                      // Переключатель "С весом"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'С весом',
                            style: NinjaText.body,
                          ),
                          SizedBox(
                            width: 120,
                            child: MetalToggleSwitch(
                              value: withWeight,
                              onChanged: (value) {
                                setState(() {
                                  withWeight = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: NinjaSpacing.xl),
                      MetalButton(
                        label: 'Добавить упражнение',
                        onPressed: _isLoading ? null : _createExerciseGroup,
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
