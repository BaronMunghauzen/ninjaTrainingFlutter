import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../design/ninja_colors.dart';
import '../../../../design/ninja_spacing.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../widgets/textured_background.dart';
import '../../../../widgets/metal_list_item.dart';
import '../../../../widgets/metal_back_button.dart';
import '../../../../widgets/metal_modal.dart';
import '../../../../widgets/metal_message.dart';
import '../../../../widgets/metal_text_field.dart';
import '../../../../widgets/macro_info_chip.dart';
import '../../../../providers/auth_provider.dart';
import '../models/food_progress_model.dart';
import '../services/food_progress_service.dart';

class FoodProgressMealsHistoryScreen extends StatefulWidget {
  const FoodProgressMealsHistoryScreen({super.key});

  @override
  State<FoodProgressMealsHistoryScreen> createState() =>
      _FoodProgressMealsHistoryScreenState();
}

class _FoodProgressMealsHistoryScreenState
    extends State<FoodProgressMealsHistoryScreen> {
  List<FoodProgressMeal> _meals = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNext = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMeals();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Загружаем следующую страницу при достижении 80% прокрутки
      if (!_isLoadingMore && _hasNext) {
        _loadMeals(loadMore: true);
      }
    }
  }

  Future<void> _loadMeals({bool loadMore = false}) async {
    if (loadMore && !_hasNext) return;

    setState(() {
      if (!loadMore) {
        _isLoading = true;
        _currentPage = 1;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        throw Exception('Пользователь не авторизован');
      }

      final page = loadMore ? _currentPage + 1 : 1;
      final response = await FoodProgressService.getMeals(
        userUuid: userUuid,
        page: page,
        size: 10,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _meals.addAll(response.items);
            _currentPage++;
          } else {
            _meals = response.items;
            _currentPage = 1;
          }
          _hasNext = response.pagination.hasNext;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки истории: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return dateFormat.format(dateTime);
  }

  void _showDeleteConfirmation(FoodProgressMeal meal) {
    MetalModal.show(
      context: context,
      title: 'Удалить прием пищи?',
      children: [
        Text(
          'Вы уверены, что хотите удалить "${meal.name.isNotEmpty ? meal.name : 'этот прием пищи'}"? Это действие нельзя отменить.',
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
                _deleteMeal(meal);
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

  Future<void> _deleteMeal(FoodProgressMeal meal) async {
    try {
      await FoodProgressService.deleteMeal(mealUuid: meal.uuid);
      if (mounted) {
        // Обновляем список после удаления
        await _loadMeals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления приема пищи: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _repeatMeal(FoodProgressMeal meal) async {
    try {
      // Используем текущие дату и время
      final mealDatetime = DateTime.now();

      await FoodProgressService.addMeal(
        mealDatetime: mealDatetime,
        name: meal.name,
        calories: meal.calories,
        proteins: meal.proteins > 0 ? meal.proteins : null,
        fats: meal.fats > 0 ? meal.fats : null,
        carbs: meal.carbs > 0 ? meal.carbs : null,
      );

      if (mounted) {
        // Обновляем список после добавления
        await _loadMeals();
        MetalMessage.show(
          context: context,
          message: 'Запись добавлена в дневник питания',
          type: MetalMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка повторения приема пищи: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  void _showMealActionsModal(FoodProgressMeal meal) {
    MetalModal.show(
      context: context,
      title: 'Действия',
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Кнопка Редактировать
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditModal(meal);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: NinjaSpacing.md,
                  vertical: NinjaSpacing.md,
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20, color: Colors.white),
                  const SizedBox(width: NinjaSpacing.sm),
                  Text('Редактировать', style: NinjaText.body),
                ],
              ),
            ),
            // Кнопка Повторить
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _repeatMeal(meal);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: NinjaSpacing.md,
                  vertical: NinjaSpacing.md,
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 20, color: Colors.white),
                  const SizedBox(width: NinjaSpacing.sm),
                  Text('Повторить', style: NinjaText.body),
                ],
              ),
            ),
            // Кнопка Удалить
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(meal);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: NinjaSpacing.md,
                  vertical: NinjaSpacing.md,
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: NinjaSpacing.sm),
                  Text(
                    'Удалить',
                    style: NinjaText.body.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditModal(FoodProgressMeal meal) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final nameController = TextEditingController(text: meal.name);
    final proteinsController = TextEditingController(
      text: meal.proteins > 0 ? meal.proteins.toStringAsFixed(1) : '',
    );
    final fatsController = TextEditingController(
      text: meal.fats > 0 ? meal.fats.toStringAsFixed(1) : '',
    );
    final carbsController = TextEditingController(
      text: meal.carbs > 0 ? meal.carbs.toStringAsFixed(1) : '',
    );
    DateTime selectedDateTime = meal.mealDatetime;

    MetalModal.show(
      context: context,
      title: 'Редактировать',
      children: [
        StatefulBuilder(
          builder: (context, setState) {

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Дата и время
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Время', style: NinjaText.title),
                    const SizedBox(height: NinjaSpacing.sm),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );

                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );

                          if (time != null) {
                            selectedDateTime = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() {});
                          }
                        }
                      },
                      child: MetalTextField(
                        controller: TextEditingController(
                          text: dateFormat.format(selectedDateTime),
                        ),
                        hint: 'Выберите дату и время',
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Название
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Название', style: NinjaText.title),
                    const SizedBox(height: NinjaSpacing.sm),
                    MetalTextField(
                      controller: nameController,
                      hint: 'Введите название',
                    ),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.lg),
                // Б, Ж, У в один ряд
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('БЖУ', style: NinjaText.title),
                    const SizedBox(height: NinjaSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Б', style: NinjaText.caption),
                              const SizedBox(height: NinjaSpacing.xs),
                              MetalTextField(
                                controller: proteinsController,
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_NumericTextInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: NinjaSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ж', style: NinjaText.caption),
                              const SizedBox(height: NinjaSpacing.xs),
                              MetalTextField(
                                controller: fatsController,
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_NumericTextInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: NinjaSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('У', style: NinjaText.caption),
                              const SizedBox(height: NinjaSpacing.xs),
                              MetalTextField(
                                controller: carbsController,
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_NumericTextInputFormatter()],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: NinjaSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Отмена', style: NinjaText.body),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    TextButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Укажите название'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final proteins = double.tryParse(
                          _normalizeNumberString(proteinsController.text),
                        );
                        final fats = double.tryParse(
                          _normalizeNumberString(fatsController.text),
                        );
                        final carbs = double.tryParse(
                          _normalizeNumberString(carbsController.text),
                        );

                        Navigator.of(context).pop();

                        try {
                          await FoodProgressService.updateMeal(
                            mealUuid: meal.uuid,
                            mealDatetime: selectedDateTime,
                            name: nameController.text.trim(),
                            proteins: proteins,
                            fats: fats,
                            carbs: carbs,
                          );
                          if (mounted) {
                            await _loadMeals();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка обновления записи: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text('Сохранить', style: NinjaText.body),
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

  String _normalizeNumberString(String value) {
    return value.replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
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
                        'Дневник питания',
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
                    : _meals.isEmpty
                        ? Center(
                            child: Text(
                              'Нет приемов пищи',
                              style: NinjaText.body.copyWith(
                                color: NinjaColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(NinjaSpacing.lg),
                            itemCount: _meals.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Показываем индикатор загрузки в конце списка
                              if (index == _meals.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(NinjaSpacing.lg),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        NinjaColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final meal = _meals[index];
                              final isFirst = index == 0;
                              final isLast = index == _meals.length - 1;
                              return MetalListItem(
                                leading: const SizedBox.shrink(),
                                title: Text(
                                  meal.name.isNotEmpty
                                      ? meal.name
                                      : 'Без названия',
                                  style: NinjaText.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(
                                    top: NinjaSpacing.sm,
                                  ),
                                  child: Wrap(
                                    spacing: NinjaSpacing.sm,
                                    runSpacing: NinjaSpacing.xs,
                                    children: [
                                      MacroInfoChip(
                                        label: 'К',
                                        value: meal.calories.toStringAsFixed(1),
                                        size: 32,
                                      ),
                                      MacroInfoChip(
                                        label: 'Б',
                                        value: meal.proteins.toStringAsFixed(1),
                                        size: 32,
                                      ),
                                      MacroInfoChip(
                                        label: 'Ж',
                                        value: meal.fats.toStringAsFixed(1),
                                        size: 32,
                                      ),
                                      MacroInfoChip(
                                        label: 'У',
                                        value: meal.carbs.toStringAsFixed(1),
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDateTime(meal.mealDatetime),
                                      style: NinjaText.body.copyWith(
                                        color: NinjaColors.textSecondary
                                            .withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: NinjaSpacing.xs),
                                        IconButton(
                                      icon: const Icon(
                                        Icons.more_vert,
                                          color: NinjaColors.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => _showMealActionsModal(meal),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                onTap: () {}, // Не кликабельный
                                isFirst: isFirst,
                                isLast: isLast,
                                removeSpacing: true,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Пустая строка разрешена
    if (text.isEmpty) {
      return newValue;
    }

    // Разрешаем только цифры, точку и запятую
    final allowedChars = RegExp(r'[0-9.,]');
    final filteredText = text.split('').where((char) => allowedChars.hasMatch(char)).join('');

    // Проверяем, что есть максимум одна точка или запятая
    final dotCount = filteredText.split('.').length - 1;
    final commaCount = filteredText.split(',').length - 1;

    if (dotCount > 1 || commaCount > 1 || (dotCount > 0 && commaCount > 0)) {
      // Если больше одной точки/запятой или обе одновременно - возвращаем старое значение
      return oldValue;
    }

    // Проверяем, что строка является валидным числом (целым или дробным)
    final normalizedText = filteredText.replaceAll(',', '.');
    if (normalizedText.isNotEmpty) {
      // Разрешаем строки вида: "123", "123.45", ".5", "0.5"
      final numberPattern = RegExp(r'^(\d+\.?\d*|\.\d+)$');
      if (!numberPattern.hasMatch(normalizedText)) {
        return oldValue;
      }
    }

    // Сохраняем позицию курсора
    int selectionOffset = newValue.selection.baseOffset;
    if (selectionOffset > filteredText.length) {
      selectionOffset = filteredText.length;
    } else if (selectionOffset < 0) {
      selectionOffset = 0;
    }

    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

