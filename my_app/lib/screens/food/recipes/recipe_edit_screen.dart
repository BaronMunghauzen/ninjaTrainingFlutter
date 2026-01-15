import 'package:flutter/material.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/metal_text_field.dart';
import '../../../widgets/metal_button.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';
import '../../../models/recipe_model.dart';
import '../../../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class RecipeEditScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isAdmin;

  const RecipeEditScreen({
    super.key,
    required this.recipe,
    required this.isAdmin,
  });

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _recipeController;
  late final TextEditingController _caloriesPer100gController;
  late final TextEditingController _proteinsPer100gController;
  late final TextEditingController _fatsPer100gController;
  late final TextEditingController _carbsPer100gController;
  late final TextEditingController _caloriesPerPortionController;
  late final TextEditingController _proteinsPerPortionController;
  late final TextEditingController _fatsPerPortionController;
  late final TextEditingController _carbsPerPortionController;
  late final TextEditingController _portionsCountController;
  late final TextEditingController _cookingTimeController;

  late List<MapEntry<String, String>> _ingredients;
  final List<TextEditingController> _ingredientNameControllers = [];
  final List<TextEditingController> _ingredientAmountControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _recipeController = TextEditingController(text: widget.recipe.recipe);
    _caloriesPer100gController = TextEditingController(
      text: widget.recipe.caloriesPer100g.toStringAsFixed(1),
    );
    _proteinsPer100gController = TextEditingController(
      text: widget.recipe.proteinsPer100g.toStringAsFixed(1),
    );
    _fatsPer100gController = TextEditingController(
      text: widget.recipe.fatsPer100g.toStringAsFixed(1),
    );
    _carbsPer100gController = TextEditingController(
      text: widget.recipe.carbsPer100g.toStringAsFixed(1),
    );
    _caloriesPerPortionController = TextEditingController(
      text: widget.recipe.caloriesPerPortion.toStringAsFixed(1),
    );
    _proteinsPerPortionController = TextEditingController(
      text: widget.recipe.proteinsPerPortion.toStringAsFixed(1),
    );
    _fatsPerPortionController = TextEditingController(
      text: widget.recipe.fatsPerPortion.toStringAsFixed(1),
    );
    _carbsPerPortionController = TextEditingController(
      text: widget.recipe.carbsPerPortion.toStringAsFixed(1),
    );
    _portionsCountController = TextEditingController(
      text: widget.recipe.portionsCount.toString(),
    );
    _cookingTimeController = TextEditingController(
      text: widget.recipe.cookingTime.toString(),
    );
    _ingredients = widget.recipe.ingredients.entries.toList();
    
    // Инициализируем контроллеры для существующих ингредиентов
    for (int i = 0; i < _ingredients.length; i++) {
      final entry = _ingredients[i];
      final nameController = TextEditingController(text: entry.key);
      final amountController = TextEditingController(text: entry.value);
      _ingredientNameControllers.add(nameController);
      _ingredientAmountControllers.add(amountController);
      
      final index = i;
      nameController.addListener(() {
        _updateIngredient(index, nameController.text, amountController.text);
      });
      amountController.addListener(() {
        _updateIngredient(index, nameController.text, amountController.text);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recipeController.dispose();
    _caloriesPer100gController.dispose();
    _proteinsPer100gController.dispose();
    _fatsPer100gController.dispose();
    _carbsPer100gController.dispose();
    _caloriesPerPortionController.dispose();
    _proteinsPerPortionController.dispose();
    _fatsPerPortionController.dispose();
    _carbsPerPortionController.dispose();
    _portionsCountController.dispose();
    _cookingTimeController.dispose();
    for (final controller in _ingredientNameControllers) {
      controller.dispose();
    }
    for (final controller in _ingredientAmountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(const MapEntry('', ''));
      final nameController = TextEditingController();
      final amountController = TextEditingController();
      _ingredientNameControllers.add(nameController);
      _ingredientAmountControllers.add(amountController);

      final index = _ingredients.length - 1;
      nameController.addListener(() {
        _updateIngredient(index, nameController.text, amountController.text);
      });
      amountController.addListener(() {
        _updateIngredient(index, nameController.text, amountController.text);
      });
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _ingredientNameControllers[index].dispose();
      _ingredientAmountControllers[index].dispose();
      _ingredientNameControllers.removeAt(index);
      _ingredientAmountControllers.removeAt(index);
    });
  }

  void _updateIngredient(int index, String name, String amount) {
    if (index < _ingredients.length) {
      setState(() {
        _ingredients[index] = MapEntry(name, amount);
      });
    }
  }

  String _normalizeNumberString(String value) {
    return value.replaceAll(',', '.');
  }

  Future<void> _saveRecipe() async {
    // Проверка названия
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название рецепта'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Проверка ингредиентов
    final ingredientsMap = <String, String>{};
    for (final entry in _ingredients) {
      if (entry.key.isNotEmpty && entry.value.isNotEmpty) {
        ingredientsMap[entry.key] = entry.value;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userUuid = widget.recipe.userUuid;

      final recipe = await RecipeService.updateRecipe(
        recipeUuid: widget.recipe.uuid,
        category: widget.recipe.category,
        name: _nameController.text.trim(),
        ingredients: ingredientsMap,
        recipe: _recipeController.text.trim(),
        caloriesPer100g: double.tryParse(_normalizeNumberString(_caloriesPer100gController.text)) ?? 0.0,
        proteinsPer100g: double.tryParse(_normalizeNumberString(_proteinsPer100gController.text)) ?? 0.0,
        fatsPer100g: double.tryParse(_normalizeNumberString(_fatsPer100gController.text)) ?? 0.0,
        carbsPer100g: double.tryParse(_normalizeNumberString(_carbsPer100gController.text)) ?? 0.0,
        caloriesPerPortion: double.tryParse(_normalizeNumberString(_caloriesPerPortionController.text)) ?? 0.0,
        proteinsPerPortion: double.tryParse(_normalizeNumberString(_proteinsPerPortionController.text)) ?? 0.0,
        fatsPerPortion: double.tryParse(_normalizeNumberString(_fatsPerPortionController.text)) ?? 0.0,
        carbsPerPortion: double.tryParse(_normalizeNumberString(_carbsPerPortionController.text)) ?? 0.0,
        portionsCount: int.tryParse(_normalizeNumberString(_portionsCountController.text)) ?? 1,
        cookingTime: int.tryParse(_normalizeNumberString(_cookingTimeController.text)) ?? 0,
        userUuid: userUuid,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления рецепта: $e'),
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
    final categoryName = widget.recipe.categoryDisplayName;

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
                        'Редактировать рецепт - $categoryName',
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
                  // Категория (неактивное поле)
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Категория',
                          style: NinjaText.title,
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        MetalTextField(
                          controller: TextEditingController(text: categoryName),
                          hint: categoryName,
                          enabled: false,
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
                          hint: 'Введите название рецепта',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // Ингредиенты
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ингредиенты',
                              style: NinjaText.title,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addIngredient,
                              color: NinjaColors.textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        ...List.generate(_ingredients.length, (index) {
                          // Используем сохраненные контроллеры
                          final nameController = _ingredientNameControllers[index];
                          final amountController = _ingredientAmountControllers[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: NinjaSpacing.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: MetalTextField(
                                    controller: nameController,
                                    hint: 'Название ингредиента',
                                  ),
                                ),
                                const SizedBox(width: NinjaSpacing.sm),
                                Expanded(
                                  child: MetalTextField(
                                    controller: amountController,
                                    hint: 'Количество',
                                  ),
                                ),
                                const SizedBox(width: NinjaSpacing.sm),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => _removeIngredient(index),
                                  color: NinjaColors.textSecondary,
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_ingredients.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(NinjaSpacing.md),
                            child: Text(
                              'Нажмите + чтобы добавить ингредиент',
                              style: NinjaText.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // Рецепт
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Рецепт',
                          style: NinjaText.title,
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        MetalTextField(
                          controller: _recipeController,
                          hint: 'Опишите процесс приготовления',
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // КБЖУ на 1 порцию
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'КБЖУ на 1 порцию',
                          style: NinjaText.title,
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Калории', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _caloriesPerPortionController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Белки', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _proteinsPerPortionController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Жиры', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _fatsPerPortionController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Углеводы', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _carbsPerPortionController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // КБЖУ на 100 грамм
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'КБЖУ на 100 грамм',
                          style: NinjaText.title,
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Калории', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _caloriesPer100gController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Белки', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _proteinsPer100gController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Жиры', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _fatsPer100gController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Углеводы', style: NinjaText.caption),
                                  const SizedBox(height: NinjaSpacing.xs),
                                  MetalTextField(
                                    controller: _carbsPer100gController,
                                    hint: '0',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // На сколько порций рассчитан рецепт
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'На сколько порций рассчитан рецепт',
                          style: NinjaText.title,
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        MetalTextField(
                          controller: _portionsCountController,
                          hint: '1',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // Время приготовления
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Время приготовления (минуты)',
                          style: NinjaText.title,
                        ),
                        const SizedBox(height: NinjaSpacing.sm),
                        MetalTextField(
                          controller: _cookingTimeController,
                          hint: '0',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NinjaSpacing.lg),

                  // Кнопка сохранения
                  MetalButton(
                    label: 'Сохранить',
                    onPressed: _isLoading ? null : _saveRecipe,
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

