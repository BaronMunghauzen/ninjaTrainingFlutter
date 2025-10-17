import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
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
  bool get isEmailVerified => _userProfile?.emailVerified ?? false;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('user_token');
      final userUuid = prefs.getString('user_uuid');

      print(
        'Checking auth status: token=${userToken != null ? 'exists' : 'null'}, uuid=${userUuid ?? 'null'}',
      );

      if (userToken != null && userToken.isNotEmpty) {
        _isAuthenticated = true;
        // Оптимизация: обновляем токен в API сервисе
        ApiService.updateToken(userToken);
        notifyListeners();

        print('User authenticated, loading profile...');
        // Загружаем профиль пользователя для проверки подтверждения почты
        await fetchUserProfile();
      } else {
        print('No valid token found, user not authenticated');
        // Убеждаемся, что состояние не аутентифицировано
        _isAuthenticated = false;
        _userUuid = null;
        _userProfile = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking auth status: $e');
      // При ошибке также сбрасываем состояние
      _isAuthenticated = false;
      _userUuid = null;
      _userProfile = null;
      notifyListeners();
    }
  }

  // Старые методы для совместимости
  Future<String?> signIn(String username, String password) async {
    try {
      final success = await login(username, password);
      if (success) {
        // После успешного входа проверяем подтверждение почты
        await fetchUserProfile();
        return null;
      } else {
        return 'Неверные учетные данные';
      }
    } on NetworkException {
      // Пробрасываем ошибку сети дальше
      rethrow;
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
        // Успешная регистрация - сохраняем токен
        final data = ApiService.decodeJson(response.body);
        final userToken = data['access_token'];

        if (userToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', userToken);

          print('Registration successful: token saved');

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
    } on NetworkException {
      // Пробрасываем ошибку сети дальше
      rethrow;
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
      final body = {'user_identity': username, 'password': password};

      final response = await ApiService.post('/auth/login/', body: body);

      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final userToken = data['access_token'];

        if (userToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_token', userToken);

          print('Login successful: token saved');

          _isAuthenticated = true;

          // Оптимизация: обновляем токен в API сервисе
          ApiService.updateToken(userToken);

          // Загружаем профиль пользователя для получения UUID
          await fetchUserProfile();
          return true;
        }
      }
      return false;
    } on NetworkException catch (e) {
      print('Network error during login: $e');
      // Пробрасываем ошибку дальше для отображения в UI
      rethrow;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    print('Logging out user...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_uuid');

    _isAuthenticated = false;
    _userUuid = null;
    _userProfile = null;

    // Оптимизация: очищаем токен в API сервисе
    ApiService.updateToken(null);

    print('User logged out successfully');
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
          // Сохраняем UUID в SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_uuid', data['uuid']);
        }
        // Устанавливаем флаг аутентификации при успешном получении профиля
        _isAuthenticated = true;
        print('User profile loaded successfully, user is now authenticated');

        // Обновляем FCM токен после успешного входа
        try {
          await FCMService.getToken(); // Автоматически отправит на сервер
          print('FCM токен обновлен при входе');

          // Дополнительная проверка токена при входе
          await FCMService.checkAndUpdateToken();
          print('FCM токен дополнительно проверен при входе');
        } catch (e) {
          print('Ошибка обновления FCM токена: $e');
        }

        // Проверяем FCM токен в профиле пользователя
        if (data['fcm_token'] == null) {
          print('🔔 FCM токен отсутствует в профиле, обновляем...');
          try {
            await FCMService.forceRefreshToken(); // Принудительно обновляем токен
            print('🔔 FCM токен принудительно обновлен');
          } catch (e) {
            print('🔔 Ошибка принудительного обновления FCM токена: $e');
          }
        } else {
          print(
            '🔔 FCM токен присутствует в профиле: ${data['fcm_token']?.substring(0, 20)}...',
          );
        }

        notifyListeners();
      } else if (response.statusCode == 401) {
        // Если токен недействителен, выходим из системы
        await logout();
      }
    } on NetworkException catch (e) {
      print('Network error fetching user profile: $e');
      // При ошибках сети не сбрасываем состояние аутентификации
      // Пользователь может работать с кэшированными данными
    } catch (e) {
      print('Error fetching user profile: $e');
      // При ошибках сети не сбрасываем состояние аутентификации
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
      if (username != null) body['login'] = username;
      if (email != null) body['email'] = email;
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (middleName != null) body['middle_name'] = middleName;
      if (gender != null) body['gender'] = gender;
      if (description != null) body['description'] = description;

      final response = await ApiService.put(
        '/auth/update/$_userUuid',
        body: body,
      );

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

  Future<String?> updateEmail(String email) async {
    if (_userUuid == null) return 'Пользователь не найден';

    try {
      final response = await ApiService.put(
        '/auth/update/$_userUuid',
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        await fetchUserProfile();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка обновления email';
      }
    } catch (e) {
      return 'Ошибка обновления email: $e';
    }
  }

  Future<String?> resendVerificationEmail(String email) async {
    if (_userUuid == null) return 'Пользователь не найден';

    try {
      final response = await ApiService.post(
        '/auth/resend-verification/?email=$email',
        body: {},
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка отправки письма';
      }
    } catch (e) {
      return 'Ошибка отправки письма: $e';
    }
  }

  Future<String?> deleteAvatar() async {
    if (_userUuid == null) return 'Пользователь не найден';

    try {
      final response = await ApiService.delete('/auth/avatar/$_userUuid');

      if (response.statusCode == 200) {
        // Обновляем профиль без уведомления слушателей, чтобы избежать перехода
        await _updateUserProfileSilently();
        // Принудительно уведомляем слушателей для обновления UI
        notifyListeners();
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
        '/auth/upload/avatar/$_userUuid',
        fileField: 'file',
        filePath: tempFile.path,
        mimeType: mimeType,
      );
      if (response.statusCode == 200) {
        // Обновляем профиль без уведомления слушателей, чтобы избежать перехода
        await _updateUserProfileSilently();
        // Принудительно уведомляем слушателей для обновления UI
        notifyListeners();
        return null;
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка загрузки аватара';
      }
    } catch (e) {
      return 'Ошибка загрузки аватара: $e';
    }
  }

  /// Обновляет профиль пользователя без уведомления слушателей
  Future<void> _updateUserProfileSilently() async {
    try {
      final response = await ApiService.get('/auth/me/');
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        final newProfile = UserModel.fromJson(data);

        // Проверяем, изменились ли данные
        final hasChanges =
            _userProfile?.avatarUuid != newProfile.avatarUuid ||
            _userProfile?.email != newProfile.email ||
            _userProfile?.firstName != newProfile.firstName ||
            _userProfile?.lastName != newProfile.lastName;

        _userProfile = newProfile;

        // Обновляем userUuid если оно есть в ответе
        if (data['uuid'] != null) {
          _userUuid = data['uuid'];
          // Сохраняем UUID в SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_uuid', data['uuid']);
        }

        // Логируем изменения для отладки
        if (hasChanges) {
          print('Profile updated: avatarUuid=${newProfile.avatarUuid}');
        }

        // Проверяем FCM токен в профиле пользователя
        if (data['fcm_token'] == null) {
          print('🔔 FCM токен отсутствует в профиле, обновляем...');
          try {
            await FCMService.forceRefreshToken(); // Принудительно обновляем токен
            print('🔔 FCM токен принудительно обновлен');
          } catch (e) {
            print('🔔 Ошибка принудительного обновления FCM токена: $e');
          }
        }

        // НЕ вызываем notifyListeners() чтобы избежать перехода
      } else if (response.statusCode == 401) {
        // Если токен недействителен, выходим из системы
        await logout();
      }
    } catch (e) {
      print('Error updating user profile silently: $e');
    }
  }

  /// Публичный метод для обновления профиля без уведомления слушателей
  Future<bool> refreshUserProfileSilently() async {
    try {
      await _updateUserProfileSilently();
      return true;
    } catch (e) {
      print('Error refreshing profile silently: $e');
      return false;
    }
  }

  /// Отправить email для сброса пароля
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      final response = await ApiService.post(
        '/auth/forgot-password/',
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        return null; // Успешно отправлено
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка отправки письма';
      }
    } catch (e) {
      return 'Ошибка отправки письма: $e';
    }
  }

  /// Сбросить пароль по коду
  Future<String?> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post(
        '/auth/reset-password/',
        body: {'email': email, 'code': code, 'new_password': newPassword},
      );

      if (response.statusCode == 200) {
        return null; // Успешно сброшен
      } else {
        final data = ApiService.decodeJson(response.body);
        return data['detail']?.toString() ?? 'Ошибка сброса пароля';
      }
    } catch (e) {
      return 'Ошибка сброса пароля: $e';
    }
  }
}
