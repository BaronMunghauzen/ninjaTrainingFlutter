import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/ninja_colors.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/subscription_error_dialog.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_card.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/macro_info_chip.dart';
import '../../utils/ninja_route.dart';
import 'photo_recognition/food_photo_selection_screen.dart';
import 'photo_recognition/food_recognition_history_screen.dart';
import 'photo_recognition/food_recognition_result_screen.dart';
import 'recipes/recipes_screen.dart';
import 'food_progress/widgets/food_progress_section.dart';
import 'food_progress/screens/food_progress_target_create_screen.dart';
import 'food_progress/screens/food_progress_meal_add_screen.dart';
import 'food_progress/screens/food_progress_meals_history_screen.dart';
import 'food_progress/services/food_progress_service.dart';
import 'food_progress/models/food_progress_model.dart';
import '../../models/food_recognition_model.dart';
import '../../services/api_service.dart';
import 'calorie_calculator/services/calorie_calculator_service.dart';
import 'calorie_calculator/models/calorie_calculator_model.dart';
import 'calorie_calculator/screens/calorie_calculator_calculate_screen.dart';
import 'calorie_calculator/screens/calorie_calculator_result_screen.dart';
import '../../widgets/metal_modal.dart';
import 'package:intl/intl.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({Key? key}) : super(key: key);

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  FoodRecognition? _lastRecognition;
  bool _isLoading = true;
  FoodProgressSummary? _progressSummary;
  bool _isLoadingProgress = true;
  CalorieCalculation? _lastCalculation;
  bool _isLoadingCalculation = true;

  @override
  void initState() {
    super.initState();
    _loadLastRecognition();
    _loadProgress();
    _loadLastCalculation();
  }

  Future<void> _loadLastRecognition() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.get(
        '/api/food-recognition/',
        queryParams: {'page': '1', 'size': '10', 'actual': 'true'},
      );

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final listResponse = FoodRecognitionListResponse.fromJson(
          data as Map<String, dynamic>,
        );

        if (mounted) {
          setState(() {
            _lastRecognition = listResponse.items.isNotEmpty
                ? listResponse.items.first
                : null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkSubscriptionAndScan() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null || userProfile.subscriptionStatus != 'active') {
      SubscriptionErrorDialog.show(
        context: context,
        message:
            'Для использования функции сканирования еды необходима активная подписка',
      );
      return;
    }

    Navigator.of(
      context,
    ).push(ninjaRoute(const FoodPhotoSelectionScreen())).then((_) {
      _loadLastRecognition();
    });
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(ninjaRoute(const FoodRecognitionHistoryScreen())).then((_) {
      _refresh();
    });
  }

  void _openLastRecognition() {
    if (_lastRecognition != null) {
      Navigator.of(context)
          .push(
            ninjaRoute(
              FoodRecognitionResultScreen(recognition: _lastRecognition!),
            ),
          )
          .then((_) {
            _refresh();
          });
    }
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final summary = await FoodProgressService.getDailySummary();
      if (mounted) {
        setState(() {
          _progressSummary = summary;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  void _openAddTarget() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const FoodProgressTargetCreateScreen(),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadProgress();
          }
        });
  }

  void _openAddMeal() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const FoodProgressMealAddScreen(),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadProgress();
          }
        });
  }

  void _openMealsHistory() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const FoodProgressMealsHistoryScreen(),
          ),
        )
        .then((_) {
          _refresh();
        });
  }

  void _openCalculator() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const CalorieCalculatorCalculateScreen(),
          ),
        )
        .then((_) {
          _loadLastCalculation();
        });
  }

  void _openCalculationResult() {
    if (_lastCalculation != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) =>
                  CalorieCalculatorResultScreen(calculation: _lastCalculation!),
            ),
          )
          .then((result) {
            _loadLastCalculation();
            // Если добавили в дневную цель, обновляем прогресс
            if (result == true) {
              _loadProgress();
            }
          });
    }
  }

  Future<void> _deleteCalculation() async {
    if (_lastCalculation == null) return;

    final confirmed = await MetalModal.show<bool>(
      context: context,
      title: 'Удалить расчет',
      children: [
        Text(
          'Вы уверены, что хотите удалить этот расчет?',
          style: NinjaText.body,
        ),
        const SizedBox(height: NinjaSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Отмена', style: NinjaText.body),
            ),
            const SizedBox(width: NinjaSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Удалить',
                style: NinjaText.body.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );

    if (confirmed != true) return;

    try {
      await CalorieCalculatorService.deactivate(_lastCalculation!.uuid);
      if (mounted) {
        setState(() {
          _lastCalculation = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления расчета: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLastCalculation() async {
    setState(() {
      _isLoadingCalculation = true;
    });

    try {
      final calculation = await CalorieCalculatorService.getLast();
      if (mounted) {
        setState(() {
          _lastCalculation = calculation;
          _isLoadingCalculation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCalculation = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadLastRecognition(),
      _loadProgress(),
      _loadLastCalculation(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: NinjaColors.textPrimary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Прогресс КБЖУ
                  if (_isLoadingProgress)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(NinjaSpacing.xxl),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NinjaColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  else
                    FoodProgressSection(
                      summary:
                          _progressSummary ??
                          FoodProgressSummary(
                            date: '',
                            eatenCalories: 0.0,
                            eatenProteins: 0.0,
                            eatenFats: 0.0,
                            eatenCarbs: 0.0,
                            targetCalories: 0.0,
                            targetProteins: 0.0,
                            targetFats: 0.0,
                            targetCarbs: 0.0,
                            remainingCalories: 0.0,
                            remainingProteins: 0.0,
                            remainingFats: 0.0,
                            remainingCarbs: 0.0,
                          ),
                      onAddTarget: _openAddTarget,
                      onAddMeal: _openAddMeal,
                      onMealsHistory: _openMealsHistory,
                    ),
                  if (!_isLoadingProgress)
                const SizedBox(height: NinjaSpacing.lg),

                  // Карточка с иконкой и 4 кнопками
                  MetalCard(
                    padding: const EdgeInsets.all(NinjaSpacing.lg),
                    child: Column(
                      children: [
                        // Логотип foodforcard.png
                        SizedBox(
                          width: 180,
                          height: 160,
                          child: Opacity(
                            opacity: 0.6,
                            child: Image.asset(
                              'assets/images/foodforcard.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        const SizedBox(height: NinjaSpacing.lg),
                        // Первый ряд: распознавание КБЖУ и рецепты
                        Row(
                          children: [
                            Expanded(
                              child: _buildImageButton(
                                imagePath: 'assets/images/aifood.png',
                                onPressed: _openScanModal,
                              ),
                            ),
                            const SizedBox(width: NinjaSpacing.md),
                            Expanded(
                              child: _buildImageButton(
                                imagePath: 'assets/images/recipes.png',
                                onPressed: _checkSubscriptionAndOpenRecipes,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: NinjaSpacing.md),
                        // Второй ряд: калькулятор калорий по центру
                        Align(
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: _buildImageButton(
                              imagePath: 'assets/images/calculator.png',
                              onPressed: _openCalculatorModal,
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _checkSubscriptionAndOpenRecipes() {
    Navigator.of(context).push(ninjaRoute(const RecipesScreen())).then((_) {
      _refresh();
    });
  }

  void _openScanModal() {
    MetalModal.show(
      context: context,
      title: 'Сканирование фото',
      children: [
        // Кнопка "Загрузить фото"
        MetalButton(
          label: 'Загрузить фото для ИИ сканирования',
          icon: Icons.camera_alt,
          onPressed: () {
            Navigator.of(context).pop();
            _checkSubscriptionAndScan();
          },
          height: 56,
        ),
        // Последнее сканирование
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(NinjaSpacing.xl),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                NinjaColors.textPrimary,
              ),
            ),
          )
        else if (_lastRecognition != null) ...[
          const SizedBox(height: NinjaSpacing.md),
          _buildLastRecognitionCard(),
        ],
        const SizedBox(height: NinjaSpacing.md),
        // Кнопка истории
        MetalButton(
          label: 'История сканирований',
          icon: Icons.history,
          onPressed: () {
            Navigator.of(context).pop();
            _openHistory();
          },
          height: 48,
        ),
      ],
    );
  }

  void _openCalculatorModal() {
    MetalModal.show(
      context: context,
      title: 'Калькулятор калорий',
      children: [
        MetalButton(
          label: 'Рассчитать норму потребления',
          icon: Icons.calculate,
          onPressed: () {
            Navigator.of(context).pop();
            _openCalculator();
          },
          height: 48,
        ),
        if (_isLoadingCalculation)
          const Padding(
            padding: EdgeInsets.all(NinjaSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  NinjaColors.textPrimary,
                ),
              ),
            ),
          )
        else if (_lastCalculation != null) ...[
          const SizedBox(height: NinjaSpacing.md),
          _buildLastCalculationCard(),
        ],
      ],
    );
  }


  Widget _buildImageButton({
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return _ImageMetalButton(
      imagePath: imagePath,
      onPressed: onPressed,
      height: 80,
    );
  }

  Widget _buildLastRecognitionCard() {
    final recognition = _lastRecognition!;
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateStr = dateFormat.format(DateTime.parse(recognition.createdAt));

    return MetalListItem(
      leading: ClipOval(
        child: AuthImageWidget(
          imageUuid: recognition.imageUuid,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Stack(
        clipBehavior: Clip.none,
        children: [
          Text(recognition.name, style: NinjaText.title.copyWith(fontSize: 16)),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.translate(
              offset: const Offset(150, 0), // Смещаем правее за пределы title
              child: Text(
                dateStr,
                style: NinjaText.caption.copyWith(
                  color: NinjaColors.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            'Вес: ${recognition.weightG.toStringAsFixed(0)} г',
            style: NinjaText.caption,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              MacroInfoChip(
                label: 'К',
                value: recognition.caloriesTotal.toStringAsFixed(0),
                size: 32,
              ),
              MacroInfoChip(
                label: 'Б',
                value: recognition.proteinsTotal.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'Ж',
                value: recognition.fatsTotal.toStringAsFixed(1),
                size: 32,
              ),
              MacroInfoChip(
                label: 'У',
                value: recognition.carbsTotal.toStringAsFixed(1),
                size: 32,
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: NinjaColors.textSecondary,
        size: 20,
      ),
      onTap: _openLastRecognition,
    );
  }

  Widget _buildLastCalculationCard() {
    final calculation = _lastCalculation!;
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateStr = dateFormat.format(calculation.createdAt);

    return MetalListItem(
      leading: const SizedBox(width: 0),
      title: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(calculation.getGoalDisplayName(), style: NinjaText.body),
              const SizedBox(height: 4),
              Text(
                'Пол: ${calculation.getGenderDisplayName()}',
                style: NinjaText.caption.copyWith(
                  color: NinjaColors.textSecondary,
                ),
              ),
              Text(
                'Вес: ${calculation.weight.toStringAsFixed(1)} кг',
                style: NinjaText.caption.copyWith(
                  color: NinjaColors.textSecondary,
                ),
              ),
              Text(
                'Возраст: ${calculation.age} лет',
                style: NinjaText.caption.copyWith(
                  color: NinjaColors.textSecondary,
                ),
              ),
              Text(
                'Уровень активности: ${calculation.getActivityDisplayName()}',
                style: NinjaText.caption.copyWith(
                  color: NinjaColors.textSecondary,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Transform.translate(
              offset: const Offset(125, 0), // Смещаем правее за пределы title
              child: Text(
                dateStr,
                style: NinjaText.caption.copyWith(
                  color: NinjaColors.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        iconSize: 20,
        color: NinjaColors.textSecondary,
        onPressed: _deleteCalculation,
      ),
      onTap: _openCalculationResult,
      isFirst: true,
      isLast: true,
      removeSpacing: false,
    );
  }
}

// Кастомная кнопка с изображением на основе MetalButton
class _ImageMetalButton extends StatefulWidget {
  final String imagePath;
  final VoidCallback? onPressed;
  final double height;

  const _ImageMetalButton({
    required this.imagePath,
    this.onPressed,
    this.height = 80,
  });

  @override
  State<_ImageMetalButton> createState() => _ImageMetalButtonState();
}

class _ImageMetalButtonState extends State<_ImageMetalButton> {
  bool _pressed = false;

  MetalButtonState get state {
    if (widget.onPressed == null) {
      return MetalButtonState.disabled;
    }
    if (_pressed) {
      return MetalButtonState.pressed;
    }
    return MetalButtonState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final s = state;

    return GestureDetector(
      onTapDown: s == MetalButtonState.idle
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: (_) {
        // Не сбрасываем здесь, пусть onTap это сделает
      },
      onTapCancel: () {
        if (_pressed) {
          setState(() => _pressed = false);
        }
      },
      onTap: s != MetalButtonState.disabled
          ? () {
              // Вызываем callback сразу
              widget.onPressed?.call();
              // Сбрасываем состояние с задержкой, чтобы анимация успела проиграться
              Future.delayed(const Duration(milliseconds: 120), () {
                if (mounted) {
                  setState(() => _pressed = false);
                }
              });
            }
          : null,
      child: AnimatedScale(
        scale: s == MetalButtonState.pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: widget.height,
          decoration: _decorationFor(s),
          child: Stack(
            children: [
              // Основной градиент (первый слой)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _gradientFor(s),
                    ),
                  ),
                ),
              ),

              // Micro texture layer
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/textures/graphite_noise.png',
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(_textureOpacityFor(s)),
                      colorBlendMode: BlendMode.softLight,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),

              // Легкое свечение сверху по центру кнопки
              if (s == MetalButtonState.idle)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFC5D09D).withOpacity(0.15),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Градиентная обводка сверху
              if (s == MetalButtonState.idle)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 2,
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Colors.transparent,
                              Color(0x80C5D09D),
                              Color(0xFFC5D09D),
                              Color(0x80C5D09D),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Дополнительное затемнение снизу
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Inner highlight (верхний свет)
              if (s == MetalButtonState.idle)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.08),
                              offset: const Offset(0, -1),
                              blurRadius: 2,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Inner shadow (нижняя тень)
              if (s == MetalButtonState.idle || s == MetalButtonState.pressed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                s == MetalButtonState.pressed ? 0.6 : 0.3,
                              ),
                              offset: const Offset(0, 2),
                              blurRadius: s == MetalButtonState.pressed ? 6 : 5,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Content - изображение
              Center(
                child: Transform.translate(
                  offset: s == MetalButtonState.pressed
                      ? const Offset(0, 1)
                      : Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
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

  BoxDecoration _decorationFor(MetalButtonState s) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: s == MetalButtonState.disabled
            ? Colors.grey.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  LinearGradient _gradientFor(MetalButtonState s) {
    if (s == MetalButtonState.disabled) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.2)],
      );
    }
    if (s == MetalButtonState.pressed) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A3A3A), Color(0xFF2A2A2A)],
    );
  }

  double _textureOpacityFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.idle:
        return 0.08;
      case MetalButtonState.pressed:
        return 0.12;
      case MetalButtonState.disabled:
        return 0.05;
    }
  }
}
