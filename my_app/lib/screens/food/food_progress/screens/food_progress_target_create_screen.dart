import 'package:flutter/material.dart';
import '../../../../widgets/textured_background.dart';
import '../../../../widgets/metal_card.dart';
import '../../../../widgets/metal_text_field.dart';
import '../../../../widgets/metal_button.dart';
import '../../../../widgets/metal_back_button.dart';
import '../../../../design/ninja_spacing.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_colors.dart';
import '../models/food_progress_model.dart';
import '../services/food_progress_service.dart';
import '../../calorie_calculator/screens/calorie_calculator_calculate_screen.dart';

class FoodProgressTargetCreateScreen extends StatefulWidget {
  const FoodProgressTargetCreateScreen({super.key});

  @override
  State<FoodProgressTargetCreateScreen> createState() =>
      _FoodProgressTargetCreateScreenState();
}

class _FoodProgressTargetCreateScreenState
    extends State<FoodProgressTargetCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _proteinsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _carbsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _proteinsController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  String _normalizeNumberString(String value) {
    return value.replaceAll(',', '.');
  }

  Future<void> _saveTarget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final proteins =
        double.tryParse(_normalizeNumberString(_proteinsController.text)) ??
        0.0;
    final fats =
        double.tryParse(_normalizeNumberString(_fatsController.text)) ?? 0.0;
    final carbs =
        double.tryParse(_normalizeNumberString(_carbsController.text)) ?? 0.0;

    if (proteins <= 0 || fats <= 0 || carbs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все поля должны быть больше нуля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Рассчитываем калории по формуле: калории = белки * 4 + жиры * 9 + углеводы * 4
    final calories = calculateCaloriesFromMacros(
      proteins: proteins,
      fats: fats,
      carbs: carbs,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      await FoodProgressService.addTarget(
        targetCalories: calories,
        targetProteins: proteins,
        targetFats: fats,
        targetCarbs: carbs,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Возвращаем true для обновления
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания цели: $e'),
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
                      child: Text('Создание цели', style: NinjaText.title),
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
                        // Информационное сообщение
                        Container(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          decoration: BoxDecoration(
                            color: NinjaColors.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.textPrimary,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'Для определения своей нормы потребления КБЖУ воспользуйтесь ',
                                ),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CalorieCalculatorCalculateScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'калькулятором',
                                      style: NinjaText.caption.copyWith(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сколько белков в день вы хотите потреблять?',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _proteinsController,
                                hint: '0',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сколько жиров в день вы хотите потреблять?',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _fatsController,
                                hint: '0',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сколько углеводов в день вы хотите потреблять?',
                                style: NinjaText.title,
                              ),
                              const SizedBox(height: NinjaSpacing.sm),
                              MetalTextField(
                                controller: _carbsController,
                                hint: '0',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.xl),
                        MetalButton(
                          label: 'Сохранить',
                          onPressed: _isLoading ? null : _saveTarget,
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
