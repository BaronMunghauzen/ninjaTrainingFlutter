import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design/ninja_colors.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/statistics_service.dart';
import '../../../models/user_training_model.dart';
import '../../../models/measurement_type_model.dart';
import '../../../models/measurement_model.dart';
import '../../../models/exercise_model.dart';
import '../../../models/exercise_statistics_model.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/metal_list_item.dart';
import '../../../widgets/metal_modal.dart';
import '../../../widgets/metal_message.dart';
import '../../../widgets/metal_dropdown.dart';
import '../../../widgets/metal_text_field.dart';
import '../../../widgets/measurement_chart.dart';
import '../../../widgets/training_calendar.dart';
import '../../../widgets/exercise_statistics_table.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int? _completedTrainingsCount;
  List<UserTrainingModel> _trainings = [];
  List<MeasurementTypeModel> _systemMeasurementTypes = [];
  List<MeasurementTypeModel> _userMeasurementTypes = [];
  List<MeasurementModel> _weightMeasurements = [];
  List<MeasurementModel> _customMeasurements = [];
  List<ExerciseModel> _exercises = [];

  MeasurementTypeModel? _selectedCustomMeasurementType;
  ExerciseModel? _selectedExercise;
  ExerciseStatisticsModel? _exerciseStatistics;
  bool _isLoadingExerciseStatistics = false;

  DateTime? _weightDateFrom;
  DateTime? _weightDateTo;
  DateTime? _customDateFrom;
  DateTime? _customDateTo;

  bool _isLoading = false;
  String? _weightMeasurementTypeUuid;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;

    if (userUuid == null) {
      return;
    }

    try {
      // Загружаем данные параллельно
      final results = await Future.wait([
        StatisticsService.getCompletedTrainingsCount(userUuid),
        StatisticsService.getUserTrainingsForCalendar(userUuid),
        StatisticsService.getMeasurementTypes(
          dataType: 'system',
          caption: 'Вес',
        ),
        StatisticsService.getUserMeasurementTypes(),
        StatisticsService.getExerciseReferences(),
      ]);

      setState(() {
        _completedTrainingsCount = results[0] as int?;
        _trainings = results[1] as List<UserTrainingModel>? ?? [];
        final systemTypes = results[2] as List<MeasurementTypeModel>? ?? [];
        _systemMeasurementTypes = systemTypes;
        final userTypes = results[3] as List<MeasurementTypeModel>? ?? [];
        // Убираем дубликаты по UUID, используя Map для уникальности
        final uniqueTypes = <String, MeasurementTypeModel>{};
        for (final type in userTypes) {
          uniqueTypes[type.uuid] = type;
        }
        _userMeasurementTypes = uniqueTypes.values.toList();

        // Проверяем, что выбранный тип все еще существует в списке
        if (_selectedCustomMeasurementType != null) {
          final selectedExists = _userMeasurementTypes.any(
            (type) => type.uuid == _selectedCustomMeasurementType!.uuid,
          );
          if (selectedExists) {
            // Обновляем ссылку на актуальный объект из нового списка
            _selectedCustomMeasurementType = _userMeasurementTypes.firstWhere(
              (type) => type.uuid == _selectedCustomMeasurementType!.uuid,
            );
          } else {
            _selectedCustomMeasurementType = null;
          }
        }
        _exercises = results[4] as List<ExerciseModel>? ?? [];

        // Получаем UUID типа измерения "Вес"
        final weightType = systemTypes.firstWhere(
          (type) => type.caption == 'Вес',
          orElse: () =>
              systemTypes.isNotEmpty ? systemTypes.first : systemTypes.first,
        );
        _weightMeasurementTypeUuid = weightType.uuid;
      });

      // Загружаем измерения веса, если есть тип измерения
      if (_weightMeasurementTypeUuid != null) {
        await _loadWeightMeasurements();
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка загрузки данных: $e',
          type: MetalMessageType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWeightMeasurements() async {
    if (_weightMeasurementTypeUuid == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) return;

    try {
      final response = await StatisticsService.getUserMeasurements(
        _weightMeasurementTypeUuid!,
        dateFrom: _weightDateFrom?.toIso8601String().split('T')[0],
        dateTo: _weightDateTo?.toIso8601String().split('T')[0],
      );

      if (response != null) {
        setState(() {
          _weightMeasurements = response.items;
        });
      }
    } catch (e) {
      // Ошибка загрузки измерений веса
    }
  }

  Future<void> _loadCustomMeasurements() async {
    if (_selectedCustomMeasurementType == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) return;

    try {
      final response = await StatisticsService.getUserMeasurements(
        _selectedCustomMeasurementType!.uuid,
        dateFrom: _customDateFrom?.toIso8601String().split('T')[0],
        dateTo: _customDateTo?.toIso8601String().split('T')[0],
      );

      if (response != null) {
        setState(() {
          _customMeasurements = response.items;
        });
      }
    } catch (e) {
      // Ошибка загрузки кастомных измерений
    }
  }

  void _onDateSelected(DateTime date, List<UserTrainingModel> trainings) {
    MetalModal.show(
      context: context,
      title: 'Тренировки ${_formatDate(date)}',
      children: [
        SizedBox(
          width: double.maxFinite,
          height: 400,
          child: trainings.isEmpty
              ? Center(
                  child: Text(
                    'Нет тренировок на эту дату',
                    style: NinjaText.body.copyWith(
                      color: NinjaColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: trainings.length,
                  separatorBuilder: (context, index) => const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final training = trainings[index];
                    return MetalListItem(
                      leading: const SizedBox.shrink(),
                      title: Text(
                        training.training.caption,
                        style: NinjaText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (training.training.muscleGroup.isNotEmpty) ...[
                            const SizedBox(height: NinjaSpacing.xs),
                            Text(
                              'Группа мышц: ${training.training.muscleGroup}',
                              style: NinjaText.caption,
                            ),
                          ],
                          if (training.program.caption.isNotEmpty) ...[
                            const SizedBox(height: NinjaSpacing.xs),
                            Text(
                              'Программа: ${training.program.caption}',
                              style: NinjaText.caption,
                            ),
                          ],
                        ],
                      ),
                      onTap: () {},
                      isFirst: index == 0,
                      isLast: index == trainings.length - 1,
                      removeSpacing: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: TexturedBackground(
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                NinjaColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Счетчик тренировок
                _buildTrainingCountCard(),
                const SizedBox(height: NinjaSpacing.lg),

                // Календарь тренировок
                _buildTrainingCalendar(),
                const SizedBox(height: NinjaSpacing.lg),

                // График веса
                _buildWeightChart(),
                const SizedBox(height: NinjaSpacing.lg),

                // График кастомных измерений
                _buildCustomMeasurementsChart(),
                const SizedBox(height: NinjaSpacing.lg),

                // Статистика упражнений
                _buildExerciseStatistics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCountCard() {
    return MetalCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(NinjaSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Проведено тренировок',
              style: NinjaText.body.copyWith(color: NinjaColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NinjaSpacing.sm),
            Text(
              '${_completedTrainingsCount ?? 0} шт',
              style: NinjaText.title.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCalendar() {
    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Календарь проведенных тренировок', style: NinjaText.title),
          const SizedBox(height: NinjaSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Фон в стиле metal_list_item
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF202020)),
                  ),
                ),
                // Текстура
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/textures/graphite_noise.png',
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.05),
                      colorBlendMode: BlendMode.softLight,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                // Вертикальная светотень
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.16),
                            Colors.transparent,
                            Colors.black.withOpacity(0.32),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Горизонтальная светотень
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                            Colors.black.withOpacity(0.60),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Календарь поверх фона (с прозрачным фоном)
                TrainingCalendar(
                  trainings: _trainings,
                  onDateSelected: _onDateSelected,
                  transparentBackground: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    final dateFromController = TextEditingController(
      text: _weightDateFrom != null
          ? '${_weightDateFrom!.day}/${_weightDateFrom!.month}/${_weightDateFrom!.year}'
          : '',
    );
    final dateToController = TextEditingController(
      text: _weightDateTo != null
          ? '${_weightDateTo!.day}/${_weightDateTo!.month}/${_weightDateTo!.year}'
          : '',
    );

    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Отслеживание веса', style: NinjaText.title),
          const SizedBox(height: NinjaSpacing.lg),

          // Поля для выбора дат
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _weightDateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _weightDateFrom = date;
                        dateFromController.text =
                            '${date.day}/${date.month}/${date.year}';
                      });
                      await _loadWeightMeasurements();
                    }
                  },
                  child: Stack(
                    children: [
                      MetalTextField(
                        controller: dateFromController,
                        hint: 'Дата от',
                        enabled: false,
                      ),
                      if (_weightDateFrom != null)
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _weightDateFrom = null;
                                dateFromController.clear();
                              });
                              _loadWeightMeasurements();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: NinjaSpacing.md),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _weightDateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _weightDateTo = date;
                        dateToController.text =
                            '${date.day}/${date.month}/${date.year}';
                      });
                      await _loadWeightMeasurements();
                    }
                  },
                  child: Stack(
                    children: [
                      MetalTextField(
                        controller: dateToController,
                        hint: 'Дата до',
                        enabled: false,
                      ),
                      if (_weightDateTo != null)
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _weightDateTo = null;
                                dateToController.clear();
                              });
                              _loadWeightMeasurements();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NinjaSpacing.lg),

          // График с фоном из metal_list_item
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Фон в стиле metal_list_item
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF202020)),
                  ),
                ),
                // Текстура
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/textures/graphite_noise.png',
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.05),
                      colorBlendMode: BlendMode.softLight,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                // Вертикальная светотень
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.16),
                            Colors.transparent,
                            Colors.black.withOpacity(0.32),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Горизонтальная светотень
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                            Colors.black.withOpacity(0.60),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // График поверх фона
                MeasurementChart(
                  measurements: _weightMeasurements,
                  measurementTypeCaption: 'Вес',
                  onAddMeasurement: () => _showAddMeasurementModal('weight'),
                  onViewList: () =>
                      _showMeasurementListModal(_weightMeasurements, 'Вес'),
                  transparentBackground: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMeasurementsChart() {
    final customDateFromController = TextEditingController(
      text: _customDateFrom != null
          ? '${_customDateFrom!.day}/${_customDateFrom!.month}/${_customDateFrom!.year}'
          : '',
    );
    final customDateToController = TextEditingController(
      text: _customDateTo != null
          ? '${_customDateTo!.day}/${_customDateTo!.month}/${_customDateTo!.year}'
          : '',
    );

    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Другие замеры', style: NinjaText.title),
          const SizedBox(height: NinjaSpacing.lg),

          // Выпадающий список типов измерений
          Row(
            children: [
              Expanded(child: _buildCustomMeasurementTypeDropdown()),
              const SizedBox(width: NinjaSpacing.md),
              IconButton(
                onPressed: () => _showMeasurementTypeModal(),
                icon: const Icon(Icons.settings),
                tooltip: 'Управление типами измерений',
                color: NinjaColors.textPrimary,
              ),
            ],
          ),

          if (_selectedCustomMeasurementType != null) ...[
            const SizedBox(height: NinjaSpacing.lg),

            // Поля для выбора дат
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _customDateFrom ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _customDateFrom = date;
                          customDateFromController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                        await _loadCustomMeasurements();
                      }
                    },
                    child: Stack(
                      children: [
                        MetalTextField(
                          controller: customDateFromController,
                          hint: 'Дата от',
                          enabled: false,
                        ),
                        if (_customDateFrom != null)
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _customDateFrom = null;
                                  customDateFromController.clear();
                                });
                                _loadCustomMeasurements();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: NinjaSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _customDateTo ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _customDateTo = date;
                          customDateToController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                        await _loadCustomMeasurements();
                      }
                    },
                    child: Stack(
                      children: [
                        MetalTextField(
                          controller: customDateToController,
                          hint: 'Дата до',
                          enabled: false,
                        ),
                        if (_customDateTo != null)
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _customDateTo = null;
                                  customDateToController.clear();
                                });
                                _loadCustomMeasurements();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NinjaSpacing.lg),

            // График с фоном из metal_list_item
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Фон в стиле metal_list_item
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF202020)),
                    ),
                  ),
                  // Текстура
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/textures/graphite_noise.png',
                        fit: BoxFit.cover,
                        color: Colors.white.withOpacity(0.05),
                        colorBlendMode: BlendMode.softLight,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  // Вертикальная светотень
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.16),
                              Colors.transparent,
                              Colors.black.withOpacity(0.32),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Горизонтальная светотень
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                              Colors.black.withOpacity(0.60),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // График поверх фона
                  MeasurementChart(
                    measurements: _customMeasurements,
                    measurementTypeCaption:
                        _selectedCustomMeasurementType!.caption,
                    onAddMeasurement: () => _showAddMeasurementModal('custom'),
                    onViewList: () => _showMeasurementListModal(
                      _customMeasurements,
                      _selectedCustomMeasurementType!.caption,
                    ),
                    transparentBackground: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomMeasurementTypeDropdown() {
    if (_userMeasurementTypes.isEmpty) {
      return MetalDropdown<MeasurementTypeModel?>(
        value: null,
        items: [
          MetalDropdownItem<MeasurementTypeModel?>(
            value: null,
            label: 'Нет типов измерений',
          ),
        ],
        onChanged: (_) {},
      );
    }

    return MetalDropdown<MeasurementTypeModel>(
      value: _selectedCustomMeasurementType ?? _userMeasurementTypes.first,
      items: _userMeasurementTypes.map((type) {
        return MetalDropdownItem<MeasurementTypeModel>(
          value: type,
          label: type.caption,
        );
      }).toList(),
      onChanged: (type) {
        setState(() {
          _selectedCustomMeasurementType = type;
          _customMeasurements.clear();
        });
        _loadCustomMeasurements();
      },
    );
  }

  Widget _buildCustomDropdown() {
    if (_exercises.isEmpty) {
      return MetalDropdown<ExerciseModel?>(
        value: null,
        items: [
          MetalDropdownItem<ExerciseModel?>(
            value: null,
            label: 'Нет упражнений',
          ),
        ],
        onChanged: (_) {},
      );
    }

    return MetalDropdown<ExerciseModel>(
      value: _selectedExercise ?? _exercises.first,
      items: _exercises.map((exercise) {
        return MetalDropdownItem<ExerciseModel>(
          value: exercise,
          label: exercise.caption,
        );
      }).toList(),
      onChanged: (exercise) {
        setState(() {
          _selectedExercise = exercise;
          _exerciseStatistics = null;
          _isLoadingExerciseStatistics = false;
        });
        _loadExerciseStatistics(exercise);
      },
    );
  }

  Widget _buildExerciseStatistics() {
    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статистика упражнений', style: NinjaText.title),
          const SizedBox(height: NinjaSpacing.lg),

          _buildCustomDropdown(),

          if (_selectedExercise != null) ...[
            const SizedBox(height: NinjaSpacing.lg),
            _isLoadingExerciseStatistics
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NinjaColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                : _exerciseStatistics != null
                ? ExerciseStatisticsTable(statistics: _exerciseStatistics!)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Выберите упражнение для просмотра статистики',
                        style: NinjaText.body.copyWith(
                          color: NinjaColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadExerciseStatistics(ExerciseModel exercise) async {
    if (_isLoadingExerciseStatistics) {
      return;
    }

    setState(() {
      _isLoadingExerciseStatistics = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) {
      setState(() {
        _isLoadingExerciseStatistics = false;
      });
      return;
    }

    try {
      final statistics = await StatisticsService.getExerciseStatistics(
        exerciseReferenceUuid: exercise.uuid,
        userUuid: userUuid,
      );

      setState(() {
        _exerciseStatistics = statistics;
        _isLoadingExerciseStatistics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingExerciseStatistics = false;
      });
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка загрузки статистики: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  void _showAddMeasurementModal(String type) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) return;

    // Проверяем подписку перед добавлением измерения
    final userProfile = authProvider.userProfile;
    if (userProfile != null && userProfile.subscriptionStatus != 'active') {
      MetalModal.show(
        context: context,
        title: 'Ошибка',
        children: [
          Text(
            'Для добавления измерений необходимо продлить подписку',
            style: NinjaText.body,
          ),
        ],
      );
      return;
    }

    String measurementTypeUuid;
    String title;

    if (type == 'weight') {
      measurementTypeUuid = _weightMeasurementTypeUuid ?? '';
      title = 'Добавить измерение веса';
    } else {
      measurementTypeUuid = _selectedCustomMeasurementType?.uuid ?? '';
      title =
          'Добавить измерение ${_selectedCustomMeasurementType?.caption ?? ''}';
    }

    final dateController = TextEditingController();
    final valueController = TextEditingController();
    DateTime? selectedDate;

    MetalModal.show(
      context: context,
      title: title,
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() {
                        selectedDate = date;
                        dateController.text = date.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                  child: MetalTextField(
                    controller: dateController,
                    hint: 'Дата',
                    enabled: false,
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),
                MetalTextField(
                  controller: valueController,
                  hint: 'Значение',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Отмена', style: NinjaText.body),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    TextButton(
                      onPressed: () async {
                        final date = dateController.text.trim();
                        final valueText = valueController.text.trim();

                        if (date.isEmpty || valueText.isEmpty) {
                          MetalMessage.show(
                            context: context,
                            message: 'Заполните все поля',
                            type: MetalMessageType.error,
                          );
                          return;
                        }

                        final normalizedValueText = valueText.replaceAll(
                          ',',
                          '.',
                        );
                        final value = double.tryParse(normalizedValueText);
                        if (value == null) {
                          MetalMessage.show(
                            context: context,
                            message: 'Введите корректное значение',
                            type: MetalMessageType.error,
                          );
                          return;
                        }

                        Navigator.of(context).pop();

                        final success = await StatisticsService.addMeasurement(
                          userUuid: userUuid,
                          measurementTypeUuid: measurementTypeUuid,
                          measurementDate: date,
                          value: value,
                        );

                        if (success) {
                          if (type == 'weight') {
                            await _loadWeightMeasurements();
                          } else {
                            await _loadCustomMeasurements();
                          }
                          if (mounted) {
                            MetalMessage.show(
                              context: context,
                              message: 'Измерение добавлено',
                              type: MetalMessageType.success,
                            );
                          }
                        } else {
                          if (mounted) {
                            MetalMessage.show(
                              context: context,
                              message: 'Ошибка добавления измерения',
                              type: MetalMessageType.error,
                            );
                          }
                        }
                      },
                      child: Text('Сохранить', style: NinjaText.body),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showMeasurementListModal(
    List<MeasurementModel> measurements,
    String caption,
  ) {
    final currentMeasurements = measurements == _weightMeasurements
        ? _weightMeasurements
        : _customMeasurements;

    MetalModal.show(
      context: context,
      title: 'Список измерений - $caption',
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: currentMeasurements.isEmpty
                  ? Center(
                      child: Text(
                        'Нет данных для отображения',
                        style: NinjaText.body.copyWith(
                          color: NinjaColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: currentMeasurements.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox.shrink(),
                      itemBuilder: (context, index) {
                        final measurement = currentMeasurements[index];
                        final date = DateTime.parse(
                          measurement.measurementDate,
                        );

                        return MetalListItem(
                          leading: const SizedBox.shrink(),
                          title: Text(
                            '${measurement.value.toStringAsFixed(1)}',
                            style: NinjaText.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: NinjaText.caption,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _showEditMeasurementModal(
                                    measurement,
                                    measurements == _weightMeasurements
                                        ? 'weight'
                                        : 'custom',
                                  );
                                },
                                color: NinjaColors.textSecondary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: NinjaSpacing.xs),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  final success =
                                      await StatisticsService.deleteMeasurement(
                                        measurement.uuid,
                                      );
                                  if (success) {
                                    if (measurements == _weightMeasurements) {
                                      await _loadWeightMeasurements();
                                    } else {
                                      await _loadCustomMeasurements();
                                    }
                                    // Обновляем модальное окно
                                    setModalState(() {});
                                    if (mounted) {
                                      MetalMessage.show(
                                        context: context,
                                        message: 'Измерение удалено',
                                        type: MetalMessageType.success,
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      MetalMessage.show(
                                        context: context,
                                        message: 'Ошибка удаления измерения',
                                        type: MetalMessageType.error,
                                      );
                                    }
                                  }
                                },
                                color: Colors.red,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          onTap: () {},
                          isFirst: index == 0,
                          isLast: index == currentMeasurements.length - 1,
                          removeSpacing: true,
                        );
                      },
                    ),
            );
          },
        ),
      ],
    );
  }

  void _showEditMeasurementModal(MeasurementModel measurement, String type) {
    final dateController = TextEditingController(
      text: measurement.measurementDate,
    );
    final valueController = TextEditingController(
      text: measurement.value.toString(),
    );
    DateTime? selectedDate = DateTime.parse(measurement.measurementDate);

    MetalModal.show(
      context: context,
      title: 'Редактировать измерение',
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setModalState(() {
                        selectedDate = date;
                        dateController.text = date.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                  child: MetalTextField(
                    controller: dateController,
                    hint: 'Дата',
                    enabled: false,
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),
                MetalTextField(
                  controller: valueController,
                  hint: 'Значение',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Отмена', style: NinjaText.body),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    TextButton(
                      onPressed: () async {
                        final date = dateController.text.trim();
                        final valueText = valueController.text.trim();

                        if (date.isEmpty || valueText.isEmpty) {
                          MetalMessage.show(
                            context: context,
                            message: 'Заполните все поля',
                            type: MetalMessageType.error,
                          );
                          return;
                        }

                        final normalizedValueText = valueText.replaceAll(
                          ',',
                          '.',
                        );
                        final value = double.tryParse(normalizedValueText);
                        if (value == null) {
                          MetalMessage.show(
                            context: context,
                            message: 'Введите корректное значение',
                            type: MetalMessageType.error,
                          );
                          return;
                        }

                        Navigator.of(context).pop();

                        final success =
                            await StatisticsService.updateMeasurement(
                              measurementUuid: measurement.uuid,
                              measurementDate: date,
                              value: value,
                            );

                        if (success) {
                          if (type == 'weight') {
                            await _loadWeightMeasurements();
                          } else {
                            await _loadCustomMeasurements();
                          }
                          if (mounted) {
                            MetalMessage.show(
                              context: context,
                              message: 'Измерение обновлено',
                              type: MetalMessageType.success,
                            );
                          }
                        } else {
                          if (mounted) {
                            MetalMessage.show(
                              context: context,
                              message: 'Ошибка обновления измерения',
                              type: MetalMessageType.error,
                            );
                          }
                        }
                      },
                      child: Text('Сохранить', style: NinjaText.body),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showMeasurementTypeModal() {
    MetalModal.show(
      context: context,
      title: 'Типы измерений',
      children: [
        StatefulBuilder(
          builder: (context, setModalState) {
            // Пересоздаем список типов при каждом обновлении модалки
            // Исключаем тип "Вес" из списка
            final allTypes = [
              ..._systemMeasurementTypes,
              ..._userMeasurementTypes,
            ].where((type) => type.caption != 'Вес').toList();
            
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Кнопка добавления
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        final captionController = TextEditingController();
                        MetalModal.show(
                          context: context,
                          title: 'Добавить тип измерения',
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                MetalTextField(
                                  controller: captionController,
                                  hint: 'Название типа измерения',
                                ),
                                const SizedBox(height: NinjaSpacing.lg),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(
                                        'Отмена',
                                        style: NinjaText.body,
                                      ),
                                    ),
                                    const SizedBox(width: NinjaSpacing.md),
                                    TextButton(
                                      onPressed: () async {
                                        final caption = captionController.text
                                            .trim();
                                        if (caption.isEmpty) {
                                          MetalMessage.show(
                                            context: context,
                                            message: 'Введите название',
                                            type: MetalMessageType.error,
                                          );
                                          return;
                                        }

                                        Navigator.of(context).pop();

                                        final authProvider =
                                            Provider.of<AuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        final userUuid = authProvider.userUuid;
                                        if (userUuid == null) return;

                                        final success =
                                            await StatisticsService.addMeasurementType(
                                              userUuid: userUuid,
                                              caption: caption,
                                            );

                                        if (success) {
                                          await _loadInitialData();
                                          _selectedCustomMeasurementType = null;
                                          // Обновляем модалку после загрузки данных
                                          setModalState(() {});
                                          if (mounted) {
                                            MetalMessage.show(
                                              context: context,
                                              message: 'Тип измерения добавлен',
                                              type: MetalMessageType.success,
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            MetalMessage.show(
                                              context: context,
                                              message:
                                                  'Ошибка добавления типа измерения',
                                              type: MetalMessageType.error,
                                            );
                                          }
                                        }
                                      },
                                      child: Text(
                                        'Добавить',
                                        style: NinjaText.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Добавить тип измерения',
                        style: NinjaText.body,
                      ),
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),
                  // Список типов измерений
                  Expanded(
                    child: allTypes.isEmpty
                        ? Center(
                            child: Text(
                              'Нет типов измерений',
                              style: NinjaText.body.copyWith(
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: allTypes.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox.shrink(),
                            itemBuilder: (context, index) {
                              final measurementType = allTypes[index];
                              final isCustom =
                                  measurementType.dataType == 'custom';

                              return MetalListItem(
                                leading: const SizedBox.shrink(),
                                title: Text(
                                  measurementType.caption,
                                  style: NinjaText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: isCustom
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              final captionController =
                                                  TextEditingController(
                                                    text:
                                                        measurementType.caption,
                                                  );
                                              // Сохраняем setModalState из родительской модалки
                                              final parentSetModalState = setModalState;
                                              MetalModal.show(
                                                context: context,
                                                title:
                                                    'Редактировать тип измерения',
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      MetalTextField(
                                                        controller:
                                                            captionController,
                                                        hint:
                                                            'Название типа измерения',
                                                      ),
                                                      const SizedBox(
                                                        height: NinjaSpacing.lg,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(),
                                                            child: Text(
                                                              'Отмена',
                                                              style: NinjaText
                                                                  .body,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width:
                                                                NinjaSpacing.md,
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              final caption =
                                                                  captionController
                                                                      .text
                                                                      .trim();
                                                              if (caption
                                                                  .isEmpty) {
                                                                MetalMessage.show(
                                                                  context:
                                                                      context,
                                                                  message:
                                                                      'Введите название',
                                                                  type:
                                                                      MetalMessageType
                                                                          .error,
                                                                );
                                                                return;
                                                              }

                                                              Navigator.of(
                                                                context,
                                                              ).pop();

                                                              final success =
                                                                  await StatisticsService.updateMeasurementType(
                                                                    measurementTypeUuid:
                                                                        measurementType
                                                                            .uuid,
                                                                    caption:
                                                                        caption,
                                                                  );

                                                              if (success) {
                                                                await _loadInitialData();
                                                                if (_selectedCustomMeasurementType
                                                                        ?.uuid ==
                                                                    measurementType
                                                                        .uuid) {
                                                                  _selectedCustomMeasurementType = _userMeasurementTypes.firstWhere(
                                                                    (type) =>
                                                                        type.uuid ==
                                                                        measurementType
                                                                            .uuid,
                                                                    orElse: () =>
                                                                        _selectedCustomMeasurementType!,
                                                                  );
                                                                }
                                                                // Обновляем родительскую модалку после загрузки данных
                                                                parentSetModalState(() {});
                                                                if (mounted) {
                                                                  MetalMessage.show(
                                                                    context:
                                                                        context,
                                                                    message:
                                                                        'Тип измерения обновлен',
                                                                    type: MetalMessageType
                                                                        .success,
                                                                  );
                                                                }
                                                              } else {
                                                                if (mounted) {
                                                                  MetalMessage.show(
                                                                    context:
                                                                        context,
                                                                    message:
                                                                        'Ошибка обновления типа измерения',
                                                                    type: MetalMessageType
                                                                        .error,
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            child: Text(
                                                              'Сохранить',
                                                              style: NinjaText
                                                                  .body,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                            color: NinjaColors.textSecondary,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          const SizedBox(
                                            width: NinjaSpacing.xs,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              MetalModal.show(
                                                context: context,
                                                title: 'Подтверждение удаления',
                                                children: [
                                                  Text(
                                                    'Вы уверены, что хотите удалить "${measurementType.caption}"?',
                                                    style: NinjaText.body,
                                                  ),
                                                  const SizedBox(
                                                    height: NinjaSpacing.lg,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: Text(
                                                          'Отмена',
                                                          style: NinjaText.body,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: NinjaSpacing.md,
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();

                                                          final success =
                                                              await StatisticsService.deleteMeasurementType(
                                                                measurementType
                                                                    .uuid,
                                                              );

                                                          if (success) {
                                                            await _loadInitialData();
                                                            if (_selectedCustomMeasurementType
                                                                    ?.uuid ==
                                                                measurementType
                                                                    .uuid) {
                                                              _selectedCustomMeasurementType =
                                                                  null;
                                                              _customMeasurements
                                                                  .clear();
                                                            }
                                                            setModalState(
                                                              () {},
                                                            );
                                                            if (mounted) {
                                                              MetalMessage.show(
                                                                context:
                                                                    context,
                                                                message:
                                                                    'Тип измерения удален',
                                                                type:
                                                                    MetalMessageType
                                                                        .success,
                                                              );
                                                            }
                                                          } else {
                                                            if (mounted) {
                                                              MetalMessage.show(
                                                                context:
                                                                    context,
                                                                message:
                                                                    'Ошибка удаления типа измерения',
                                                                type:
                                                                    MetalMessageType
                                                                        .error,
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: Text(
                                                          'Удалить',
                                                          style: NinjaText.body
                                                              .copyWith(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                            color: Colors.red,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {},
                                isFirst: index == 0,
                                isLast: index == allTypes.length - 1,
                                removeSpacing: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
