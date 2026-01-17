import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_status_model.dart';
import '../models/payment_model.dart';
import 'api_service.dart';

/// Кастомный класс исключения для SubscriptionService
/// Позволяет извлечь сообщение без префикса "Exception: "
class _SubscriptionServiceException implements Exception {
  final String message;
  _SubscriptionServiceException(this.message);
  
  @override
  String toString() => message;
}

class SubscriptionService {
  /// Получить список всех доступных тарифных планов
  /// НЕ требует авторизации
  /// [promoCode] - опциональный промокод для применения скидки
  static Future<List<SubscriptionPlan>> getPlans({String? promoCode}) async {
    const String _logPrefix = '🌐 API';
    var uri = Uri.parse('${ApiConstants.baseUrl}/api/subscriptions/plans');
    
    // Добавляем промокод как query параметр, если он указан
    if (promoCode != null && promoCode.isNotEmpty) {
      uri = uri.replace(queryParameters: {'promo_code': promoCode});
    }
    
    final headers = {'Content-Type': 'application/json'};
    
    try {
      // Логирование запроса
      final timestamp = DateTime.now().toIso8601String();
      print('$_logPrefix ================================================================================');
      print('$_logPrefix 🕐 ВРЕМЯ: $timestamp');
      print('$_logPrefix 📡 МЕТОД: GET');
      print('$_logPrefix 🌐 URI: $uri');
      print('$_logPrefix 📋 ЗАГОЛОВКИ:');
      headers.forEach((key, value) {
        print('$_logPrefix    $key: $value');
      });
      print('$_logPrefix ================================================================================');
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      // Логирование ответа
      final responseHeaders = <String, String>{};
      response.headers.forEach((key, value) {
        responseHeaders[key] = value;
      });
      final responseBody = utf8.decode(response.bodyBytes);
      
      print('$_logPrefix ================================================================================');
      print('$_logPrefix 📥 ОТВЕТ API (GET):');
      print('$_logPrefix 📊 СТАТУС: ${response.statusCode}');
      if (responseHeaders.isNotEmpty) {
        print('$_logPrefix 📋 ЗАГОЛОВКИ ОТВЕТА:');
        responseHeaders.forEach((key, value) {
          print('$_logPrefix    $key: $value');
        });
      }
      print('$_logPrefix 📦 ТЕЛО ОТВЕТА:');
      print('$_logPrefix    $responseBody');
      print('$_logPrefix ================================================================================');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(responseBody);
        return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
      } else {
        // Пытаемся извлечь сообщение об ошибке из поля detail
        String errorMessage = 'Ошибка загрузки тарифов: ${response.statusCode}';
        try {
          final errorData = json.decode(responseBody);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'] as String;
          }
        } catch (_) {
          // Если не удалось распарсить, используем стандартное сообщение
        }
        // Используем кастомный класс исключения, чтобы можно было извлечь только сообщение
        throw _SubscriptionServiceException(errorMessage);
      }
    } catch (e) {
      // Логирование ошибки
      final errorTimestamp = DateTime.now().toIso8601String();
      print('$_logPrefix ================================================================================');
      print('$_logPrefix ❌ ОШИБКА API (GET):');
      print('$_logPrefix 🕐 ВРЕМЯ: $errorTimestamp');
      print('$_logPrefix 🌐 URI: $uri');
      print('$_logPrefix 💥 ОШИБКА: $e');
      print('$_logPrefix ================================================================================');
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
    String? promoCode,
  }) async {
    try {
      final body = {
        'plan_uuid': planUuid,
        if (returnUrl != null) 'return_url': returnUrl,
        if (paymentMode != null) 'payment_mode': paymentMode,
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
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

