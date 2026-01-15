import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/textured_background.dart';
import '../../../../widgets/metal_card.dart';
import '../../../../widgets/metal_button.dart';
import '../../../../widgets/metal_modal.dart';
import '../../../../widgets/macro_info_chip.dart';
import '../../../../design/ninja_spacing.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_colors.dart';
import '../models/calorie_calculator_model.dart';
import '../../food_progress/services/food_progress_service.dart';

class CalorieCalculatorResultScreen extends StatefulWidget {
  final CalorieCalculation calculation;

  const CalorieCalculatorResultScreen({super.key, required this.calculation});

  @override
  State<CalorieCalculatorResultScreen> createState() =>
      _CalorieCalculatorResultScreenState();
}

class _CalorieCalculatorResultScreenState
    extends State<CalorieCalculatorResultScreen> {
  bool _isAddingToTarget = false;

  Future<void> _addToTarget() async {
    final macros = widget.calculation.getMacrosForGoal();
    if (macros == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось определить макросы для цели'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Добавить в дневную цель',
      children: [
        Text(
          'Добавить рассчитанные значения в дневную цель?',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.md),
        Text(
          'Калории: ${macros.calories.toStringAsFixed(0)}\n'
          'Белки: ${macros.proteins.toStringAsFixed(1)} г\n'
          'Жиры: ${macros.fats.toStringAsFixed(1)} г\n'
          'Углеводы: ${macros.carbs.toStringAsFixed(1)} г',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Отмена', style: NinjaText.body),
            ),
            const SizedBox(width: NinjaSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Добавить', style: NinjaText.body),
            ),
          ],
        ),
      ],
    );

    if (confirmed != true) return;

    setState(() {
      _isAddingToTarget = true;
    });

    try {
      await FoodProgressService.addTarget(
        targetCalories: macros.calories,
        targetProteins: macros.proteins,
        targetFats: macros.fats,
        targetCarbs: macros.carbs,
      );

      if (!mounted) return;

      // Возвращаемся на food_screen с результатом true
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка добавления цели: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToTarget = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.calculation.getMacrosForGoal();
    final dateStr = _formatDate(widget.calculation.createdAt);

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
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      color: NinjaColors.textPrimary,
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text('Результат расчета', style: NinjaText.title),
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
                      // Дата
                      Text(
                        dateStr,
                        style: NinjaText.caption.copyWith(
                          color: NinjaColors.textSecondary.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // Информация о расчете
                      MetalCard(
                        padding: const EdgeInsets.all(NinjaSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Цель и Пол в одном ряду
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Цель', style: NinjaText.body),
                                      const SizedBox(height: NinjaSpacing.xs),
                                      Text(
                                        widget.calculation.getGoalDisplayName(),
                                        style: NinjaText.body.copyWith(
                                          color: NinjaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: NinjaSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Пол', style: NinjaText.body),
                                      const SizedBox(height: NinjaSpacing.xs),
                                      Text(
                                        widget.calculation
                                            .getGenderDisplayName(),
                                        style: NinjaText.body.copyWith(
                                          color: NinjaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.md),
                            // Вес и Возраст в одном ряду
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Вес', style: NinjaText.body),
                                      const SizedBox(height: NinjaSpacing.xs),
                                      Text(
                                        '${widget.calculation.weight.toStringAsFixed(1)} кг',
                                        style: NinjaText.body.copyWith(
                                          color: NinjaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: NinjaSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Возраст', style: NinjaText.body),
                                      const SizedBox(height: NinjaSpacing.xs),
                                      Text(
                                        '${widget.calculation.age} лет',
                                        style: NinjaText.body.copyWith(
                                          color: NinjaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.md),
                            Text('Уровень активности', style: NinjaText.body),
                            const SizedBox(height: NinjaSpacing.xs),
                            Text(
                              widget.calculation.getActivityDisplayName(),
                              style: NinjaText.body.copyWith(
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // BMR
                      MetalCard(
                        padding: const EdgeInsets.all(NinjaSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'BMR',
                                  style: NinjaText.title.copyWith(fontSize: 18),
                                ),
                                Text(
                                  widget.calculation.bmr.toStringAsFixed(0),
                                  style: NinjaText.body.copyWith(fontSize: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.xs),
                            Text(
                              'Минимальное количество энергии, которое организм тратит в состоянии покоя для поддержания жизненно важных функций',
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.textSecondary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // TDEE
                      MetalCard(
                        padding: const EdgeInsets.all(NinjaSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TDEE',
                                  style: NinjaText.title.copyWith(fontSize: 18),
                                ),
                                Text(
                                  widget.calculation.tdee.toStringAsFixed(0),
                                  style: NinjaText.body.copyWith(fontSize: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: NinjaSpacing.xs),
                            Text(
                              'Оценка общего количества калорий, которые организм сжигает в течение дня (BMR с поправкой на коэффициент активности)',
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.textSecondary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // КБЖУ для цели
                      if (macros != null) ...[
                        MetalCard(
                          padding: const EdgeInsets.all(NinjaSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.calculation.goal == 'weight_loss'
                                    ? 'КБЖУ для похудения'
                                    : widget.calculation.goal == 'muscle_gain'
                                    ? 'КБЖУ для набора массы'
                                    : 'КБЖУ для поддержания веса',
                                style: NinjaText.title.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: NinjaSpacing.md),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  MacroInfoChip(
                                    label: 'К',
                                    value: macros.calories.toStringAsFixed(0),
                                    size:
                                        widget.calculation.goal == 'weight_loss'
                                        ? 40
                                        : 32,
                                  ),
                                  MacroInfoChip(
                                    label: 'Б',
                                    value: macros.proteins.toStringAsFixed(1),
                                    size:
                                        widget.calculation.goal == 'weight_loss'
                                        ? 40
                                        : 32,
                                  ),
                                  MacroInfoChip(
                                    label: 'Ж',
                                    value: macros.fats.toStringAsFixed(1),
                                    size:
                                        widget.calculation.goal == 'weight_loss'
                                        ? 40
                                        : 32,
                                  ),
                                  MacroInfoChip(
                                    label: 'У',
                                    value: macros.carbs.toStringAsFixed(1),
                                    size:
                                        widget.calculation.goal == 'weight_loss'
                                        ? 40
                                        : 32,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                      ],

                      // Кнопки
                      Row(
                        children: [
                          Expanded(
                            child: MetalButton(
                              label: 'Добавить в дневную цель',
                              onPressed: _isAddingToTarget
                                  ? null
                                  : _addToTarget,
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: NinjaSpacing.md),
                          MetalButton(
                            label: 'Закрыть',
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            height: 48,
                          ),
                        ],
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
