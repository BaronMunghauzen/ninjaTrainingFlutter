import 'package:flutter/material.dart';
import '../../../design/ninja_colors.dart';
import '../../../design/ninja_gradients.dart';
import '../../../design/ninja_radii.dart';
import '../../../design/ninja_shadows.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_button.dart';
import '../../../models/food_recognition_model.dart';

class FoodRecognitionResultScreen extends StatelessWidget {
  final FoodRecognition recognition;

  const FoodRecognitionResultScreen({Key? key, required this.recognition})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: NinjaColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Результаты анализа', style: NinjaText.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: TexturedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Комментарий пользователя
                if (recognition.comment != null &&
                    recognition.comment!.isNotEmpty) ...[
                  _buildSection(
                    title: 'Комментарий пользователя',
                    child: Text(recognition.comment!, style: NinjaText.body),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),
                ],

                // Название
                _buildSection(
                  title: 'Название',
                  child: Text(
                    recognition.name,
                    style: NinjaText.title.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),

                // КБЖУ в порции
                _buildSection(
                  title: 'КБЖУ в порции',
                  child: Column(
                    children: [
                      _buildNutritionRow('Калории', recognition.caloriesTotal),
                      const SizedBox(height: NinjaSpacing.sm),
                      _buildNutritionRow('Белки', recognition.proteinsTotal),
                      const SizedBox(height: NinjaSpacing.sm),
                      _buildNutritionRow('Жиры', recognition.fatsTotal),
                      const SizedBox(height: NinjaSpacing.sm),
                      _buildNutritionRow('Углеводы', recognition.carbsTotal),
                    ],
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),

                // Вес порции
                _buildSection(
                  title: 'Вес порции',
                  child: Text(
                    '${recognition.weightG.toStringAsFixed(0)} г',
                    style: NinjaText.body,
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),

                // КБЖУ на 100 гр
                _buildSection(
                  title: 'КБЖУ на 100 гр',
                  child: Column(
                    children: [
                      _buildNutritionRow(
                        'Калории',
                        recognition.caloriesPer100g,
                      ),
                      const SizedBox(height: NinjaSpacing.sm),
                      _buildNutritionRow('Белки', recognition.proteinsPer100g),
                      const SizedBox(height: NinjaSpacing.sm),
                      _buildNutritionRow('Жиры', recognition.fatsPer100g),
                      const SizedBox(height: NinjaSpacing.sm),
                      _buildNutritionRow('Углеводы', recognition.carbsPer100g),
                    ],
                  ),
                ),
                const SizedBox(height: NinjaSpacing.lg),

                // Микронутриенты
                if (recognition.micronutrients.isNotEmpty) ...[
                  _buildSection(
                    title: 'Микронутриенты',
                    child: Column(
                      children: recognition.micronutrients
                          .map(
                            (micronutrient) =>
                                _buildMicronutrientItem(micronutrient),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),
                ],

                // Ингредиенты
                if (recognition.ingredients.isNotEmpty) ...[
                  _buildSection(
                    title: 'Ингредиенты',
                    child: Column(
                      children: recognition.ingredients
                          .map((ingredient) => _buildIngredientItem(ingredient))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),
                ],

                // Советы/рекомендации/альтернативы
                if ((recognition.recommendationsTip != null &&
                        recognition.recommendationsTip!.isNotEmpty) ||
                    (recognition.recommendationsAlternative != null &&
                        recognition
                            .recommendationsAlternative!
                            .isNotEmpty)) ...[
                  _buildSection(
                    title: 'Советы/рекомендации/альтернативы',
                    child: Column(
                      children: [
                        if (recognition.recommendationsTip != null)
                          ...recognition.recommendationsTip!.map(
                            (rec) => _buildRecommendationItem(rec),
                          ),
                        if (recognition.recommendationsAlternative != null)
                          ...recognition.recommendationsAlternative!.map(
                            (rec) => _buildRecommendationItem(rec),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),
                ],

                // Кнопка закрыть
                MetalButton(
                  label: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                  height: 56,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(NinjaSpacing.lg),
      decoration: BoxDecoration(
        gradient: NinjaGradients.metalSoft,
        borderRadius: BorderRadius.circular(NinjaRadii.sm),
        boxShadow: NinjaShadows.card,
        border: Border.all(color: NinjaColors.metalEdgeSoft, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NinjaText.title.copyWith(fontSize: 18)),
          const SizedBox(height: NinjaSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: NinjaText.body.copyWith(color: NinjaColors.textSecondary),
        ),
        Text(
          value.toStringAsFixed(1),
          style: NinjaText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMicronutrientItem(Micronutrient micronutrient) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NinjaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${micronutrient.name} - ${micronutrient.amount.toStringAsFixed(1)} ${micronutrient.unit}',
            style: NinjaText.body,
          ),
          const SizedBox(height: NinjaSpacing.sm),
          // Шкала процента от дневной нормы
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: NinjaColors.metalDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (micronutrient.percentOfDailyValue / 100).clamp(
                  0.0,
                  1.0,
                ),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: NinjaColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NinjaSpacing.xs),
          Text(
            '${micronutrient.percentOfDailyValue.toStringAsFixed(1)}% от дневной нормы потребления',
            style: NinjaText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(Ingredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: NinjaSpacing.md),
      padding: const EdgeInsets.all(NinjaSpacing.md),
      decoration: BoxDecoration(
        gradient: NinjaGradients.metalSoft,
        borderRadius: BorderRadius.circular(NinjaRadii.xs),
        border: Border.all(color: NinjaColors.metalEdgeSoft, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ingredient.name,
            style: NinjaText.body.copyWith(fontWeight: FontWeight.bold),
          ),
          if (ingredient.description != null) ...[
            const SizedBox(height: NinjaSpacing.xs),
            Text(ingredient.description!, style: NinjaText.caption),
          ],
          const SizedBox(height: NinjaSpacing.sm),
          Text(
            'Вес в порции: ${ingredient.weightInPortionG.toStringAsFixed(0)} г',
            style: NinjaText.caption,
          ),
          const SizedBox(height: NinjaSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutritionBadge('К', ingredient.caloriesInPortion),
              _buildNutritionBadge('Б', ingredient.proteinsInPortion),
              _buildNutritionBadge('Ж', ingredient.fatsInPortion),
              _buildNutritionBadge('У', ingredient.carbsInPortion),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Recommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: NinjaSpacing.md),
      padding: const EdgeInsets.all(NinjaSpacing.md),
      decoration: BoxDecoration(
        gradient: NinjaGradients.metalSoft,
        borderRadius: BorderRadius.circular(NinjaRadii.xs),
        border: Border.all(color: NinjaColors.metalEdgeSoft, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.title,
            style: NinjaText.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: NinjaSpacing.xs),
          Text(recommendation.description, style: NinjaText.caption),
        ],
      ),
    );
  }

  Widget _buildNutritionBadge(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NinjaSpacing.sm,
        vertical: NinjaSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: NinjaGradients.metalVertical,
        borderRadius: BorderRadius.circular(NinjaRadii.xs),
        boxShadow: NinjaShadows.button,
        border: Border.all(color: NinjaColors.metalEdgeSoft, width: 0.5),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NinjaRadii.xs),
                gradient: NinjaGradients.highlightTop,
              ),
            ),
          ),
          Text(
            '$label ${value.toStringAsFixed(1)}',
            style: NinjaText.chip.copyWith(color: NinjaColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
