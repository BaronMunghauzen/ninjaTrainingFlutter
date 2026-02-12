import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/achievement_type_model.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_text_field.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_dropdown.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/auth_image_widget.dart';
import '../../design/ninja_typography.dart';
import '../../design/ninja_colors.dart';
import '../../design/ninja_spacing.dart';

class AdminAchievementTypesScreen extends StatefulWidget {
  const AdminAchievementTypesScreen({super.key});

  @override
  State<AdminAchievementTypesScreen> createState() =>
      _AdminAchievementTypesScreenState();
}

class _AdminAchievementTypesScreenState
    extends State<AdminAchievementTypesScreen> {
  List<AchievementType> _achievementTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAchievementTypes();
  }

  Future<void> _loadAchievementTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/achievements/types');

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        if (data is List) {
          final achievementTypes = data
              .map(
                (json) =>
                    AchievementType.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          if (mounted) {
            setState(() {
              _achievementTypes = achievementTypes;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Неверный формат ответа API');
        }
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
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

  Map<String, List<AchievementType>> _groupByCategory(
    List<AchievementType> achievementTypes,
  ) {
    final Map<String, List<AchievementType>> grouped = {};
    for (final achievementType in achievementTypes) {
      final category = achievementType.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(achievementType);
    }
    return grouped;
  }

  Future<void> _uploadImage(String achievementTypeUuid) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

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
        '/achievements/types/$achievementTypeUuid/upload-image',
        fileField: 'file',
        filePath: image.path,
        mimeType: mimeType,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Изображение успешно загружено',
            type: MetalMessageType.success,
          );
          await _loadAchievementTypes();
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка загрузки изображения: ${response.statusCode}',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  Future<void> _deleteImage(String achievementTypeUuid) async {
    try {
      final response = await ApiService.delete(
        '/achievements/types/$achievementTypeUuid/delete-image',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Изображение успешно удалено',
            type: MetalMessageType.success,
          );
          await _loadAchievementTypes();
        }
      } else {
        if (mounted) {
          MetalMessage.show(
            context: context,
            message: 'Ошибка удаления изображения: ${response.statusCode}',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  void _showAchievementTypeDetail(AchievementType achievementType) {
    MetalModal.show(
      context: context,
      title: achievementType.name,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка с кнопками управления
            Center(
              child: Column(
                children: [
                  AuthImageWidget(
                    imageUuid: achievementType.imageUuid,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: NinjaSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MetalButton(
                        label: 'Загрузить',
                        icon: Icons.upload,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _uploadImage(achievementType.uuid);
                        },
                        height: 36,
                        fontSize: 12,
                      ),
                      if (achievementType.imageUuid != null) ...[
                        const SizedBox(width: NinjaSpacing.sm),
                        MetalButton(
                          label: 'Удалить',
                          icon: Icons.delete,
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteImage(achievementType.uuid);
                          },
                          height: 36,
                          fontSize: 12,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: NinjaSpacing.lg),
            // Описание
            Text('Описание:', style: NinjaText.title.copyWith(fontSize: 16)),
            const SizedBox(height: NinjaSpacing.sm),
            Text(achievementType.description, style: NinjaText.body),
            const SizedBox(height: NinjaSpacing.lg),
            // Категория
            Text('Категория:', style: NinjaText.title.copyWith(fontSize: 16)),
            const SizedBox(height: NinjaSpacing.sm),
            Text(achievementType.category, style: NinjaText.body),
            if (achievementType.subcategory != null) ...[
              const SizedBox(height: NinjaSpacing.md),
              Text(
                'Подкатегория:',
                style: NinjaText.title.copyWith(fontSize: 16),
              ),
              const SizedBox(height: NinjaSpacing.sm),
              Text(achievementType.subcategory!, style: NinjaText.body),
            ],
            const SizedBox(height: NinjaSpacing.lg),
            // Требования
            Text('Требования:', style: NinjaText.title.copyWith(fontSize: 16)),
            const SizedBox(height: NinjaSpacing.sm),
            Text(achievementType.requirements, style: NinjaText.body),
            const SizedBox(height: NinjaSpacing.lg),
            // Очки
            Row(
              children: [
                const Icon(Icons.stars, color: NinjaColors.accent, size: 20),
                const SizedBox(width: NinjaSpacing.sm),
                Text(
                  'Очки: ${achievementType.points}',
                  style: NinjaText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: NinjaSpacing.md),
            // Статус
            Row(
              children: [
                Icon(
                  achievementType.isActive ? Icons.check_circle : Icons.cancel,
                  color: achievementType.isActive
                      ? NinjaColors.success
                      : NinjaColors.error,
                  size: 20,
                ),
                const SizedBox(width: NinjaSpacing.sm),
                Text(
                  achievementType.isActive ? 'Активно' : 'Неактивно',
                  style: NinjaText.body.copyWith(
                    color: achievementType.isActive
                        ? NinjaColors.success
                        : NinjaColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showEditModal(AchievementType achievementType) {
    final nameController = TextEditingController(text: achievementType.name);
    final descriptionController = TextEditingController(
      text: achievementType.description,
    );
    final requirementsController = TextEditingController(
      text: achievementType.requirements,
    );
    final pointsController = TextEditingController(
      text: achievementType.points.toString(),
    );
    String selectedCategory = achievementType.category;
    bool isActive = achievementType.isActive;
    bool isLoading = false;

    MetalModal.show(
      context: context,
      title: 'Редактировать достижение',
      children: [
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Название
                MetalTextField(controller: nameController, hint: 'Название'),
                const SizedBox(height: NinjaSpacing.lg),
                // Описание
                MetalTextField(
                  controller: descriptionController,
                  hint: 'Описание',
                  maxLines: 3,
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Категория
                Text(
                  'Категория:',
                  style: NinjaText.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: NinjaSpacing.sm),
                MetalDropdown<String>(
                  value: selectedCategory,
                  items: [
                    MetalDropdownItem<String>(
                      value: 'training_count_in_week',
                      label: 'training_count_in_week',
                    ),
                    MetalDropdownItem<String>(
                      value: 'training_count',
                      label: 'training_count',
                    ),
                    MetalDropdownItem<String>(
                      value: 'time_more_than',
                      label: 'time_more_than',
                    ),
                    MetalDropdownItem<String>(
                      value: 'time_less_than',
                      label: 'time_less_than',
                    ),
                    MetalDropdownItem<String>(
                      value: 'special_day',
                      label: 'special_day',
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Требования
                MetalTextField(
                  controller: requirementsController,
                  hint: 'Требования',
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Очки
                MetalTextField(
                  controller: pointsController,
                  hint: 'Очки',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Статус активности
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value ?? true;
                        });
                      },
                    ),
                    Text('Активно', style: NinjaText.body),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Кнопки
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text('Отмена', style: NinjaText.body),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty) {
                                MetalMessage.show(
                                  context: context,
                                  message: 'Укажите название',
                                  type: MetalMessageType.error,
                                );
                                return;
                              }

                              final points = int.tryParse(
                                pointsController.text,
                              );
                              if (points == null) {
                                MetalMessage.show(
                                  context: context,
                                  message:
                                      'Укажите корректное количество очков',
                                  type: MetalMessageType.error,
                                );
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final response = await ApiService.put(
                                  '/achievements/types/${achievementType.uuid}',
                                  body: {
                                    'name': nameController.text.trim(),
                                    'description': descriptionController.text
                                        .trim(),
                                    'category': selectedCategory,
                                    'requirements': requirementsController.text
                                        .trim(),
                                    'points': points,
                                    'is_active': isActive,
                                  },
                                );

                                if (response.statusCode >= 200 &&
                                    response.statusCode < 300) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    MetalMessage.show(
                                      context: context,
                                      message: 'Достижение успешно обновлено',
                                      type: MetalMessageType.success,
                                    );
                                    await _loadAchievementTypes();
                                  }
                                } else {
                                  throw Exception(
                                    'Ошибка обновления: ${response.statusCode}',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  MetalMessage.show(
                                    context: context,
                                    message: 'Ошибка: $e',
                                    type: MetalMessageType.error,
                                  );
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Сохранить', style: NinjaText.body),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showCreateModal() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final requirementsController = TextEditingController();
    final pointsController = TextEditingController(text: '0');
    String selectedCategory = 'special_day';
    bool isActive = true;
    bool isLoading = false;

    MetalModal.show(
      context: context,
      title: 'Создать достижение',
      children: [
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Название
                MetalTextField(controller: nameController, hint: 'Название'),
                const SizedBox(height: NinjaSpacing.lg),
                // Описание
                MetalTextField(
                  controller: descriptionController,
                  hint: 'Описание',
                  maxLines: 3,
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Категория
                Text(
                  'Категория:',
                  style: NinjaText.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: NinjaSpacing.sm),
                MetalDropdown<String>(
                  value: selectedCategory,
                  items: [
                    MetalDropdownItem<String>(
                      value: 'training_count_in_week',
                      label: 'training_count_in_week',
                    ),
                    MetalDropdownItem<String>(
                      value: 'training_count',
                      label: 'training_count',
                    ),
                    MetalDropdownItem<String>(
                      value: 'time_more_than',
                      label: 'time_more_than',
                    ),
                    MetalDropdownItem<String>(
                      value: 'time_less_than',
                      label: 'time_less_than',
                    ),
                    MetalDropdownItem<String>(
                      value: 'special_day',
                      label: 'special_day',
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Требования
                MetalTextField(
                  controller: requirementsController,
                  hint: 'Требования',
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Очки
                MetalTextField(
                  controller: pointsController,
                  hint: 'Очки',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Статус активности
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value ?? true;
                        });
                      },
                    ),
                    Text('Активно', style: NinjaText.body),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Кнопки
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text('Отмена', style: NinjaText.body),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty) {
                                MetalMessage.show(
                                  context: context,
                                  message: 'Укажите название',
                                  type: MetalMessageType.error,
                                );
                                return;
                              }

                              final points = int.tryParse(
                                pointsController.text,
                              );
                              if (points == null) {
                                MetalMessage.show(
                                  context: context,
                                  message:
                                      'Укажите корректное количество очков',
                                  type: MetalMessageType.error,
                                );
                                return;
                              }

                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final response = await ApiService.post(
                                  '/achievements/types',
                                  body: {
                                    'name': nameController.text.trim(),
                                    'description': descriptionController.text
                                        .trim(),
                                    'category': selectedCategory,
                                    'requirements': requirementsController.text
                                        .trim(),
                                    'points': points,
                                    'is_active': isActive,
                                  },
                                );

                                if (response.statusCode >= 200 &&
                                    response.statusCode < 300) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    MetalMessage.show(
                                      context: context,
                                      message: 'Достижение успешно создано',
                                      type: MetalMessageType.success,
                                    );
                                    await _loadAchievementTypes();
                                  }
                                } else {
                                  throw Exception(
                                    'Ошибка создания: ${response.statusCode}',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  MetalMessage.show(
                                    context: context,
                                    message: 'Ошибка: $e',
                                    type: MetalMessageType.error,
                                  );
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Создать', style: NinjaText.body),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Заголовок и кнопка назад
                  Container(
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
                            'Типы достижений',
                            style: NinjaText.title,
                          ),
                        ),
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
                                  _error!,
                                  style: NinjaText.body.copyWith(
                                    color: NinjaColors.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadAchievementTypes,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: NinjaColors.metalMid,
                                    foregroundColor: NinjaColors.textPrimary,
                                  ),
                                  child: Text(
                                    'Повторить',
                                    style: NinjaText.body,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAchievementTypes,
                            color: NinjaColors.accent,
                            child: CustomScrollView(
                              slivers: _buildAchievementGroups(),
                            ),
                          ),
                  ),
                ],
              ),
              // Кнопка добавления внизу справа
              if (!_isLoading && _error == null)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton(
                    onPressed: _showCreateModal,
                    backgroundColor: NinjaColors.accent,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAchievementGroups() {
    final grouped = _groupByCategory(_achievementTypes);
    final categories = grouped.keys.toList()..sort();

    return categories.map((category) {
      final achievementTypes = grouped[category]!;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок категории
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  category,
                  style: NinjaText.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Сетка достижений (2 в строке)
              _buildAchievementsGrid(achievementTypes),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAchievementsGrid(List<AchievementType> achievementTypes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: achievementTypes.length,
      itemBuilder: (context, index) {
        return _buildAchievementItem(achievementTypes[index]);
      },
    );
  }

  Widget _buildAchievementItem(AchievementType achievementType) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showAchievementTypeDetail(achievementType),
          child: MetalCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Картинка
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AuthImageWidget(
                      imageUuid: achievementType.imageUuid,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Название достижения
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    achievementType.name,
                    style: NinjaText.caption.copyWith(
                      color: NinjaColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Кнопка редактирования
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _showEditModal(achievementType),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: NinjaColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
