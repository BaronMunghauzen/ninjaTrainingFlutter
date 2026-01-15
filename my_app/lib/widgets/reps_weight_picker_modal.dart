import 'package:flutter/material.dart';
import '../design/ninja_spacing.dart';
import 'metal_button.dart';

/// Модальное окно для выбора повторений и веса
class RepsWeightPickerModal extends StatefulWidget {
  final int initialReps;
  final double initialWeight;
  final int maxReps;
  final bool withWeight;
  final Function(int reps, double weight) onSave;

  const RepsWeightPickerModal({
    super.key,
    required this.initialReps,
    required this.initialWeight,
    required this.maxReps,
    required this.withWeight,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required int initialReps,
    required double initialWeight,
    required int maxReps,
    required bool withWeight,
    required Function(int reps, double weight) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RepsWeightPickerModal(
        initialReps: initialReps,
        initialWeight: initialWeight,
        maxReps: maxReps,
        withWeight: withWeight,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RepsWeightPickerModal> createState() => _RepsWeightPickerModalState();
}

class _RepsWeightPickerModalState extends State<RepsWeightPickerModal> {
  late int selectedReps;
  late int selectedWeightInteger;
  late int selectedWeightFractionIndex;
  late FixedExtentScrollController repsController;
  late FixedExtentScrollController weightIntegerController;
  late FixedExtentScrollController weightFractionController;

  // Значения для дробной части веса
  static const List<String> weightFractions = ['00', '25', '50', '75'];

  @override
  void initState() {
    super.initState();
    selectedReps = widget.initialReps.clamp(0, widget.maxReps);

    // Инициализация контроллеров для повторений
    repsController = FixedExtentScrollController(initialItem: selectedReps);

    // Инициализация контроллеров для веса
    final weightInteger = widget.initialWeight.floor();
    final weightFraction = ((widget.initialWeight - weightInteger) * 100)
        .round();
    final fractionIndex = _getFractionIndex(weightFraction);

    selectedWeightInteger = weightInteger.clamp(0, 400);
    selectedWeightFractionIndex = fractionIndex;

    weightIntegerController = FixedExtentScrollController(
      initialItem: selectedWeightInteger,
    );
    weightFractionController = FixedExtentScrollController(
      initialItem: selectedWeightFractionIndex,
    );
  }

  int _getFractionIndex(int fraction) {
    switch (fraction) {
      case 0:
      case 1:
      case 2:
        return 0; // '00'
      case 25:
      case 26:
      case 24:
        return 1; // '25'
      case 50:
      case 51:
      case 49:
        return 2; // '50'
      case 75:
      case 76:
      case 74:
        return 3; // '75'
      default:
        // Находим ближайшее значение
        if (fraction < 12) return 0;
        if (fraction < 37) return 1;
        if (fraction < 62) return 2;
        return 3;
    }
  }

  @override
  void dispose() {
    repsController.dispose();
    weightIntegerController.dispose();
    weightFractionController.dispose();
    super.dispose();
  }

  double get currentWeight {
    final fraction =
        int.parse(weightFractions[selectedWeightFractionIndex]) / 100.0;
    return selectedWeightInteger + fraction;
  }

  void _handleSave() {
    widget.onSave(selectedReps, currentWeight);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Stack(
        children: [
          // Фон в стиле MetalModal
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  // Базовый фон
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  // Текстура графита
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/textures/graphite_noise.png',
                        fit: BoxFit.cover,
                        color: Colors.white.withOpacity(0.05),
                        colorBlendMode: BlendMode.softLight,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  // Вертикальная светотень
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.16),
                              Colors.transparent,
                              Colors.black.withOpacity(0.32),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Горизонтальная светотень
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                              Colors.black.withOpacity(0.60),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Дополнительное затемнение посередине
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.18),
                              Colors.black.withOpacity(0.60),
                              Colors.black.withOpacity(0.18),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Внешняя тень
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      offset: const Offset(0, -1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Контент
          Padding(
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: NinjaSpacing.md),
                // Скроллы
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Скролл повторений
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Повторения',
                          style: TextStyle(
                            color: Color(0xFFEDEDED),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            controller: repsController,
                            itemExtent: 40,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (val) {
                              setState(() {
                                selectedReps = val;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, i) => Center(
                                child: Text(
                                  '$i',
                                  style: const TextStyle(
                                    color: Color(0xFFEDEDED),
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              childCount: widget.maxReps + 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.withWeight) ...[
                      const SizedBox(width: 16),
                      // Разделитель "x"
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: const Text(
                          ' x ',
                          style: TextStyle(
                            color: Color(0xFFEDEDED),
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Скроллы веса
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Вес (кг)',
                            style: TextStyle(
                              color: Color(0xFFEDEDED),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Скролл целых чисел
                              SizedBox(
                                height: 120,
                                width: 60,
                                child: ListWheelScrollView.useDelegate(
                                  controller: weightIntegerController,
                                  itemExtent: 40,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (val) {
                                    setState(() {
                                      selectedWeightInteger = val;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, i) => Center(
                                      child: Text(
                                        '$i',
                                        style: const TextStyle(
                                          color: Color(0xFFEDEDED),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    childCount: 401, // 0-400 кг
                                  ),
                                ),
                              ),
                              // Точка
                              Transform.translate(
                                offset: const Offset(0, 0),
                                child: const Text(
                                  '.',
                                  style: TextStyle(
                                    color: Color(0xFFEDEDED),
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              // Скролл дробной части
                              SizedBox(
                                height: 120,
                                width: 50,
                                child: ListWheelScrollView.useDelegate(
                                  controller: weightFractionController,
                                  itemExtent: 40,
                                  diameterRatio: 1.2,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (val) {
                                    setState(() {
                                      selectedWeightFractionIndex = val;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, i) => Center(
                                      child: Text(
                                        weightFractions[i],
                                        style: const TextStyle(
                                          color: Color(0xFFEDEDED),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    childCount: weightFractions.length,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                // Кнопка сохранить
                MetalButton(
                  label: 'Сохранить',
                  onPressed: _handleSave,
                  height: 56,
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
