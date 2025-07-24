import 'package:flutter/material.dart';
import '../../services/program_service.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProgramEditScreen extends StatefulWidget {
  final String programUuid;
  final Map<String, dynamic> initialData;

  const ProgramEditScreen({
    Key? key,
    required this.programUuid,
    required this.initialData,
  }) : super(key: key);

  @override
  State<ProgramEditScreen> createState() => _ProgramEditScreenState();
}

class _ProgramEditScreenState extends State<ProgramEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isLoading = false;

  // Сохраняем исходные значения для сравнения
  late String _originalCaption;
  late String _originalDescription;
  late int _originalDifficulty;
  late int _originalOrder;
  late bool _originalActual;
  late String _originalTrainingDays;

  // Флаг для отслеживания изменений
  bool _hasChanges = false;

  // Параметры actual и training_days
  bool _actual = false;
  final List<bool> _selectedDays = List.filled(7, false);

  final List<String> _daysOfWeek = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  @override
  void initState() {
    super.initState();
    // Заполняем поля начальными данными
    _captionController.text = widget.initialData['caption'] ?? '';
    _descriptionController.text = widget.initialData['description'] ?? '';
    _difficultyController.text = (widget.initialData['difficulty_level'] ?? 1)
        .toString();
    _orderController.text = (widget.initialData['order'] ?? 0).toString();

    // Инициализируем actual и training_days
    _actual = widget.initialData['actual'] ?? false;
    _originalActual = _actual;
    _originalTrainingDays = widget.initialData['training_days'] ?? '[]';

    // Парсим training_days и устанавливаем чекбоксы
    _parseTrainingDays(_originalTrainingDays);

    // Сохраняем исходные значения
    _originalCaption = widget.initialData['caption'] ?? '';
    _originalDescription = widget.initialData['description'] ?? '';
    _originalDifficulty = widget.initialData['difficulty_level'] ?? 1;
    _originalOrder = widget.initialData['order'] ?? 0;

    // Добавляем слушатели изменений
    _captionController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
    _difficultyController.addListener(_checkForChanges);
    _orderController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _difficultyController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  // Парсит строку training_days и устанавливает чекбоксы
  void _parseTrainingDays(String trainingDaysString) {
    try {
      final daysString = trainingDaysString
          .replaceAll('[', '')
          .replaceAll(']', '');
      if (daysString.isNotEmpty) {
        final dayNumbers = daysString
            .split(',')
            .map((e) => int.parse(e.trim()))
            .toList()
            .cast<int>();

        for (int i = 0; i < _selectedDays.length; i++) {
          _selectedDays[i] = dayNumbers.contains(i + 1);
        }
      }
    } catch (e) {
      print('Ошибка парсинга training_days: $e');
    }
  }

  // Генерирует строку training_days из выбранных дней
  String _generateTrainingDaysString() {
    final selectedDayNumbers = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDayNumbers.add(i + 1); // Дни недели с 1 до 7
      }
    }
    return selectedDayNumbers.isEmpty ? '[]' : selectedDayNumbers.toString();
  }

  // Проверка изменений в полях
  void _checkForChanges() {
    final currentCaption = _captionController.text.trim();
    final currentDescription = _descriptionController.text.trim();
    final currentDifficulty =
        int.tryParse(_difficultyController.text.trim()) ?? _originalDifficulty;
    final currentOrder =
        int.tryParse(_orderController.text.trim()) ?? _originalOrder;
    final currentTrainingDays = _generateTrainingDaysString();

    final hasChanges =
        currentCaption != _originalCaption ||
        currentDescription != _originalDescription ||
        currentDifficulty != _originalDifficulty ||
        currentOrder != _originalOrder ||
        _actual != _originalActual ||
        currentTrainingDays != _originalTrainingDays;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  // Получить только измененные параметры
  Map<String, dynamic> _getChangedParameters() {
    final changedParams = <String, dynamic>{};

    final currentCaption = _captionController.text.trim();
    final currentDescription = _descriptionController.text.trim();
    final currentDifficulty =
        int.tryParse(_difficultyController.text.trim()) ?? _originalDifficulty;
    final currentOrder =
        int.tryParse(_orderController.text.trim()) ?? _originalOrder;
    final currentTrainingDays = _generateTrainingDaysString();

    if (currentCaption != _originalCaption) {
      changedParams['caption'] = currentCaption;
    }
    if (currentDescription != _originalDescription) {
      changedParams['description'] = currentDescription;
    }
    if (currentDifficulty != _originalDifficulty) {
      changedParams['difficulty_level'] = currentDifficulty;
    }
    if (currentOrder != _originalOrder) {
      changedParams['order'] = currentOrder;
    }
    if (_actual != _originalActual) {
      changedParams['actual'] = _actual;
    }
    if (currentTrainingDays != _originalTrainingDays) {
      changedParams['training_days'] = currentTrainingDays;
    }

    return changedParams;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Проверяем, есть ли изменения
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет изменений для сохранения'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final changedParams = _getChangedParameters();
      final success = await ProgramService.updateProgramPartial(
        programUuid: widget.programUuid,
        changedParameters: changedParams,
      );

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при обновлении программы'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать программу'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Название',
                controller: _captionController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Описание',
                controller: _descriptionController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите описание' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Уровень сложности (от 1)',
                controller: _difficultyController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите уровень сложности' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Порядок/сортировка (от 0)',
                controller: _orderController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите порядок' : null,
              ),
              const SizedBox(height: 16),

              // Переключатель actual
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Активная программа',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _actual
                                  ? 'Программа активна'
                                  : 'Программа неактивна',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _actual,
                        onChanged: (value) {
                          setState(() {
                            _actual = value;
                            _checkForChanges();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Выбор дней недели
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Дни тренировок',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(7, (index) {
                        return CheckboxListTile(
                          title: Text(_daysOfWeek[index]),
                          value: _selectedDays[index],
                          onChanged: (value) {
                            setState(() {
                              _selectedDays[index] = value ?? false;
                              _checkForChanges();
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Сохранить',
                onPressed: (_isLoading || !_hasChanges) ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
