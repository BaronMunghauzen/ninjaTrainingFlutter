class ApiConstants {
  static const String baseUrl =
      'http://10.0.2.2:8000'; //Локальный IP на эмуляторе
  // static const String baseUrl =
  //     'https://ninjatraining.ru'; //IP сервера продакшена

  // Auth endpoints
  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register/';

  // User profile endpoints
  static const String getMeUrl = '$baseUrl/auth/me';
  static String updateUserUrl(String uuid) => '$baseUrl/auth/update/$uuid';

  // File/Avatar endpoints
  static String getFileUrl(String fileUuid) => '$baseUrl/files/file/$fileUuid';
  static String uploadAvatarUrl(String userUuid) =>
      '$baseUrl/auth/upload/avatar/$userUuid';
  static String deleteFileUrl(String fileUuid) =>
      '$baseUrl/files/file/$fileUuid';

  static String getLastUserExercisesUrl() =>
      '$baseUrl/user_exercises/utils/getLastUserExercises';

  // Subscription endpoints
  static const String subscriptionPlansUrl = '$baseUrl/api/subscriptions/plans';
  static const String subscriptionStatusUrl =
      '$baseUrl/api/subscriptions/status';
  static const String activateTrialUrl =
      '$baseUrl/api/subscriptions/activate-trial';
  static const String createPaymentUrl = '$baseUrl/api/subscriptions/purchase';
  static String paymentStatusUrl(String paymentUuid) =>
      '$baseUrl/api/subscriptions/payment/$paymentUuid/status';
  static const String paymentHistoryUrl = '$baseUrl/api/subscriptions/history';
}
