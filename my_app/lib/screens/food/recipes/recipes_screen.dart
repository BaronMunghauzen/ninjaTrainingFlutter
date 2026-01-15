import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../widgets/metal_button.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';
import '../../../models/recipe_model.dart';
import '../../../services/recipe_service.dart';
import 'recipe_category_section.dart';
import 'recipe_category_screen.dart';
import 'recipe_detail_screen.dart';
import 'recipe_create_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  RecipesGroupedByCategoryResponse? _recipesData;
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Делаем 7 параллельных запросов для каждой категории
      final categories = [
        'breakfast',
        'lunch',
        'dinner',
        'salad',
        'snack',
        'dessert',
        'other',
      ];

      final results = await Future.wait([
        for (final category in categories)
          RecipeService.getRecipesByCategory(category: category, actual: true),
      ]);

      if (mounted) {
        setState(() {
          _recipesData = RecipesGroupedByCategoryResponse(
            breakfast: results[0],
            lunch: results[1],
            dinner: results[2],
            salad: results[3],
            snack: results[4],
            dessert: results[5],
            other: results[6],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }

  void _openRecipeDetail(Recipe recipe) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        )
        .then((_) {
          _loadRecipes();
        });
  }

  void _openCategoryScreen(String category, String categoryName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeCategoryScreen(
          category: category,
          categoryName: categoryName,
        ),
      ),
    );
  }

  void _openCreateRecipe(String category, {required bool isAdmin}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                RecipeCreateScreen(category: category, isAdmin: isAdmin),
          ),
        )
        .then((_) {
          _loadRecipes();
        });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;

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
                    Text('Рецепты', style: NinjaText.title),
                  ],
                ),
              ),
              // Контент
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            NinjaColors.textPrimary,
                          ),
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ошибка загрузки рецептов',
                              style: NinjaText.title,
                            ),
                            const SizedBox(height: NinjaSpacing.md),
                            Text(
                              _error!,
                              style: NinjaText.caption,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            MetalButton(
                              label: 'Повторить',
                              onPressed: _loadRecipes,
                              height: 48,
                            ),
                          ],
                        ),
                      )
                    : _recipesData == null
                    ? const Center(child: Text('Нет данных'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(NinjaSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Завтрак
                            RecipeCategorySection(
                              category: 'breakfast',
                              categoryName: 'Завтрак',
                              recipes: _recipesData!.breakfast,
                              isExpanded:
                                  _expandedCategories['breakfast'] ?? false,
                              onToggle: () => _toggleCategory('breakfast'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('breakfast', 'Завтрак'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'breakfast',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () => _openCreateRecipe(
                                'breakfast',
                                isAdmin: false,
                              ),
                              onRecipeDeleted: _loadRecipes,
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Обед
                            RecipeCategorySection(
                              category: 'lunch',
                              categoryName: 'Обед',
                              recipes: _recipesData!.lunch,
                              isExpanded: _expandedCategories['lunch'] ?? false,
                              onToggle: () => _toggleCategory('lunch'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('lunch', 'Обед'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'lunch',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () =>
                                  _openCreateRecipe('lunch', isAdmin: false),
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Ужин
                            RecipeCategorySection(
                              category: 'dinner',
                              categoryName: 'Ужин',
                              recipes: _recipesData!.dinner,
                              isExpanded:
                                  _expandedCategories['dinner'] ?? false,
                              onToggle: () => _toggleCategory('dinner'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('dinner', 'Ужин'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'dinner',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () =>
                                  _openCreateRecipe('dinner', isAdmin: false),
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Салаты
                            RecipeCategorySection(
                              category: 'salad',
                              categoryName: 'Салаты',
                              recipes: _recipesData!.salad,
                              isExpanded: _expandedCategories['salad'] ?? false,
                              onToggle: () => _toggleCategory('salad'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('salad', 'Салаты'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'salad',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () =>
                                  _openCreateRecipe('salad', isAdmin: false),
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Перекус
                            RecipeCategorySection(
                              category: 'snack',
                              categoryName: 'Перекус',
                              recipes: _recipesData!.snack,
                              isExpanded: _expandedCategories['snack'] ?? false,
                              onToggle: () => _toggleCategory('snack'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('snack', 'Перекус'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'snack',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () =>
                                  _openCreateRecipe('snack', isAdmin: false),
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Десерты
                            RecipeCategorySection(
                              category: 'dessert',
                              categoryName: 'Десерты',
                              recipes: _recipesData!.dessert,
                              isExpanded:
                                  _expandedCategories['dessert'] ?? false,
                              onToggle: () => _toggleCategory('dessert'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('dessert', 'Десерты'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'dessert',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () =>
                                  _openCreateRecipe('dessert', isAdmin: false),
                            ),
                            const SizedBox(height: NinjaSpacing.lg),
                            // Другое
                            RecipeCategorySection(
                              category: 'other',
                              categoryName: 'Другое',
                              recipes: _recipesData!.other,
                              isExpanded: _expandedCategories['other'] ?? false,
                              onToggle: () => _toggleCategory('other'),
                              onRecipeTap: _openRecipeDetail,
                              onViewMore: () =>
                                  _openCategoryScreen('other', 'Другое'),
                              onAddRecipe: isAdmin
                                  ? () => _openCreateRecipe(
                                      'other',
                                      isAdmin: true,
                                    )
                                  : null,
                              onAddUserRecipe: () =>
                                  _openCreateRecipe('other', isAdmin: false),
                              onRecipeDeleted: _loadRecipes,
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
