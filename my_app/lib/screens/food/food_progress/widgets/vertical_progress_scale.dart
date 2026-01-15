import 'package:flutter/material.dart';
import '../../../../design/ninja_colors.dart';
import '../../../../design/ninja_typography.dart';
import '../../../../design/ninja_spacing.dart';

class VerticalProgressScale extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String label;
  final double current;
  final double target;
  final bool isDecimal;

  const VerticalProgressScale({
    super.key,
    required this.progress,
    required this.label,
    required this.current,
    required this.target,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    const double scaleWidth =
        8.0; // Ширина линии как на food_recognition_result_screen
    const double scaleHeight = 150.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: scaleWidth,
          height: scaleHeight,
          child: Stack(
            children: [
              // Фоновая линия (как metalDark на food_recognition_result_screen)
              Container(
                width: scaleWidth,
                height: scaleHeight,
                decoration: BoxDecoration(
                  color: NinjaColors.metalDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Заполнение
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    width: scaleWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBC497),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NinjaSpacing.sm),
        // Название и значения
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: NinjaText.caption.copyWith(
                color: NinjaColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${current.toStringAsFixed(isDecimal ? 1 : 0)} / ${target.toStringAsFixed(isDecimal ? 1 : 0)}',
              style: NinjaText.body.copyWith(
                fontSize: 11,
                color: NinjaColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
