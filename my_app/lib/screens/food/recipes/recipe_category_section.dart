import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import '../../../widgets/metal_card.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';
import 'recipe_card_widget.dart';

class RecipeCategorySection extends StatelessWidget {
  final String category;
  final String categoryName;
  final List<Recipe> recipes;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(Recipe) onRecipeTap;
  final VoidCallback onViewMore;
  final VoidCallback? onAddRecipe;
  final VoidCallback? onAddUserRecipe;
  final VoidCallback? onRecipeDeleted;

  const RecipeCategorySection({
    super.key,
    required this.category,
    required this.categoryName,
    required this.recipes,
    required this.isExpanded,
    required this.onToggle,
    required this.onRecipeTap,
    required this.onViewMore,
    this.onAddRecipe,
    this.onAddUserRecipe,
    this.onRecipeDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final displayRecipes = recipes.take(4).toList();
    final hasMore = recipes.length > 4;

    return MetalCard(
      padding: const EdgeInsets.all(NinjaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок категории с кнопкой развернуть/свернуть
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onToggle,
                  child: Row(
                    children: [
                      Text(
                        categoryName,
                        style: NinjaText.title.copyWith(fontSize: 20),
                      ),
                      const SizedBox(width: NinjaSpacing.sm),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: NinjaColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              // Кнопки добавления рецепта
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onAddUserRecipe != null)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onAddUserRecipe,
                      color: NinjaColors.textPrimary,
                      tooltip: 'Добавить рецепт',
                    ),
                  if (onAddRecipe != null)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: onAddRecipe,
                      color: NinjaColors.textPrimary,
                      tooltip: 'Добавить рецепт (админ)',
                    ),
                ],
              ),
            ],
          ),
          // Список рецептов (если развернуто)
          if (isExpanded) ...[
            const SizedBox(height: NinjaSpacing.md),
            if (displayRecipes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(NinjaSpacing.md),
                child: Text(
                  'Нет рецептов в этой категории',
                  style: NinjaText.caption,
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - NinjaSpacing.md) / 2;
                  return Wrap(
                    spacing: NinjaSpacing.md,
                    runSpacing: NinjaSpacing.md,
                    children: displayRecipes.map((recipe) {
                      return SizedBox(
                        width: cardWidth,
                          child: RecipeCardWidget(
                            recipe: recipe,
                            onTap: () => onRecipeTap(recipe),
                            onDeleted: onRecipeDeleted,
                          ),
                      );
                    }).toList(),
                  );
                },
              ),
            // Кнопка "Смотреть еще"
            if (hasMore) ...[
              const SizedBox(height: NinjaSpacing.md),
              TextButton(
                onPressed: onViewMore,
                child: Text(
                  'Смотреть еще',
                  style: NinjaText.body.copyWith(
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

