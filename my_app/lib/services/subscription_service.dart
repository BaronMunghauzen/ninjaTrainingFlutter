import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_status_model.dart';
import '../models/payment_model.dart';
import 'api_service.dart';

class SubscriptionService {
  /// Получить список всех доступных тарифных планов
  /// НЕ требует авторизации
  static Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/subscriptions/plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки тарифов: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки тарифов: $e');
    }
  }

  /// Получить статус подписки текущего пользователя
  /// Требует авторизации
  static Future<SubscriptionStatus> getStatus() async {
    try {
      final response = await ApiService.get('/api/subscriptions/status');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SubscriptionStatus.fromJson(data);
      } else {
        throw Exception('Ошибка загрузки статуса: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки статуса подписки: $e');
    }
  }

  /// Активировать триальный период вручную
  /// Требует авторизации
  static Future<Map<String, dynamic>> activateTrial() async {
    try {
      final response = await ApiService.post(
        '/api/subscriptions/activate-trial',
        body: {},
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['detail'] ?? 'Ошибка активации триала');
      }
    } catch (e) {
      throw Exception('Ошибка активации триала: $e');
    }
  }

  /// Создать платёжную ссылку для покупки подписки
  /// Требует авторизации
  static Future<PaymentResponse> createPayment({
    required String planUuid,
    String? returnUrl,
    List<String>? paymentMode,
  }) async {
    try {
      final body = {
        'plan_uuid': planUuid,
        if (returnUrl != null) 'return_url': returnUrl,
        if (paymentMode != null) 'payment_mode': paymentMode,
      };

      final response = await ApiService.post(
        '/api/subscriptions/purchase',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return PaymentResponse.fromJson(data);
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['detail'] ?? 'Ошибка создания платежа');
      }
    } catch (e) {
      throw Exception('Ошибка создания платежа: $e');
    }
  }

  /// Проверить статус конкретного платежа
  /// Требует авторизации
  static Future<PaymentStatus> checkPaymentStatus(String paymentUuid) async {
    try {
      final response = await ApiService.get(
        '/api/subscriptions/payment/$paymentUuid/status',
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return PaymentStatus.fromJson(data);
      } else {
        throw Exception('Ошибка проверки платежа: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка проверки статуса платежа: $e');
    }
  }

  /// Получить историю платежей пользователя
  /// Требует авторизации
  static Future<List<PaymentHistoryItem>> getHistory() async {
    try {
      final response = await ApiService.get('/api/subscriptions/history');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> payments = data['payments'];
        return payments
            .map((json) => PaymentHistoryItem.fromJson(json))
            .toList();
      } else {
        throw Exception('Ошибка загрузки истории: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки истории платежей: $e');
    }
  }

  /// Форматировать цену в рублях
  static String formatPrice(double amount) {
    return '${amount.toStringAsFixed(0)} ₽';
  }
}

