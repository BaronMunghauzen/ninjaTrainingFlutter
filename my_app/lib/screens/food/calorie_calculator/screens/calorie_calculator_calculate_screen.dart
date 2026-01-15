import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/textured_background.dart';
import '../../../../widgets/metal_card.dart';
import '../../../../widgets/metal_button.dart';
import '../../../../widgets/metal_text_field.dart';
import '../../../../widgets/metal_dropdown.dart';
import '../../../../widgets/metal_back_button.dart';
import '../../../../design/ninja_spacing.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_colors.dart';
import '../services/calorie_calculator_service.dart';
import 'calorie_calculator_result_screen.dart';

class CalorieCalculatorCalculateScreen extends StatefulWidget {
  const CalorieCalculatorCalculateScreen({super.key});

  @override
  State<CalorieCalculatorCalculateScreen> createState() =>
      _CalorieCalculatorCalculateScreenState();
}

class _CalorieCalculatorCalculateScreenState
    extends State<CalorieCalculatorCalculateScreen> {
  final _goalController = TextEditingController();
  final _genderController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _activityController = TextEditingController();

  String _selectedGoal = 'weight_loss';
  String _selectedGender = 'male';
  String _selectedActivity = '1.2';

  bool _isCalculating = false;

  final List<MetalDropdownItem<String>> _goalItems = [
    MetalDropdownItem(value: 'weight_loss', label: 'Похудение'),
    MetalDropdownItem(value: 'muscle_gain', label: 'Набор массы'),
    MetalDropdownItem(value: 'maintenance', label: 'Поддержание веса'),
  ];

  final List<MetalDropdownItem<String>> _genderItems = [
    MetalDropdownItem(value: 'male', label: 'Мужской'),
    MetalDropdownItem(value: 'female', label: 'Женский'),
  ];

  final List<MetalDropdownItem<String>> _activityItems = [
    MetalDropdownItem(value: '1.2', label: 'Сидячий'),
    MetalDropdownItem(value: '1.375', label: 'Слабая'),
    MetalDropdownItem(value: '1.55', label: 'Средняя'),
    MetalDropdownItem(value: '1.725', label: 'Высокая'),
    MetalDropdownItem(value: '1.9', label: 'Экстремальная'),
  ];

  String _getActivityDescription(String activityCoefficient) {
    switch (activityCoefficient) {
      case '1.2':
        return 'Минимальная активность, сидячая работа, отсутствие тренировок';
      case '1.375':
        return 'Легкие тренировки 1-3 раза в неделю, небольшая активность';
      case '1.55':
        return 'Умеренные тренировки 3-5 раз в неделю, средняя активность';
      case '1.725':
        return 'Интенсивные тренировки 6-7 раз в неделю, высокая активность';
      case '1.9':
        return 'Очень интенсивные тренировки, физическая работа, экстремальная активность';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _genderController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_weightController.text.isEmpty ||
        double.tryParse(_weightController.text) == null ||
        double.parse(_weightController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректный вес (больше 0)'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_heightController.text.isEmpty ||
        double.tryParse(_heightController.text) == null ||
        double.parse(_heightController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректный рост (больше 0)'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_ageController.text.isEmpty ||
        int.tryParse(_ageController.text) == null ||
        int.parse(_ageController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректный возраст (больше 0)'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _calculate() async {
    if (!_validateForm()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final result = await CalorieCalculatorService.calculate(
        goal: _selectedGoal,
        gender: _selectedGender,
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
        activityCoefficient: _selectedActivity,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              CalorieCalculatorResultScreen(calculation: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка расчета: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
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
                        'Рассчитать норму потребления',
                        style: NinjaText.title,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(NinjaSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MetalCard(
                        padding: const EdgeInsets.all(NinjaSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Цель', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.sm),
                            MetalDropdown<String>(
                              value: _selectedGoal,
                              items: _goalItems,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGoal = value;
                                });
                              },
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            Text('Пол', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.sm),
                            MetalDropdown<String>(
                              value: _selectedGender,
                              items: _genderItems,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            Text('Вес (кг)', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.sm),
                            MetalTextField(
                              controller: _weightController,
                              hint: 'Введите вес',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+[.,]?\d{0,2}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            Text('Рост (см)', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.sm),
                            MetalTextField(
                              controller: _heightController,
                              hint: 'Введите рост',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+[.,]?\d{0,2}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            Text('Возраст', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.sm),
                            MetalTextField(
                              controller: _ageController,
                              hint: 'Введите возраст',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            Text('Уровень активности', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.sm),
                            MetalDropdown<String>(
                              value: _selectedActivity,
                              items: _activityItems,
                              onChanged: (value) {
                                setState(() {
                                  _selectedActivity = value;
                                });
                              },
                            ),
                            const SizedBox(height: NinjaSpacing.xs),
                            Text(
                              _getActivityDescription(_selectedActivity),
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
                      MetalButton(
                        label: 'Рассчитать',
                        icon: Icons.calculate,
                        onPressed: _isCalculating ? null : _calculate,
                        height: 56,
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

