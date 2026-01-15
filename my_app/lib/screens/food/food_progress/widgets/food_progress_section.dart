import 'package:flutter/material.dart';
import '../../../../design/ninja_colors.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_spacing.dart';
import '../../../../widgets/metal_card.dart';
import '../../../../widgets/metal_button.dart';
import '../models/food_progress_model.dart';
import 'vertical_progress_scale.dart';

class FoodProgressSection extends StatelessWidget {
  final FoodProgressSummary summary;
  final VoidCallback onAddTarget;
  final VoidCallback onAddMeal;
  final VoidCallback onMealsHistory;

  const FoodProgressSection({
    super.key,
    required this.summary,
    required this.onAddTarget,
    required this.onAddMeal,
    required this.onMealsHistory,
  });

  @override
  Widget build(BuildContext context) {
    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и кнопки
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('КБЖУ за день', style: NinjaText.title),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onAddMeal,
                    color: NinjaColors.textPrimary,
                    tooltip: 'Добавить прием пищи',
                  ),
                  IconButton(
                    icon: const Icon(Icons.track_changes),
                    onPressed: onAddTarget,
                    color: NinjaColors.textPrimary,
                    tooltip: 'Добавить цель',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: NinjaSpacing.lg),
          // Прогресс-бары в виде вертикальных шкал
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              VerticalProgressScale(
                progress: summary.caloriesProgress,
                label: 'Калории',
                current: summary.eatenCalories,
                target: summary.targetCalories,
                isDecimal: true,
              ),
              VerticalProgressScale(
                progress: summary.proteinsProgress,
                label: 'Белки',
                current: summary.eatenProteins,
                target: summary.targetProteins,
                isDecimal: true,
              ),
              VerticalProgressScale(
                progress: summary.fatsProgress,
                label: 'Жиры',
                current: summary.eatenFats,
                target: summary.targetFats,
                isDecimal: true,
              ),
              VerticalProgressScale(
                progress: summary.carbsProgress,
                label: 'Углеводы',
                current: summary.eatenCarbs,
                target: summary.targetCarbs,
                isDecimal: true,
              ),
            ],
          ),
          const SizedBox(height: NinjaSpacing.lg),
          // Кнопка истории приемов пищи
          MetalButton(
            label: 'История приемов пищи',
            icon: Icons.history,
            onPressed: onMealsHistory,
            height: 48,
          ),
        ],
      ),
    );
  }
}
