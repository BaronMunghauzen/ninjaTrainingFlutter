import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/subscription/payment_check_screen.dart';
import '../main.dart';

class DeepLinkHandler {
  /// Обработать Deep Link URL
  static Future<void> handleDeepLink(String url) async {
    print('Deep link received: $url');

    // Проверяем, что это ссылка возврата из оплаты
    // Поддерживаем оба варианта: custom scheme и https
    if (url.contains('payment/callback') &&
        (url.startsWith('ninjatraining://') ||
            url.startsWith('https://ninjatraining.ru'))) {
      // Получаем сохраненный payment_uuid
      final prefs = await SharedPreferences.getInstance();
      final paymentUuid = prefs.getString('current_payment_uuid');

      if (paymentUuid == null) {
        print('payment_uuid не найден в хранилище');
        return;
      }

      print('Opening payment check screen for payment: $paymentUuid');

      // Переходим на экран проверки платежа
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentCheckScreen(paymentUuid: paymentUuid),
          ),
        );
      }
    }
  }
}
