import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/metal_list_item.dart';
import '../../../widgets/auth_image_widget.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../widgets/macro_info_chip.dart';
import '../../../widgets/metal_modal.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';
import '../../../models/recipe_model.dart';
import '../../../services/recipe_service.dart';
import '../../../services/api_service.dart';
import 'recipe_edit_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _selectedPortions = 1;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Recipe? _currentRecipe;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _selectedPortions = widget.recipe.portionsCount;
    _currentRecipe = widget.recipe;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showPortionsMenu(BuildContext context) {
    final RenderBox? renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      // Попробуем еще раз после небольшой задержки
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
          // Фон для закрытия меню при клике вне его
          Positioned.fill(
            child: GestureDetector(
              onTap: _hidePortionsMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Само меню
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
                          height: 32, // Компактная высота
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

  Future<void> _showImageActionDialog() async {
    if (_isUploadingImage) return;

    // Проверка прав доступа
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;
    final isUserRecipe = _currentRecipe?.userUuid != null;
    final canManageImage =
        isAdmin ||
        (isUserRecipe && userProfile?.uuid == _currentRecipe?.userUuid);

    if (!canManageImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Вы можете управлять изображением только для своих рецептов',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final action = await MetalModal.show<String>(
      context: context,
      title: 'Действие с изображением',
      children: [
        if (_currentRecipe?.imageUuid != null)
          GestureDetector(
            onTap: () => Navigator.of(context).pop('delete'),
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
                  const Icon(Icons.delete, color: Colors.red, size: 24),
                  const SizedBox(width: NinjaSpacing.md),
                  Expanded(
                    child: Text(
                      'Удалить изображение',
                      style: NinjaText.body.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop('upload'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NinjaSpacing.md,
              vertical: NinjaSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_photo_alternate,
                  color: NinjaColors.textPrimary,
                  size: 24,
                ),
                const SizedBox(width: NinjaSpacing.md),
                Expanded(
                  child: Text(
                    _currentRecipe?.imageUuid != null
                        ? 'Заменить изображение'
                        : 'Добавить изображение',
                    style: NinjaText.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (action == 'delete') {
      await _deleteImage();
    } else if (action == 'upload') {
      await _uploadImage();
    }
  }

  Future<void> _deleteImage() async {
    if (_currentRecipe?.imageUuid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NinjaColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Удалить изображение?', style: NinjaText.title),
        content: Text(
          'Вы уверены, что хотите удалить это изображение?',
          style: NinjaText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена', style: NinjaText.body),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Удалить',
              style: NinjaText.body.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final response = await ApiService.delete(
        '/api/recipes/${_currentRecipe!.uuid}/delete-image',
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Перезагружаем рецепт для получения обновленных данных
        final updatedRecipe = await RecipeService.getRecipe(
          _currentRecipe!.uuid,
        );
        if (mounted) {
          setState(() {
            _currentRecipe = updatedRecipe;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Изображение успешно удалено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка удаления изображения: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      setState(() {
        _isUploadingImage = true;
      });

      // Определяем MIME тип
      final fileExtension = image.path.split('.').last.toLowerCase();
      String? mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      final response = await ApiService.multipart(
        '/api/recipes/${_currentRecipe!.uuid}/upload-image',
        fileField: 'file',
        filePath: image.path,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Перезагружаем рецепт для получения обновленных данных
        final updatedRecipe = await RecipeService.getRecipe(
          _currentRecipe!.uuid,
        );
        if (mounted) {
          setState(() {
            _currentRecipe = updatedRecipe;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Изображение успешно загружено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка загрузки изображения: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _parseIngredientAmount(String amountStr, int multiplier) {
    // Парсим строку вида "1 шт" или "100 г"
    final parts = amountStr.split(' ');
    if (parts.isEmpty) return amountStr;

    try {
      final number = double.parse(parts[0]);
      final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final newAmount = (number * multiplier).toStringAsFixed(0);
      return unit.isNotEmpty ? '$newAmount $unit' : newAmount;
    } catch (e) {
      return amountStr;
    }
  }

  void _openEditRecipe() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;
    final isUserRecipe = _currentRecipe?.userUuid != null;
    final canEdit =
        isAdmin ||
        (isUserRecipe && userProfile?.uuid == _currentRecipe?.userUuid);

    if (!canEdit) return;

    final useAdminForm = isAdmin && !isUserRecipe;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RecipeEditScreen(
              recipe: _currentRecipe!,
              isAdmin: useAdminForm,
            ),
          ),
        )
        .then((_) async {
          // Обновить данные рецепта при возврате
          if (mounted && _currentRecipe != null) {
            try {
              final updatedRecipe = await RecipeService.getRecipe(
                _currentRecipe!.uuid,
              );
              if (mounted) {
                setState(() {
                  _currentRecipe = updatedRecipe;
                });
              }
            } catch (e) {
              // Игнорируем ошибки обновления
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;
    final isUserRecipe = _currentRecipe?.userUuid != null;
    final canEdit =
        isAdmin ||
        (isUserRecipe && userProfile?.uuid == _currentRecipe?.userUuid);
    // Для обычного пользователя можно управлять изображением только для своего рецепта
    // Для админа - для любого рецепта
    final canManageImage =
        isAdmin ||
        (isUserRecipe && userProfile?.uuid == _currentRecipe?.userUuid);

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
                    Expanded(child: Text('Рецепт', style: NinjaText.title)),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _openEditRecipe,
                        color: NinjaColors.textPrimary,
                      ),
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
                      // Фото
                      GestureDetector(
                        onTap: (_isUploadingImage || !canManageImage)
                            ? null
                            : _showImageActionDialog,
                        child: MetalCard(
                          padding: EdgeInsets.zero,
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            child: _isUploadingImage
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                NinjaColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: NinjaSpacing.md),
                                        Text(
                                          'Загрузка изображения...',
                                          style: NinjaText.body.copyWith(
                                            color: NinjaColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _currentRecipe?.imageUuid != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: AuthImageWidget(
                                      imageUuid: _currentRecipe!.imageUuid,
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 64,
                                          color: NinjaColors.textSecondary,
                                        ),
                                        const SizedBox(height: NinjaSpacing.lg),
                                        Text(
                                          canManageImage
                                              ? 'Нажмите, чтобы выбрать фото'
                                              : 'Изображение недоступно',
                                          style: NinjaText.body.copyWith(
                                            color: NinjaColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // Название и порции
                      MetalCard(
                        padding: const EdgeInsets.all(NinjaSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Название
                            Text(_currentRecipe!.name, style: NinjaText.title),
                            const SizedBox(height: NinjaSpacing.xs),
                            // Категория
                            Text(
                              _currentRecipe!.type ??
                                  _currentRecipe!.categoryDisplayName,
                              style: NinjaText.caption.copyWith(
                                color: NinjaColors.textSecondary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: NinjaSpacing.md),
                            // Порции
                            Row(
                              children: [
                                Text(
                                  'Порций',
                                  style: NinjaText.body.copyWith(
                                    color: NinjaColors.textSecondary,
                                  ),
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
                                          Text(
                                            '$_selectedPortions',
                                            style: NinjaText.body,
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Время приготовления
                                Text(
                                  '~${_currentRecipe!.cookingTime} мин',
                                  style: NinjaText.caption.copyWith(
                                    color: NinjaColors.textSecondary
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
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
                            Text('Ингредиенты', style: NinjaText.title),
                            const SizedBox(height: NinjaSpacing.md),
                            ..._currentRecipe!.ingredients.entries.map((entry) {
                              final amount = _parseIngredientAmount(
                                entry.value,
                                _selectedPortions,
                              );
                              return MetalListItem(
                                leading: const SizedBox(width: 0),
                                title: Text(entry.key, style: NinjaText.body),
                                subtitle: Text(
                                  amount,
                                  style: NinjaText.caption,
                                ),
                                onTap: () {},
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: NinjaSpacing.lg),

                      // КБЖУ на порцию
                      MetalCard(
                        padding: const EdgeInsets.all(NinjaSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('КБЖУ на порцию', style: NinjaText.title),
                            const SizedBox(height: NinjaSpacing.md),
                            // КБЖУ на 1 порцию
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'На 1 порцию',
                                    style: NinjaText.caption.copyWith(
                                      color: NinjaColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: NinjaSpacing.sm),
                                Expanded(
                                  child: Wrap(
                                    spacing: 2,
                                    runSpacing: 2,
                                    children: [
                                      MacroInfoChip(
                                        label: 'К',
                                        value: _currentRecipe!
                                            .caloriesPerPortion
                                            .toStringAsFixed(1),
                                        size: 36,
                                      ),
                                      MacroInfoChip(
                                        label: 'Б',
                                        value: _currentRecipe!
                                            .proteinsPerPortion
                                            .toStringAsFixed(1),
                                        size: 36,
                                      ),
                                      MacroInfoChip(
                                        label: 'Ж',
                                        value: _currentRecipe!.fatsPerPortion
                                            .toStringAsFixed(1),
                                        size: 36,
                                      ),
                                      MacroInfoChip(
                                        label: 'У',
                                        value: _currentRecipe!.carbsPerPortion
                                            .toStringAsFixed(1),
                                        size: 36,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // КБЖУ на указанное количество порций (только если не равно 1)
                            if (_selectedPortions != 1) ...[
                              const SizedBox(height: NinjaSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'На $_selectedPortions порций',
                                      style: NinjaText.caption.copyWith(
                                        color: NinjaColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: NinjaSpacing.sm),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 2,
                                      runSpacing: 2,
                                      children: [
                                        MacroInfoChip(
                                          label: 'К',
                                          value:
                                              (_currentRecipe!
                                                          .caloriesPerPortion *
                                                      _selectedPortions)
                                                  .toStringAsFixed(1),
                                          size: 36,
                                        ),
                                        MacroInfoChip(
                                          label: 'Б',
                                          value:
                                              (_currentRecipe!
                                                          .proteinsPerPortion *
                                                      _selectedPortions)
                                                  .toStringAsFixed(1),
                                          size: 36,
                                        ),
                                        MacroInfoChip(
                                          label: 'Ж',
                                          value:
                                              (_currentRecipe!.fatsPerPortion *
                                                      _selectedPortions)
                                                  .toStringAsFixed(1),
                                          size: 36,
                                        ),
                                        MacroInfoChip(
                                          label: 'У',
                                          value:
                                              (_currentRecipe!.carbsPerPortion *
                                                      _selectedPortions)
                                                  .toStringAsFixed(1),
                                          size: 36,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                            Text('КБЖУ на 100 грамм', style: NinjaText.title),
                            const SizedBox(height: NinjaSpacing.md),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: [
                                MacroInfoChip(
                                  label: 'К',
                                  value: _currentRecipe!.caloriesPer100g
                                      .toStringAsFixed(1),
                                  size: 36,
                                ),
                                MacroInfoChip(
                                  label: 'Б',
                                  value: _currentRecipe!.proteinsPer100g
                                      .toStringAsFixed(1),
                                  size: 36,
                                ),
                                MacroInfoChip(
                                  label: 'Ж',
                                  value: _currentRecipe!.fatsPer100g
                                      .toStringAsFixed(1),
                                  size: 36,
                                ),
                                MacroInfoChip(
                                  label: 'У',
                                  value: _currentRecipe!.carbsPer100g
                                      .toStringAsFixed(1),
                                  size: 36,
                                ),
                              ],
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
                            Text('Рецепт', style: NinjaText.title),
                            const SizedBox(height: NinjaSpacing.md),
                            Text(_currentRecipe!.recipe, style: NinjaText.body),
                          ],
                        ),
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
