import 'package:flutter/material.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ProgramCreateScreen extends StatefulWidget {
  const ProgramCreateScreen({Key? key}) : super(key: key);

  @override
  State<ProgramCreateScreen> createState() => _ProgramCreateScreenState();
}

class _ProgramCreateScreenState extends State<ProgramCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isLoading = false;

  // Параметры actual и training_days
  bool _actual = false; // По умолчанию выключен
  final List<bool> _selectedDays = List.filled(7, false); // 7 дней недели

  final List<String> _daysOfWeek = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  // Генерирует строку training_days из выбранных дней
  String _generateTrainingDaysString() {
    final selectedDayNumbers = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDayNumbers.add(i + 1); // Дни недели с 1 до 7
      }
    }
    // Возвращаем JSON-совместимую строку
    if (selectedDayNumbers.isEmpty) {
      return '[]';
    } else {
      return '[' + selectedDayNumbers.join(',') + ']';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    // Дополнительная проверка данных
    final caption = _captionController.text.trim();
    final description = _descriptionController.text.trim();
    final difficultyLevel =
        int.tryParse(_difficultyController.text.trim()) ?? 1;
    final order = int.tryParse(_orderController.text.trim()) ?? 0;

    if (caption.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      // Логируем данные перед отправкой
      print('Creating program with data:');
      print('  caption: $caption');
      print('  description: $description');
      print('  difficultyLevel: $difficultyLevel');
      print('  order: $order');
      print('  actual: $_actual');
      print('  programType: system');
      print('  scheduleType: weekly');
      print('  trainingDays: ${_generateTrainingDaysString()}');
      print('  weeksCount: 1');
      print('  imageUrl: (empty)');

      final success = await ProgramService.createProgram(
        actual: _actual,
        programType: 'system',
        caption: caption,
        description: description,
        difficultyLevel: difficultyLevel,
        order: order,
        scheduleType: 'weekly',
        trainingDays: _generateTrainingDaysString(),
        weeksCount: 1, // Добавляем обязательный параметр
        imageUrl: '', // Добавляем обязательный параметр
      );
      if (success) {
        // Возвращаемся к списку программ и обновляем его
        Navigator.of(context).pop(true);
      } else {
        print('Program creation failed - success returned false');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ошибка при создании программы. Проверьте логи для деталей.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Exception during program creation: $e');
      print('Exception type: ${e.runtimeType}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Исключение при создании программы: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
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
      appBar: AppBar(title: const Text('Создать программу')),
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
                text: 'Добавить',
                onPressed: _isLoading ? null : _submit,
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
