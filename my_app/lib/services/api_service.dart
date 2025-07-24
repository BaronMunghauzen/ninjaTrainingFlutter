import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String _logPrefix = '🌐 API';

  // Кэш токена для избежания повторных обращений к SharedPreferences
  static String? _cachedToken;
  static bool _tokenInitialized = false;

  /// Инициализация токена (вызывается при старте приложения)
  static Future<void> initializeToken() async {
    if (!_tokenInitialized) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('user_token');
      _tokenInitialized = true;
    }
  }

  /// Обновление токена (вызывается при логине/логауте)
  static void updateToken(String? token) {
    _cachedToken = token;
  }

  /// Единый метод для GET запросов
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    return _makeRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
    );
  }

  /// Единый метод для POST запросов
  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    return _makeRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParams: queryParams,
      timeout: timeout,
    );
  }

  /// Единый метод для PUT запросов
  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    return _makeRequest(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParams: queryParams,
      timeout: timeout,
    );
  }

  /// Единый метод для DELETE запросов
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    return _makeRequest(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
    );
  }

  /// Единый метод для PATCH запросов
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    return _makeRequest(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParams: queryParams,
      timeout: timeout,
    );
  }

  /// Единый метод для multipart/form-data (загрузка файлов)
  static Future<http.Response> multipart(
    String endpoint, {
    required String fileField,
    required String filePath,
    String? mimeType,
    Map<String, String>? fields,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    // Убеждаемся, что токен инициализирован
    if (!_tokenInitialized) {
      await initializeToken();
    }

    // Формируем базовые заголовки
    final requestHeaders = <String, String>{...?headers};
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      requestHeaders['Cookie'] = 'users_access_token=$_cachedToken';
    }

    // Формируем URI с query параметрами
    String uri = '${ApiConstants.baseUrl}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      uri += '?$queryString';
    }

    // Логируем запрос
    _logRequest(
      method: 'POST (multipart)',
      uri: uri,
      headers: requestHeaders,
      body: 'file: $filePath, fields: $fields',
    );

    final request = http.MultipartRequest('POST', Uri.parse(uri));
    request.headers.addAll(requestHeaders);
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        filePath,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ),
    );

    http.StreamedResponse streamedResponse;
    http.Response response;
    try {
      streamedResponse = await request.send().timeout(timeout);
      response = await http.Response.fromStream(streamedResponse);
    } catch (e) {
      _logError(method: 'POST (multipart)', uri: uri, error: e.toString());
      rethrow;
    }

    _logResponse(
      method: 'POST (multipart)',
      uri: uri,
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
    );

    return response;
  }

  /// Внутренний метод для выполнения всех HTTP запросов
  static Future<http.Response> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    // Убеждаемся, что токен инициализирован
    if (!_tokenInitialized) {
      await initializeToken();
    }

    // Формируем базовые заголовки
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Добавляем токен в заголовки, если он есть
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      requestHeaders['Cookie'] = 'users_access_token=$_cachedToken';
    }

    // Формируем URI с query параметрами
    String uri = '${ApiConstants.baseUrl}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      uri += '?$queryString';
    }

    // Подготавливаем body
    String? requestBody;
    if (body != null) {
      requestBody = jsonEncode(body);
    }

    // Логируем запрос
    _logRequest(
      method: method,
      uri: uri,
      headers: requestHeaders,
      body: requestBody,
    );

    // Выполняем запрос
    http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(Uri.parse(uri), headers: requestHeaders)
              .timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(Uri.parse(uri), headers: requestHeaders, body: requestBody)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(Uri.parse(uri), headers: requestHeaders, body: requestBody)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(Uri.parse(uri), headers: requestHeaders)
              .timeout(timeout);
          break;
        case 'PATCH':
          response = await http
              .patch(Uri.parse(uri), headers: requestHeaders, body: requestBody)
              .timeout(timeout);
          break;
        default:
          throw ArgumentError('Неподдерживаемый HTTP метод: $method');
      }
    } catch (e) {
      _logError(method: method, uri: uri, error: e.toString());
      rethrow;
    }

    // Логируем ответ
    _logResponse(
      method: method,
      uri: uri,
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
    );

    return response;
  }

  /// Логирование запроса
  static void _logRequest({
    required String method,
    required String uri,
    required Map<String, String> headers,
    String? body,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    print(
      '$_logPrefix ================================================================================',
    );
    print('$_logPrefix 🕐 ВРЕМЯ: $timestamp');
    print('$_logPrefix 📡 МЕТОД: $method');
    print('$_logPrefix 🌐 URI: $uri');
    print('$_logPrefix 📋 ЗАГОЛОВКИ:');
    headers.forEach((key, value) {
      print('$_logPrefix    $key: $value');
    });
    if (body != null) {
      print('$_logPrefix 📦 ТЕЛО ЗАПРОСА:');
      print('$_logPrefix    $body');
    }
    print(
      '$_logPrefix ================================================================================',
    );
  }

  /// Логирование ответа
  static void _logResponse({
    required String method,
    required String uri,
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    print(
      '$_logPrefix ================================================================================',
    );
    print('$_logPrefix 📥 ОТВЕТ API ($method):');
    print('$_logPrefix 📊 СТАТУС: $statusCode');
    if (headers.isNotEmpty) {
      print('$_logPrefix 📋 ЗАГОЛОВКИ ОТВЕТА:');
      headers.forEach((key, value) {
        print('$_logPrefix    $key: $value');
      });
    }
    print('$_logPrefix 📦 ТЕЛО ОТВЕТА:');
    print('$_logPrefix    $body');
    print(
      '$_logPrefix ================================================================================',
    );
  }

  /// Логирование ошибки
  static void _logError({
    required String method,
    required String uri,
    required String error,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    print(
      '$_logPrefix ================================================================================',
    );
    print('$_logPrefix ❌ ОШИБКА API ($method):');
    print('$_logPrefix 🕐 ВРЕМЯ: $timestamp');
    print('$_logPrefix 🌐 URI: $uri');
    print('$_logPrefix 💥 ОШИБКА: $error');
    print(
      '$_logPrefix ================================================================================',
    );
  }

  /// Вспомогательный метод для декодирования JSON ответа
  static dynamic decodeJson(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('$_logPrefix ❌ Ошибка декодирования JSON: $e');
      print('$_logPrefix 📦 Строка JSON: $jsonString');
      rethrow;
    }
  }

  /// Вспомогательный метод для получения базового URL
  static String get baseUrl => ApiConstants.baseUrl;
}
