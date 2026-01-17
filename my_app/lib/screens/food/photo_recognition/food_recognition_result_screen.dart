import 'package:flutter/material.dart';
import '../../../design/ninja_colors.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_button.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../widgets/metal_list_item.dart';
import '../../../widgets/metal_modal.dart';
import '../../../widgets/metal_message.dart';
import '../../../widgets/macro_info_chip.dart';
import '../../../models/food_recognition_model.dart';
import '../../food/food_progress/services/food_progress_service.dart';

class FoodRecognitionResultScreen extends StatefulWidget {
  final FoodRecognition recognition;

  const FoodRecognitionResultScreen({Key? key, required this.recognition})
    : super(key: key);

  @override
  State<FoodRecognitionResultScreen> createState() =>
      _FoodRecognitionResultScreenState();
}

class _FoodRecognitionResultScreenState
    extends State<FoodRecognitionResultScreen> {
  bool _isAdding = false;

  void _showAddToMealsConfirmation() {
    MetalModal.show(
      context: context,
      title: 'Добавить в дневник?',
      children: [
        Text(
          'Добавить "${widget.recognition.name}" в дневник?',
          style: NinjaText.body,
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
              onPressed: () {
                Navigator.of(context).pop();
                _addToMeals();
              },
              child: Text('Добавить', style: NinjaText.body),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addToMeals() async {
    setState(() {
      _isAdding = true;
    });

    try {
      // Используем текущие дату и время
      final mealDatetime = DateTime.now();

      await FoodProgressService.addMeal(
        mealDatetime: mealDatetime,
        name: widget.recognition.name,
        calories: widget.recognition.caloriesTotal,
        proteins: widget.recognition.proteinsTotal,
        fats: widget.recognition.fatsTotal,
        carbs: widget.recognition.carbsTotal,
      );

      if (mounted) {
        setState(() {
          _isAdding = false;
        });
        MetalMessage.show(
          context: context,
          message: 'Запись успешно добавлена в дневник питания',
          type: MetalMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления в дневник питания: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
              // Кастомный заголовок с фоном как у экрана
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NinjaSpacing.lg,
                  vertical: NinjaSpacing.md,
                ),
                child: Row(
                  children: [
                    MetalBackButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    Text('Результаты анализа', style: NinjaText.title),
                  ],
                ),
              ),
              // Контент
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(NinjaSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Комментарий пользователя
                      if (widget.recognition.comment != null &&
                          widget.recognition.comment!.isNotEmpty) ...[
                        _buildSection(
                          title: 'Комментарий пользователя',
                          child: Text(
                            widget.recognition.comment!,
                            style: NinjaText.body,
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                      ],

                      // Название
                      _buildSection(
                        title: 'Название',
                        child: Text(
                          widget.recognition.name,
                          style: NinjaText.title.copyWith(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // КБЖУ в порции
                      _buildSection(
                        title: 'КБЖУ в порции',
                        child: Column(
                          children: [
                            _buildNutritionRow(
                              'Калории',
                              widget.recognition.caloriesTotal,
                            ),
                            const SizedBox(height: NinjaSpacing.sm),
                            _buildNutritionRow(
                              'Белки',
                              widget.recognition.proteinsTotal,
                            ),
                            const SizedBox(height: NinjaSpacing.sm),
                            _buildNutritionRow(
                              'Жиры',
                              widget.recognition.fatsTotal,
                            ),
                            const SizedBox(height: NinjaSpacing.sm),
                            _buildNutritionRow(
                              'Углеводы',
                              widget.recognition.carbsTotal,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // Вес порции
                      _buildSection(
                        title: 'Вес порции',
                        child: Text(
                          '${widget.recognition.weightG.toStringAsFixed(0)} г',
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
                              widget.recognition.caloriesPer100g,
                            ),
                            const SizedBox(height: NinjaSpacing.sm),
                            _buildNutritionRow(
                              'Белки',
                              widget.recognition.proteinsPer100g,
                            ),
                            const SizedBox(height: NinjaSpacing.sm),
                            _buildNutritionRow(
                              'Жиры',
                              widget.recognition.fatsPer100g,
                            ),
                            const SizedBox(height: NinjaSpacing.sm),
                            _buildNutritionRow(
                              'Углеводы',
                              widget.recognition.carbsPer100g,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // Микронутриенты
                      if (widget.recognition.micronutrients.isNotEmpty) ...[
                        _buildSection(
                          title: 'Микронутриенты',
                          child: Column(
                            children: widget.recognition.micronutrients
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
                      if (widget.recognition.ingredients.isNotEmpty) ...[
                        _buildSection(
                          title: 'Ингредиенты',
                          child: Column(
                            children: widget.recognition.ingredients
                                .map(
                                  (ingredient) =>
                                      _buildIngredientItem(ingredient),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                      ],

                      // Советы/рекомендации/альтернативы
                      if ((widget.recognition.recommendationsTip != null &&
                              widget
                                  .recognition
                                  .recommendationsTip!
                                  .isNotEmpty) ||
                          (widget.recognition.recommendationsAlternative !=
                                  null &&
                              widget
                                  .recognition
                                  .recommendationsAlternative!
                                  .isNotEmpty)) ...[
                        _buildSection(
                          title: 'Советы/рекомендации/альтернативы',
                          child: Column(
                            children: [
                              if (widget.recognition.recommendationsTip != null)
                                ...widget.recognition.recommendationsTip!.map(
                                  (rec) => _buildRecommendationItem(rec),
                                ),
                              if (widget
                                      .recognition
                                      .recommendationsAlternative !=
                                  null)
                                ...widget
                                    .recognition
                                    .recommendationsAlternative!
                                    .map(
                                      (rec) => _buildRecommendationItem(rec),
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
                              label: 'Добавить в дневник',
                              onPressed: _isAdding
                                  ? null
                                  : _showAddToMealsConfirmation,
                              isLoading: _isAdding,
                              height: 56,
                            ),
                          ),
                          const SizedBox(width: NinjaSpacing.md),
                          Expanded(
                            child: MetalButton(
                              label: 'Закрыть',
                              onPressed: () => Navigator.of(context).pop(),
                              height: 56,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: NinjaSpacing.xl),
                      // Предупреждение об ИИ
                      Container(
                        padding: const EdgeInsets.all(NinjaSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.withOpacity(0.8),
                              size: 20,
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Text(
                                'Результат сканирования фото - это анализ искусственного интеллекта и может быть неверным. Пожалуйста, проверьте данные перед добавлением в дневник питания.',
                                style: NinjaText.caption.copyWith(
                                  color: Colors.orange.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),
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

  Widget _buildSection({required String title, required Widget child}) {
    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.lg),
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
    return MetalListItem(
      leading: const SizedBox.shrink(),
      title: Text(
        ingredient.name,
        style: NinjaText.body.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: NinjaSpacing.md),
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
          Wrap(
            spacing: NinjaSpacing.sm,
            runSpacing: NinjaSpacing.xs,
            children: [
              MacroInfoChip(
                label: 'К',
                value: ingredient.caloriesInPortion.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'Б',
                value: ingredient.proteinsInPortion.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'Ж',
                value: ingredient.fatsInPortion.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'У',
                value: ingredient.carbsInPortion.toStringAsFixed(1),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: NinjaSpacing.md),
        ],
      ),
      onTap: () {}, // Пустой callback, так как элемент не кликабельный
    );
  }

  Widget _buildRecommendationItem(Recommendation recommendation) {
    return MetalListItem(
      leading: const SizedBox.shrink(),
      title: Text(
        recommendation.title,
        style: NinjaText.body.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: NinjaSpacing.md),
          Text(recommendation.description, style: NinjaText.caption),
          const SizedBox(height: NinjaSpacing.md),
        ],
      ),
      onTap: () {}, // Пустой callback, так как элемент не кликабельный
    );
  }
}
