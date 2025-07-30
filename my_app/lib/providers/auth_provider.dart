import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userUuid;
  UserModel? _userProfile;
  bool _isLoadingProfile = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userUuid => _userUuid;
  UserModel? get userProfile => _userProfile;
  bool get isLoadingProfile => _isLoadingProfile;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('user_token');
    final userUuid = prefs.getString('user_uuid');

    if (userToken != null && userToken.isNotEmpty && userUuid != null) {
      _isAuthenticated = true;
      _userUuid = userUuid;
      // Оптимизация: обновляем токен в API сервисе
      ApiService.updateToken(userToken);
      notifyListeners();
    }
  }

  // Старые методы для совместимости
  Future<String?> signIn(String username, String password) async {
    try {
      final success = await login(username, password);
      return success ? null : 'Неверные учетные данные';
    } catch (e) {
      return 'Ошибка входа: $e';
    }
  }

  Future<String?> signUp(
    String email,
    String username,
    String password,
    String confirmPassword,
  ) async {
    try {
      if (password != confirmPassword) {
        return 'Пароли не совпадают';
      }

      final body = {'login': username, 'email': email, 'password': password};

      final response = await ApiService.post('/auth/register/', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Успешная регистрация - сохраняем токен и UUID
        final data = ApiService.decodeJson(response.body);
        final userToken = data['access_token'];
        final userUuid = data['user_uuid'];

        if (userToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', userToken);

          // Если user_uuid нет в ответе, попробуем получить его из токена или запросить профиль
          if (userUuid != null) {
            await prefs.setString('user_uuid', userUuid);
            _userUuid = userUuid;
          }

          _isAuthenticated = true;
          ApiService.updateToken(userToken);
          notifyListeners();

          // Загружаем профиль пользователя для получения UUID
          await fetchUserProfile();
        }

        return null; // Успешная регистрация
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка регистрации';
      }
    } catch (e) {
      return 'Ошибка регистрации: $e';
    }
  }

  Future<void> signOut() async {
    await logout();
  }

  // Методы валидации
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidLogin(String login) {
    return login.length >= 3 && login.length <= 50;
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  Future<bool> login(String username, String password) async {
    try {
      final body = {'login': username, 'password': password};

      final response = await ApiService.post('/auth/login/', body: body);

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final userToken = data['access_token'];
        final userUuid = data['user_uuid'];

        if (userToken != null && userUuid != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', userToken);
          await prefs.setString('user_uuid', userUuid);

          _isAuthenticated = true;
          _userUuid = userUuid;

          // Оптимизация: обновляем токен в API сервисе
          ApiService.updateToken(userToken);

          notifyListeners();

          // Загружаем профиль пользователя
          await fetchUserProfile();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_uuid');

    _isAuthenticated = false;
    _userUuid = null;
    _userProfile = null;

    // Оптимизация: очищаем токен в API сервисе
    ApiService.updateToken(null);

    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    _isLoadingProfile = true;
    notifyListeners();
    try {
      final response = await ApiService.get('/auth/me/');
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        _userProfile = UserModel.fromJson(data);
        // Обновляем userUuid если оно есть в ответе
        if (data['uuid'] != null) {
          _userUuid = data['uuid'];
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<String?> updateUserProfile({
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? middleName,
    String? gender,
    String? description,
  }) async {
    if (_userUuid == null) return 'Пользователь не найден';

    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (middleName != null) body['middle_name'] = middleName;
      if (gender != null) body['gender'] = gender;
      if (description != null) body['description'] = description;

      final response = await ApiService.put('/users/$_userUuid', body: body);

      if (response.statusCode == 200) {
        await fetchUserProfile();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка обновления профиля';
      }
    } catch (e) {
      return 'Ошибка обновления профиля: $e';
    }
  }

  Future<String?> deleteAvatar() async {
    if (_userUuid == null) return 'Пользователь не найден';

    try {
      final response = await ApiService.delete('/users/$_userUuid/avatar');

      if (response.statusCode == 200) {
        await fetchUserProfile();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка удаления аватара';
      }
    } catch (e) {
      return 'Ошибка удаления аватара: $e';
    }
  }

  Future<String?> uploadAvatar(List<int> fileBytes, String fileName) async {
    if (_userUuid == null) return 'Пользователь не найден';
    try {
      // Определяем mime-type
      String? mimeType;
      if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      }
      // Сохраняем файл во временное хранилище
      // (т.к. multipart требует путь к файлу)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(fileBytes);
      final response = await ApiService.multipart(
        '/users/$_userUuid/upload-avatar',
        fileField: 'file',
        filePath: tempFile.path,
        mimeType: mimeType,
      );
      if (response.statusCode == 200) {
        await fetchUserProfile();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка загрузки аватара';
      }
    } catch (e) {
      return 'Ошибка загрузки аватара: $e';
    }
  }
}
