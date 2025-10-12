import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../constants/api_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';

/// Исключение для ошибок сети
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _logPrefix = '🌐 API';

  // Кэш токена для избежания повторных обращений к SharedPreferences
  static String? _cachedToken;
  static bool _tokenInitialized = false;

  // Кэш файлов в памяти для быстрого доступа
  static final Map<String, Uint8List> _fileCache = {};

  // Кэш метаданных файлов (размер, время загрузки)
  static final Map<String, Map<String, dynamic>> _fileMetadata = {};

  /// Получить путь к директории кэша
  static Future<String> get _cacheDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/file_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  /// Создать хеш для UUID файла (для безопасного имени файла)
  static String _createFileHash(String uuid) {
    return sha256.convert(utf8.encode(uuid)).toString();
  }

  /// Получить путь к кэшированному файлу
  static Future<String> _getCachedFilePath(String uuid) async {
    final cacheDir = await _cacheDirectory;
    final fileHash = _createFileHash(uuid);
    return '$cacheDir/$fileHash';
  }

  /// Проверить, есть ли файл в кэше
  static Future<bool> _isFileCached(String uuid) async {
    // Сначала проверяем память
    if (_fileCache.containsKey(uuid)) {
      return true;
    }

    // Затем проверяем диск
    final filePath = await _getCachedFilePath(uuid);
    final file = File(filePath);
    return await file.exists();
  }

  /// Получить файл из кэша
  static Future<Uint8List?> _getCachedFile(String uuid) async {
    // Сначала проверяем память
    if (_fileCache.containsKey(uuid)) {
      return _fileCache[uuid];
    }

    // Затем проверяем диск
    final filePath = await _getCachedFilePath(uuid);
    final file = File(filePath);
    if (await file.exists()) {
      try {
        final bytes = await file.readAsBytes();
        // Добавляем в память для быстрого доступа
        _fileCache[uuid] = bytes;
        return bytes;
      } catch (e) {
        print('$_logPrefix ❌ Ошибка чтения кэшированного файла: $e');
        return null;
      }
    }

    return null;
  }

  /// Сохранить файл в кэш
  static Future<void> _saveFileToCache(String uuid, Uint8List bytes) async {
    try {
      // Сохраняем в память
      _fileCache[uuid] = bytes;

      // Сохраняем на диск
      final filePath = await _getCachedFilePath(uuid);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Обновляем метаданные
      _fileMetadata[uuid] = {
        'size': bytes.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'path': filePath,
      };

      print('$_logPrefix 💾 Файл $uuid сохранен в кэш (${bytes.length} байт)');
    } catch (e) {
      print('$_logPrefix ❌ Ошибка сохранения файла в кэш: $e');
    }
  }

  /// Очистить кэш файлов
  static Future<void> clearFileCache() async {
    try {
      // Очищаем память
      _fileCache.clear();
      _fileMetadata.clear();

      // Очищаем диск
      final cacheDir = await _cacheDirectory;
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }

      print('$_logPrefix 🗑️ Кэш файлов очищен');
    } catch (e) {
      print('$_logPrefix ❌ Ошибка очистки кэша: $e');
    }
  }

  /// Получить размер кэша
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _cacheDirectory;
      final dir = Directory(cacheDir);
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('$_logPrefix ❌ Ошибка получения размера кэша: $e');
      return 0;
    }
  }

  /// Загрузить файл с кэшированием по UUID
  static Future<Uint8List?> getFile(
    String uuid, {
    bool forceRefresh = false,
  }) async {
    if (uuid.isEmpty) return null;

    try {
      // Проверяем кэш, если не требуется принудительное обновление
      if (!forceRefresh) {
        final cachedFile = await _getCachedFile(uuid);
        if (cachedFile != null) {
          print('$_logPrefix 📁 Файл $uuid загружен из кэша');
          return cachedFile;
        }
      }

      // Загружаем файл с сервера
      print('$_logPrefix 📥 Загружаем файл $uuid с сервера...');
      final response = await get('/files/file/$uuid');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Сохраняем в кэш
        await _saveFileToCache(uuid, bytes);

        print('$_logPrefix ✅ Файл $uuid успешно загружен и сохранен в кэш');
        return bytes;
      } else {
        print(
          '$_logPrefix ❌ Ошибка загрузки файла $uuid: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('$_logPrefix ❌ Ошибка при работе с файлом $uuid: $e');
      return null;
    }
  }

  /// Получить ImageProvider для изображения с кэшированием
  static Future<ImageProvider?> getImageProvider(
    String uuid, {
    bool forceRefresh = false,
  }) async {
    final bytes = await getFile(uuid, forceRefresh: forceRefresh);
    if (bytes != null) {
      return MemoryImage(bytes);
    }
    return null;
  }

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
    String uri;
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      // Если endpoint уже содержит полный URL, используем его как есть
      uri = endpoint;
    } else {
      // Иначе добавляем базовый URL
      uri = '${ApiConstants.baseUrl}$endpoint';
    }

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
    String uri;
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      // Если endpoint уже содержит полный URL, используем его как есть
      uri = endpoint;
    } else {
      // Иначе добавляем базовый URL
      uri = '${ApiConstants.baseUrl}$endpoint';
    }

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

      // Обработка ошибок сети
      if (e is SocketException) {
        throw NetworkException(
          'Нет подключения к интернету. Проверьте сетевое соединение.',
        );
      } else if (e is TimeoutException) {
        throw NetworkException(
          'Превышено время ожидания. Проверьте подключение к интернету.',
        );
      } else if (e is HttpException) {
        throw NetworkException('Ошибка HTTP соединения.');
      }

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

  /// Метод для загрузки файлов
  static Future<http.Response> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? additionalFields,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await initializeToken();

      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      // Создаем multipart request
      final request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки авторизации
      if (_cachedToken != null) {
        request.headers['Cookie'] = 'users_access_token=$_cachedToken';
      }

      // Определяем MIME тип файла на основе расширения
      String? mimeType;
      final extension = file.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        case 'avi':
          mimeType = 'video/x-msvideo';
          break;
        case 'mkv':
          mimeType = 'video/x-matroska';
          break;
      }

      // Добавляем файл с правильным MIME типом
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);

      // Добавляем дополнительные поля
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Логируем запрос
      _logRequest(
        method: 'POST',
        uri: uri.toString(),
        headers: request.headers,
        body: 'Multipart file upload: ${file.path} (MIME: $mimeType)',
      );

      // Отправляем запрос
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      // Логируем ответ
      _logResponse(
        method: 'POST',
        uri: uri.toString(),
        statusCode: response.statusCode,
        headers: response.headers,
        body: response.body,
      );

      return response;
    } catch (e) {
      _logError(
        method: 'POST',
        uri: '${ApiConstants.baseUrl}$endpoint',
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Получить данные справочника упражнения
  static Future<Map<String, dynamic>?> getExerciseReference(
    String exerciseReferenceUuid,
  ) async {
    try {
      final response = await get('/exercise_reference/$exerciseReferenceUuid');
      if (response.statusCode == 200) {
        return decodeJson(response.body);
      } else {
        print(
          '$_logPrefix ❌ Ошибка получения справочника упражнения: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('$_logPrefix ❌ Ошибка при получении справочника упражнения: $e');
      return null;
    }
  }

  /// Получить статистику упражнения для пользователя
  static Future<Map<String, dynamic>?> getExerciseStatistics(
    String exerciseReferenceUuid,
    String userUuid,
  ) async {
    try {
      final response = await get(
        '/exercise_reference/$exerciseReferenceUuid/statistics/$userUuid',
      );
      if (response.statusCode == 200) {
        return decodeJson(response.body);
      } else {
        print(
          '$_logPrefix ❌ Ошибка получения статистики упражнения: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('$_logPrefix ❌ Ошибка при получении статистики упражнения: $e');
      return null;
    }
  }

  /// Вспомогательный метод для получения базового URL
  static String get baseUrl => ApiConstants.baseUrl;
}
