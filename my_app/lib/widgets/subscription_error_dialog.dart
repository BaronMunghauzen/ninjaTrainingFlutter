import 'package:flutter/material.dart';
import 'metal_modal.dart';
import 'metal_button.dart';
import '../design/ninja_colors.dart';
import '../design/ninja_typography.dart';
import '../design/ninja_spacing.dart';

class SubscriptionErrorDialog {
  static Future<void> show({
    required BuildContext context,
    VoidCallback? onClose,
    String? message,
    bool barrierDismissible = false,
  }) {
    return MetalModal.show(
      context: context,
      title: 'Подписка истекла',
      onClose: onClose,
      barrierDismissible: barrierDismissible,
      children: [
        // Иконка ошибки
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NinjaColors.error.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.block,
              color: NinjaColors.error,
              size: 50,
            ),
          ),
        ),
        const SizedBox(height: NinjaSpacing.lg),

        // Сообщение
        Text(
          message ??
              'Для доступа к этой функции необходимо продлить подписку',
          style: NinjaText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NinjaSpacing.xl),

        // Кнопка "Назад"
        MetalButton(
          label: 'Назад',
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
        ),
      ],
    );
  }
}
