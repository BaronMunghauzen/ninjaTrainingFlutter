import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/recipe_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/auth_image_widget.dart';
import '../../../widgets/macro_info_chip.dart';
import '../../../widgets/metal_modal.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';
import '../../../services/recipe_service.dart';
import '../../../screens/food/food_progress/services/food_progress_service.dart';
import 'recipe_edit_screen.dart';

class RecipeCardWidget extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onDeleted;

  const RecipeCardWidget({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onDeleted,
  });

  @override
  State<RecipeCardWidget> createState() => _RecipeCardWidgetState();
}

class _RecipeCardWidgetState extends State<RecipeCardWidget> {
  late bool _isFavorite;
  bool _isTogglingFavorite = false;
  bool _isAddingToMeal = false;
  int _selectedPortions = 1;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // Инициализируем состояние избранного из модели рецепта
    _isFavorite = widget.recipe.isFavorite;
    _selectedPortions = 1; // По умолчанию всегда 1
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      bool success;
      if (_isFavorite) {
        success = await RecipeService.removeFromFavorites(widget.recipe.uuid);
      } else {
        success = await RecipeService.addToFavorites(widget.recipe.uuid);
      }

      if (mounted && success) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isTogglingFavorite = false;
        });
      } else if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка изменения статуса избранного'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMenuDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;
    final isUserRecipe = widget.recipe.userUuid != null;
    final canEdit =
        isAdmin ||
        (isUserRecipe && userProfile?.uuid == widget.recipe.userUuid);
    final canDelete =
        isUserRecipe &&
        (isAdmin || userProfile?.uuid == widget.recipe.userUuid);

    MetalModal.show(
      context: context,
      title: 'Действия',
      children: [
        _buildMenuItem(
          icon: Icons.restaurant,
          title: 'Добавить в приемы пищи',
          color: NinjaColors.textPrimary,
          onTap: () {
            Navigator.of(context).pop();
            _showAddToMealConfirmation();
          },
        ),
        if (canEdit)
          _buildMenuItem(
            icon: Icons.edit,
            title: 'Редактировать',
            color: NinjaColors.textPrimary,
            onTap: () {
              Navigator.of(context).pop();
              _openEditRecipe();
            },
          ),
        if (canDelete)
          _buildMenuItem(
            icon: Icons.delete,
            title: 'Удалить',
            color: Colors.red,
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation();
            },
          ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NinjaSpacing.md,
          vertical: NinjaSpacing.md,
        ),
        margin: const EdgeInsets.only(bottom: NinjaSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: NinjaSpacing.md),
            Expanded(
              child: Text(title, style: NinjaText.body.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditRecipe() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;
    final isUserRecipe = widget.recipe.userUuid != null;
    final useAdminForm = isAdmin && !isUserRecipe;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                RecipeEditScreen(recipe: widget.recipe, isAdmin: useAdminForm),
          ),
        )
        .then((_) {
          if (widget.onDeleted != null) {
            widget.onDeleted!();
          }
        });
  }

  void _showDeleteConfirmation() {
    MetalModal.show(
      context: context,
      title: 'Удалить рецепт?',
      children: [
        Text(
          'Вы уверены, что хотите удалить этот рецепт? Это действие нельзя отменить.',
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
                _deleteRecipe();
              },
              child: Text(
                'Удалить',
                style: NinjaText.body.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteRecipe() async {
    try {
      await RecipeService.deleteRecipe(widget.recipe.uuid);
      if (mounted) {
        if (widget.onDeleted != null) {
          widget.onDeleted!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления рецепта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddToMealConfirmation() {
    _selectedPortions = 1; // Сбрасываем на 1 при открытии
    MetalModal.show(
      context: context,
      title: 'Добавить в приемы пищи',
      children: [
        Text(
          'Добавить "${widget.recipe.name}" в приемы пищи?',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.lg),
        // Выбор порций
        Row(
          children: [
            Text(
              'Порций',
              style: NinjaText.body.copyWith(color: NinjaColors.textSecondary),
            ),
            const SizedBox(width: NinjaSpacing.sm),
            CompositedTransformTarget(
              key: _dropdownKey,
              link: _layerLink,
              child: GestureDetector(
                onTap: () {
                  if (_overlayEntry == null) {
                    _showPortionsMenu(context);
                  } else {
                    _hidePortionsMenu();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_selectedPortions', style: NinjaText.body),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: NinjaSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                _hidePortionsMenu();
                Navigator.of(context).pop();
              },
              child: Text('Отмена', style: NinjaText.body),
            ),
            const SizedBox(width: NinjaSpacing.md),
            TextButton(
              onPressed: _isAddingToMeal
                  ? null
                  : () {
                      _hidePortionsMenu();
                      Navigator.of(context).pop();
                      _addToMeal();
                    },
              child: Text('Добавить', style: NinjaText.body),
            ),
          ],
        ),
      ],
    );
  }

  void _showPortionsMenu(BuildContext context) {
    final RenderBox? renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          final RenderBox? retryRenderBox =
              _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
          if (retryRenderBox != null && retryRenderBox.attached) {
            _showPortionsMenu(context);
          }
        }
      });
      return;
    }

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hidePortionsMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 80,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, renderBox.size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: 15,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade700,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final value = index + 1;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedPortions = value;
                          });
                          _hidePortionsMenu();
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: Text('$value', style: NinjaText.body),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePortionsMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _addToMeal() async {
    setState(() {
      _isAddingToMeal = true;
    });

    try {
      // Умножаем КБЖУ на количество порций
      final calories = widget.recipe.caloriesPerPortion * _selectedPortions;
      final proteins = widget.recipe.proteinsPerPortion * _selectedPortions;
      final fats = widget.recipe.fatsPerPortion * _selectedPortions;
      final carbs = widget.recipe.carbsPerPortion * _selectedPortions;

      // Используем текущее время
      final mealDatetime = DateTime.now();

      await FoodProgressService.addMeal(
        mealDatetime: mealDatetime,
        name: widget.recipe.name,
        calories: calories,
        proteins: proteins,
        fats: fats,
        carbs: carbs,
      );

      if (mounted) {
        setState(() {
          _isAddingToMeal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingToMeal = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;
    final isUserRecipe = widget.recipe.userUuid != null;
    final canEdit =
        isAdmin ||
        (isUserRecipe && userProfile?.uuid == widget.recipe.userUuid);
    final canDelete =
        isUserRecipe &&
        (isAdmin || userProfile?.uuid == widget.recipe.userUuid);
    final showMenu = canEdit || canDelete;

    return GestureDetector(
      onTap: widget.onTap,
      child: MetalCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: widget.recipe.imageUuid != null
                    ? AuthImageWidget(
                        imageUuid: widget.recipe.imageUuid,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.restaurant,
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // Контент
            Padding(
              padding: const EdgeInsets.all(NinjaSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Время приготовления, избранное и меню
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '~${widget.recipe.cookingTime} мин',
                          style: NinjaText.caption.copyWith(
                            color: NinjaColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Иконка избранного
                          GestureDetector(
                            onTap: _isTogglingFavorite ? null : _toggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _isTogglingFavorite
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              NinjaColors.textSecondary,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18,
                                      color: _isFavorite
                                          ? Colors.red
                                          : NinjaColors.textSecondary,
                                    ),
                            ),
                          ),
                          // Меню (три точки)
                          if (showMenu)
                            GestureDetector(
                              onTap: () {
                                _showMenuDialog();
                              },
                              child: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Название
                  Text(
                    widget.recipe.name,
                    style: NinjaText.title.copyWith(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // КБЖУ в порции
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      MacroInfoChip(
                        label: 'К',
                        value: widget.recipe.caloriesPerPortion.toStringAsFixed(
                          1,
                        ),
                        size: 36,
                      ),
                      MacroInfoChip(
                        label: 'Б',
                        value: widget.recipe.proteinsPerPortion.toStringAsFixed(
                          1,
                        ),
                        size: 36,
                      ),
                      MacroInfoChip(
                        label: 'Ж',
                        value: widget.recipe.fatsPerPortion.toStringAsFixed(1),
                        size: 36,
                      ),
                      MacroInfoChip(
                        label: 'У',
                        value: widget.recipe.carbsPerPortion.toStringAsFixed(1),
                        size: 36,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
