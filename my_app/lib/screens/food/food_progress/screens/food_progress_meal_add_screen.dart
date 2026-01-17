import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/textured_background.dart';
import '../../../../widgets/metal_card.dart';
import '../../../../widgets/metal_text_field.dart';
import '../../../../widgets/metal_button.dart';
import '../../../../widgets/metal_back_button.dart';
import '../../../../design/ninja_spacing.dart';
import '../../../../design/ninja_typography.dart';
import '../models/food_progress_model.dart';
import '../services/food_progress_service.dart';

class FoodProgressMealAddScreen extends StatefulWidget {
  const FoodProgressMealAddScreen({super.key});

  @override
  State<FoodProgressMealAddScreen> createState() =>
      _FoodProgressMealAddScreenState();
}

class _FoodProgressMealAddScreenState
    extends State<FoodProgressMealAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Предзаполняем текущим временем
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  String _normalizeNumberString(String value) {
    return value.replaceAll(',', '.');
  }

  // TextInputFormatter для валидации числового ввода (целые и дробные числа с точкой или запятой)
  TextInputFormatter _numericInputFormatter() {
    return _NumericTextInputFormatter();
  }

  Future<void> _selectDateTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveMeal() async {
    // Проверка обязательного поля "Название"
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите название'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final proteins = double.tryParse(
          _normalizeNumberString(_proteinsController.text),
        );
    final fats = double.tryParse(_normalizeNumberString(_fatsController.text));
    final carbs = double.tryParse(_normalizeNumberString(_carbsController.text));

    // Проверка: хотя бы один параметр БЖУ должен быть указан
    if (proteins == null && fats == null && carbs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите хотя бы один параметр БЖУ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Рассчитываем калории по формуле
    final calories = calculateCaloriesFromMacros(
      proteins: proteins ?? 0.0,
      fats: fats ?? 0.0,
      carbs: carbs ?? 0.0,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await FoodProgressService.addMeal(
        mealDatetime: _selectedDateTime,
        name: _nameController.text.trim(),
        calories: calories,
        proteins: proteins,
        fats: fats,
        carbs: carbs,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок и кнопка назад
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: NinjaSpacing.lg,
                  vertical: NinjaSpacing.md,
                ),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text(
                        'Добавление приема пищи',
                        style: NinjaText.title,
                      ),
                    ),
                  ],
                ),
              ),
              // Контент
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(NinjaSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Дата и время
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Дата и время',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              GestureDetector(
                                onTap: _selectDateTime,
                                child: MetalTextField(
                                  controller: TextEditingController(
                                    text: dateFormat.format(_selectedDateTime),
                                  ),
                                  hint: 'Выберите дату и время',
                                  enabled: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Название
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Название',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _nameController,
                                hint: 'Введите название',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Белки
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Белки',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _proteinsController,
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_numericInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Жиры
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Жиры',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _fatsController,
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_numericInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Углеводы
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Углеводы',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _carbsController,
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_numericInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.xl),
                        MetalButton(
                          label: 'Сохранить',
                          onPressed: _isLoading ? null : _saveMeal,
                          isLoading: _isLoading,
                          height: 56,
                        ),
                      ],
                    ),
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

// Кастомный TextInputFormatter для валидации числового ввода
class _NumericTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Пустая строка разрешена
    if (text.isEmpty) {
      return newValue;
    }

    // Разрешаем только цифры, точку и запятую
    final allowedChars = RegExp(r'[0-9.,]');
    final filteredText = text.split('').where((char) => allowedChars.hasMatch(char)).join('');

    // Проверяем, что есть максимум одна точка или запятая
    final dotCount = filteredText.split('.').length - 1;
    final commaCount = filteredText.split(',').length - 1;

    if (dotCount > 1 || commaCount > 1 || (dotCount > 0 && commaCount > 0)) {
      // Если больше одной точки/запятой или обе одновременно - возвращаем старое значение
      return oldValue;
    }

    // Проверяем, что строка является валидным числом (целым или дробным)
    final normalizedText = filteredText.replaceAll(',', '.');
    if (normalizedText.isNotEmpty) {
      // Разрешаем строки вида: "123", "123.45", ".5", "0.5"
      final numberPattern = RegExp(r'^(\d+\.?\d*|\.\d+)$');
      if (!numberPattern.hasMatch(normalizedText)) {
        return oldValue;
      }
    }

    // Сохраняем позицию курсора
    int selectionOffset = newValue.selection.baseOffset;
    if (selectionOffset > filteredText.length) {
      selectionOffset = filteredText.length;
    } else if (selectionOffset < 0) {
      selectionOffset = 0;
    }

    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

