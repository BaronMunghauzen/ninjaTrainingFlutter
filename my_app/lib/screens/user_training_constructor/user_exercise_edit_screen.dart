import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_toggle_switch.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

class UserExerciseEditScreen extends StatefulWidget {
  final String exerciseUuid;

  const UserExerciseEditScreen({Key? key, required this.exerciseUuid})
    : super(key: key);

  @override
  State<UserExerciseEditScreen> createState() => _UserExerciseEditScreenState();
}

class _UserExerciseEditScreenState extends State<UserExerciseEditScreen> {
  final _setsCountController = TextEditingController();
  final _repsCountController = TextEditingController();
  final _restTimeController = TextEditingController();

  bool withWeight = false;
  bool _isLoading = false;
  String? exerciseReferenceName;
  String? _caption; // Название для отправки на бэк (не отображается)
  String? _description; // Описание для отправки на бэк (не отображается)
  String? _muscleGroup; // Группа мышц для отправки на бэк (не отображается)

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  @override
  void dispose() {
    _setsCountController.dispose();
    _repsCountController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadExerciseData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '/exercises/${widget.exerciseUuid}',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        // Сохраняем данные для отправки на бэк (не отображаем в форме)
        // Сохраняем как есть, даже если пустые - потом используем из справочника если нужно
        _caption = data['caption'];
        _description = data['description'];
        _muscleGroup = data['muscle_group'];
        _setsCountController.text = (data['sets_count'] ?? 1).toString();
        _repsCountController.text = (data['reps_count'] ?? 1).toString();
        _restTimeController.text = (data['rest_time'] ?? 0).toString();
        withWeight = data['with_weight'] ?? false;
        print('🔄 Loaded withWeight from API: $withWeight');

        // Загружаем данные упражнения из справочника
        final exerciseReferenceUuid = data['exercise_reference_uuid'];
        if (exerciseReferenceUuid != null) {
          await _loadExerciseReferenceData(exerciseReferenceUuid);
        }
      }
    } catch (e) {
      print('Error loading exercise data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExerciseReferenceData(String exerciseReferenceUuid) async {
    try {
      final response = await ApiService.get(
        '/exercise_reference/$exerciseReferenceUuid',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          exerciseReferenceName = data['caption'] ?? 'Неизвестное упражнение';
        });
        
        // Если поля пустые, используем значения из справочника
        if ((_caption == null || _caption!.isEmpty) && data['caption'] != null) {
          _caption = data['caption'];
        }
        if ((_description == null || _description!.isEmpty) && data['description'] != null) {
          _description = data['description'];
        }
        if ((_muscleGroup == null || _muscleGroup!.isEmpty) && data['muscle_group'] != null) {
          _muscleGroup = data['muscle_group'];
        }
      }
    } catch (e) {
      print('Error loading exercise reference data: $e');
      setState(() {
        exerciseReferenceName = 'Ошибка загрузки';
      });
    }
  }

  Future<void> _updateExercise() async {
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

    if (setsCount == null || setsCount <= 0) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Количество подходов должно быть положительным числом',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (repsCount == null || repsCount <= 0) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Количество повторений должно быть положительным числом',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (restTime == null || restTime < 0) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Время отдыха должно быть неотрицательным числом',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Пользователь не авторизован',
            type: MetalMessageType.error,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Используем сохраненные значения (если пустые, используем из справочника)
      final caption = _caption ?? '';
      final description = _description ?? '';
      final muscleGroup = _muscleGroup ?? '';
      
      final exerciseData = {
        'caption': caption,
        'description': description,
        'muscle_group': muscleGroup,
        'sets_count': setsCount,
        'reps_count': repsCount,
        'rest_time': restTime,
        'with_weight': withWeight,
      };

      final response = await ApiService.put(
        '/exercises/update/${widget.exerciseUuid}',
        body: exerciseData,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop(true);
          MetalMessage.show(
            context: context,
            message: 'Упражнение обновлено',
            type: MetalMessageType.success,
          );
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка при обновлении упражнения',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      print('Error updating exercise: $e');
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка при обновлении упражнения: $e',
          type: MetalMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                        'Редактировать упражнение',
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Упражнение из справочника (только для чтения, без возможности удаления)
                            Container(
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
                                      exerciseReferenceName ?? 'Загрузка...',
                                      style: exerciseReferenceName != null
                                          ? NinjaText.body
                                          : NinjaText.body.copyWith(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                    ),
                                  ),
                                ],
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
                              label: 'Сохранить',
                              onPressed: _isLoading ? null : _updateExercise,
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
