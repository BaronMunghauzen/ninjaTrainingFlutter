import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/statistics_service.dart';
import '../../../models/user_training_model.dart';
import '../../../models/measurement_type_model.dart';
import '../../../models/measurement_model.dart';
import '../../../models/exercise_model.dart';
import '../../../models/exercise_statistics_model.dart';
import '../../../widgets/measurement_chart.dart';
import '../../../widgets/measurement_modal.dart';
import '../../../widgets/measurement_type_modal.dart';
import '../../../widgets/training_calendar.dart';
import '../../../widgets/training_detail_modal.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
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
    showDialog(
      context: context,
      builder: (context) =>
          TrainingDetailModal(selectedDate: date, trainings: trainings),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Статистика',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1F2121)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Счетчик тренировок
            _buildTrainingCountCard(),
            const SizedBox(height: 24),

            // Календарь тренировок
            _buildTrainingCalendar(),
            const SizedBox(height: 24),

            // График веса
            _buildWeightChart(),
            const SizedBox(height: 24),

            // График кастомных измерений
            _buildCustomMeasurementsChart(),
            const SizedBox(height: 24),

            // Статистика упражнений
            _buildExerciseStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Проведено тренировок',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${_completedTrainingsCount ?? 0} шт',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Календарь проведенных тренировок',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TrainingCalendar(
          trainings: _trainings,
          onDateSelected: _onDateSelected,
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Отслеживание веса',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Поля для выбора дат
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Дата от',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_weightDateFrom != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _weightDateFrom = null;
                            });
                            _loadWeightMeasurements();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _weightDateFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _weightDateFrom = date;
                            });
                            await _loadWeightMeasurements();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: _weightDateFrom != null
                      ? '${_weightDateFrom!.day}/${_weightDateFrom!.month}/${_weightDateFrom!.year}'
                      : '',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Дата до',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_weightDateTo != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _weightDateTo = null;
                            });
                            _loadWeightMeasurements();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _weightDateTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _weightDateTo = date;
                            });
                            await _loadWeightMeasurements();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: _weightDateTo != null
                      ? '${_weightDateTo!.day}/${_weightDateTo!.month}/${_weightDateTo!.year}'
                      : '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        MeasurementChart(
          measurements: _weightMeasurements,
          measurementTypeCaption: 'Вес',
          onAddMeasurement: () => _showAddMeasurementModal('weight'),
          onViewList: () =>
              _showMeasurementListModal(_weightMeasurements, 'Вес'),
        ),
      ],
    );
  }

  Widget _buildCustomMeasurementsChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Другие замеры',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Выпадающий список типов измерений
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<MeasurementTypeModel>(
                value: _selectedCustomMeasurementType,
                decoration: const InputDecoration(
                  labelText: 'Тип измерения',
                  border: OutlineInputBorder(),
                ),
                items: _userMeasurementTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.caption),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomMeasurementType = value;
                    _customMeasurements.clear();
                  });
                  if (value != null) {
                    _loadCustomMeasurements();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => _showMeasurementTypeModal(),
              icon: const Icon(Icons.settings),
              tooltip: 'Управление типами измерений',
            ),
          ],
        ),

        if (_selectedCustomMeasurementType != null) ...[
          const SizedBox(height: 16),

          // Поля для выбора дат
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Дата от',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_customDateFrom != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _customDateFrom = null;
                              });
                              _loadCustomMeasurements();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _customDateFrom ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _customDateFrom = date;
                              });
                              await _loadCustomMeasurements();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _customDateFrom != null
                        ? '${_customDateFrom!.day}/${_customDateFrom!.month}/${_customDateFrom!.year}'
                        : '',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Дата до',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_customDateTo != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _customDateTo = null;
                              });
                              _loadCustomMeasurements();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _customDateTo ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _customDateTo = date;
                              });
                              await _loadCustomMeasurements();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: _customDateTo != null
                        ? '${_customDateTo!.day}/${_customDateTo!.month}/${_customDateTo!.year}'
                        : '',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          MeasurementChart(
            measurements: _customMeasurements,
            measurementTypeCaption: _selectedCustomMeasurementType!.caption,
            onAddMeasurement: () => _showAddMeasurementModal('custom'),
            onViewList: () => _showMeasurementListModal(
              _customMeasurements,
              _selectedCustomMeasurementType!.caption,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExerciseStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика упражнений',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<ExerciseModel>(
          value: _selectedExercise,
          decoration: const InputDecoration(
            labelText: 'Выберите упражнение',
            border: OutlineInputBorder(),
          ),
          items: _exercises.map((exercise) {
            return DropdownMenuItem(
              value: exercise,
              child: Text(exercise.caption),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedExercise = value;
              _exerciseStatistics = null;
              _isLoadingExerciseStatistics = false;
            });
            if (value != null) {
              _loadExerciseStatistics(value);
            }
          },
        ),

        if (_selectedExercise != null) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              print(
                'StatisticsScreen 🔍 Проверяем состояние: isLoading=$_isLoadingExerciseStatistics, hasData=${_exerciseStatistics != null}',
              );
              return _isLoadingExerciseStatistics
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _exerciseStatistics != null
                  ? (() {
                      print(
                        'StatisticsScreen 🔍 Отображаем ExerciseStatisticsTable',
                      );
                      return ExerciseStatisticsTable(
                        statistics: _exerciseStatistics!,
                      );
                    })()
                  : (() {
                      print(
                        'StatisticsScreen 🔍 Отображаем сообщение "Выберите упражнение"',
                      );
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Выберите упражнение для просмотра статистики',
                          ),
                        ),
                      );
                    })();
            },
          ),
        ],
      ],
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки статистики: $e')));
    }
  }

  void _showAddMeasurementModal(String type) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userUuid = authProvider.userUuid;
    if (userUuid == null) return;

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

    showDialog(
      context: context,
      builder: (context) => MeasurementModal(
        title: title,
        onSave: (date, value) async {
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Измерение добавлено')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка добавления измерения')),
            );
          }
        },
      ),
    );
  }

  void _showMeasurementListModal(
    List<MeasurementModel> measurements,
    String caption,
  ) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => MeasurementListModal(
          measurements: measurements == _weightMeasurements
              ? _weightMeasurements
              : _customMeasurements,
          measurementTypeCaption: caption,
          onEdit: (measurement) {
            Navigator.of(context).pop();
            _showEditMeasurementModal(
              measurement,
              measurements == _weightMeasurements ? 'weight' : 'custom',
            );
          },
          onDelete: (measurementUuid) async {
            final success = await StatisticsService.deleteMeasurement(
              measurementUuid,
            );
            if (success) {
              if (measurements == _weightMeasurements) {
                await _loadWeightMeasurements();
              } else {
                await _loadCustomMeasurements();
              }
              // Обновляем модальное окно
              setModalState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Измерение удалено')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка удаления измерения')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showEditMeasurementModal(MeasurementModel measurement, String type) {
    showDialog(
      context: context,
      builder: (context) => MeasurementModal(
        title: 'Редактировать измерение',
        initialDate: measurement.measurementDate,
        initialValue: measurement.value,
        onSave: (date, value) async {
          final success = await StatisticsService.updateMeasurement(
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Измерение обновлено')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка обновления измерения')),
            );
          }
        },
      ),
    );
  }

  void _showMeasurementTypeModal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => MeasurementTypeModal(
          measurementTypes: [
            ..._systemMeasurementTypes,
            ..._userMeasurementTypes,
          ],
          onAdd: (caption) async {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            final userUuid = authProvider.userUuid;
            if (userUuid == null) return;

            final success = await StatisticsService.addMeasurementType(
              userUuid: userUuid,
              caption: caption,
            );

            if (success) {
              await _loadInitialData();
              // Очищаем выбранный тип, чтобы пользователь выбрал новый
              _selectedCustomMeasurementType = null;
              // Обновляем модальное окно
              setModalState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тип измерения добавлен')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка добавления типа измерения'),
                ),
              );
            }
          },
          onEdit: (uuid, caption) async {
            final success = await StatisticsService.updateMeasurementType(
              measurementTypeUuid: uuid,
              caption: caption,
            );

            if (success) {
              await _loadInitialData();
              // Если редактировался выбранный тип, обновляем ссылку
              if (_selectedCustomMeasurementType?.uuid == uuid) {
                _selectedCustomMeasurementType = _userMeasurementTypes
                    .firstWhere(
                      (type) => type.uuid == uuid,
                      orElse: () => _selectedCustomMeasurementType!,
                    );
              }
              // Обновляем модальное окно
              setModalState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тип измерения обновлен')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка обновления типа измерения'),
                ),
              );
            }
          },
          onDelete: (uuid) async {
            final success = await StatisticsService.deleteMeasurementType(uuid);

            if (success) {
              await _loadInitialData();
              // Если удалялся выбранный тип, очищаем выбор
              if (_selectedCustomMeasurementType?.uuid == uuid) {
                _selectedCustomMeasurementType = null;
                _customMeasurements.clear();
              }
              // Обновляем модальное окно
              setModalState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тип измерения удален')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ошибка удаления типа измерения')),
              );
            }
          },
        ),
      ),
    );
  }
}
