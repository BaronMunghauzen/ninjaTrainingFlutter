class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Auth endpoints
  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register/';

  // User profile endpoints
  static const String getMeUrl = '$baseUrl/auth/me';
  static String updateUserUrl(String uuid) => '$baseUrl/auth/update/$uuid';

  // File/Avatar endpoints
  static String getFileUrl(String fileUuid) => '$baseUrl/files/file/$fileUuid';
  static String uploadAvatarUrl(String userUuid) =>
      '$baseUrl/files/upload/avatar/$userUuid';
  static String deleteFileUrl(String fileUuid) =>
      '$baseUrl/files/file/$fileUuid';

  static String getLastUserExercisesUrl() =>
      '$baseUrl/user_exercises/utils/getLastUserExercises';
}
