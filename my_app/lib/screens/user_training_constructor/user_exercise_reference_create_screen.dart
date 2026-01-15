import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_dropdown.dart';
import '../../widgets/metal_toggle_switch.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_message.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';

class UserExerciseReferenceCreateScreen extends StatefulWidget {
  const UserExerciseReferenceCreateScreen({Key? key}) : super(key: key);

  @override
  State<UserExerciseReferenceCreateScreen> createState() =>
      _UserExerciseReferenceCreateScreenState();
}

class _UserExerciseReferenceCreateScreenState
    extends State<UserExerciseReferenceCreateScreen> {
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _hasEquipment = false;
  
  // Фильтры для выпадающих списков
  List<String> _availableMuscleGroups = [];
  List<String> _availableEquipmentNames = [];
  static const String _notSpecified = 'Не указано';
  String? _selectedMuscleGroup = _notSpecified;
  String? _selectedEquipmentName = _notSpecified;
  bool _isLoadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() {
          _availableMuscleGroups = [];
          _availableEquipmentNames = [];
          _isLoadingFilters = false;
        });
        return;
      }

      final response = await ApiService.get(
        '/exercise_reference/filters/$userUuid',
      );
      
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final equipmentNames = List<String>.from(
          data['equipment_names'] ?? [],
        );
        // Убираем "Без оборудования" из списка
        equipmentNames.remove('Без оборудования');
        
        setState(() {
          final muscleGroups = List<String>.from(
            data['muscle_groups'] ?? [],
          );
          // Добавляем "Не указано" в начало списка
          _availableMuscleGroups = [_notSpecified, ...muscleGroups];
          // Добавляем "Не указано" в начало списка оборудования
          _availableEquipmentNames = [_notSpecified, ...equipmentNames];
          _isLoadingFilters = false;
        });
      } else {
        setState(() {
          _availableMuscleGroups = [];
          _availableEquipmentNames = [];
          _isLoadingFilters = false;
        });
      }
    } catch (e) {
      print('Error loading filters: $e');
      setState(() {
        _availableMuscleGroups = [];
        _availableEquipmentNames = [];
        _isLoadingFilters = false;
      });
    }
  }

  Future<void> _createExercise() async {
    // Валидация полей
    if (_captionController.text.trim().isEmpty) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, введите название упражнения',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (_selectedMuscleGroup == null || _selectedMuscleGroup == _notSpecified) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, выберите группу мышц',
          type: MetalMessageType.error,
        );
      }
      return;
    }

    if (_hasEquipment && (_selectedEquipmentName == null || _selectedEquipmentName == _notSpecified)) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Пожалуйста, выберите оборудование',
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

      final result = await UserTrainingService.createUserExercise(
        userUuid: userUuid,
        caption: _captionController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        muscleGroup: _selectedMuscleGroup!,
        equipmentName: _hasEquipment ? _selectedEquipmentName : null,
      );

      if (result != null) {
        if (mounted) {
          Navigator.of(context).pop(true);
          MetalMessage.show(
            context: context,
            message: 'Упражнение создано',
            type: MetalMessageType.success,
          );
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
      setState(() {
        _isLoading = false;
      });
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
                        'Создать упражнение',
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
                          hint: 'Название упражнения',
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        MetalTextField(
                          controller: _descriptionController,
                          hint: 'Описание',
                          maxLines: 3,
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Группа мышц - выпадающий список
                        if (_isLoadingFilters)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          )
                        else if (_availableMuscleGroups.isEmpty)
                          Text(
                            'Группы мышц не загружены',
                            style: NinjaText.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Группа мышц',
                                style: NinjaText.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MetalDropdown<String>(
                                value: _selectedMuscleGroup ?? _notSpecified,
                                items: _availableMuscleGroups.map((group) {
                                  return MetalDropdownItem<String>(
                                    value: group,
                                    label: group,
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMuscleGroup = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Оборудование - переключатель
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Используется оборудование:',
                                style: NinjaText.body,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120,
                              child: MetalToggleSwitch(
                                value: _hasEquipment,
                                onChanged: (value) {
                                  setState(() {
                                    _hasEquipment = value;
                                    if (!value) {
                                      _selectedEquipmentName = null;
                                    } else {
                                      _selectedEquipmentName = _notSpecified;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_hasEquipment) ...[
                          const SizedBox(height: NinjaSpacing.lg),
                          // Название оборудования - выпадающий список
                          if (_availableEquipmentNames.isEmpty)
                            Text(
                              'Оборудование не загружено',
                              style: NinjaText.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Название оборудования',
                                  style: NinjaText.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                MetalDropdown<String>(
                                  value: _selectedEquipmentName ?? _notSpecified,
                                  items: _availableEquipmentNames.map((equipment) {
                                    return MetalDropdownItem<String>(
                                      value: equipment,
                                      label: equipment,
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedEquipmentName = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                        const SizedBox(height: NinjaSpacing.xl),
                        MetalButton(
                          label: 'Создать упражнение',
                          onPressed: _isLoading ? null : _createExercise,
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
