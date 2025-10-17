class UserModel {
  final String subscriptionStatus;
  final int? id;
  final String uuid;
  final DateTime? subscriptionUntil;
  final String? phoneNumber;
  final String? firstName;
  final String theme;
  final String? lastName;
  final String email;
  final String login;
  final bool isUser;
  final String? middleName;
  final String? gender;
  final bool isAdmin;
  final DateTime? createdAt;
  final String? description;
  final DateTime? updatedAt;
  final String? avatarUuid;
  final bool emailVerified;
  final String? fcmToken; // Добавляем поле для FCM токена

  UserModel({
    required this.subscriptionStatus,
    this.id,
    required this.uuid,
    this.subscriptionUntil,
    this.phoneNumber,
    this.firstName,
    required this.theme,
    this.lastName,
    required this.email,
    required this.login,
    required this.isUser,
    this.middleName,
    this.gender,
    required this.isAdmin,
    this.createdAt,
    this.description,
    this.updatedAt,
    this.avatarUuid,
    required this.emailVerified,
    this.fcmToken, // Добавляем в конструктор
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      subscriptionStatus: json['subscription_status'] ?? '',
      id: json['id'],
      uuid: json['uuid'] ?? '',
      subscriptionUntil: json['subscription_until'] != null
          ? DateTime.parse(json['subscription_until'])
          : null,
      phoneNumber: json['phone_number'],
      firstName: json['first_name'],
      theme: json['theme'] ?? 'dark',
      lastName: json['last_name'],
      email: json['email'] ?? '',
      login: json['login'] ?? '',
      isUser: json['is_user'] ?? false,
      middleName: json['middle_name'],
      gender: json['gender'],
      isAdmin: json['is_admin'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      description: json['description'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      avatarUuid: json['avatar_uuid'],
      emailVerified: json['email_verified'] ?? false,
      fcmToken: json['fcm_token'], // Парсим FCM токен
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_status': subscriptionStatus,
      'id': id,
      'uuid': uuid,
      'subscription_until': subscriptionUntil?.toIso8601String(),
      'phone_number': phoneNumber,
      'first_name': firstName,
      'theme': theme,
      'last_name': lastName,
      'email': email,
      'login': login,
      'is_user': isUser,
      'middle_name': middleName,
      'gender': gender,
      'is_admin': isAdmin,
      'created_at': createdAt?.toIso8601String(),
      'description': description,
      'updated_at': updatedAt?.toIso8601String(),
      'avatar_uuid': avatarUuid,
      'email_verified': emailVerified,
      'fcm_token': fcmToken, // Добавляем в JSON
    };
  }

  // Метод для создания копии с измененными полями
  UserModel copyWith({
    String? subscriptionStatus,
    int? id,
    String? uuid,
    DateTime? subscriptionUntil,
    String? phoneNumber,
    String? firstName,
    String? theme,
    String? lastName,
    String? email,
    String? login,
    bool? isUser,
    String? middleName,
    String? gender,
    bool? isAdmin,
    DateTime? createdAt,
    String? description,
    DateTime? updatedAt,
    String? avatarUuid,
    bool? emailVerified,
    String? fcmToken, // Добавляем в copyWith
  }) {
    return UserModel(
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      subscriptionUntil: subscriptionUntil ?? this.subscriptionUntil,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      theme: theme ?? this.theme,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      login: login ?? this.login,
      isUser: isUser ?? this.isUser,
      middleName: middleName ?? this.middleName,
      gender: gender ?? this.gender,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUuid: avatarUuid ?? this.avatarUuid,
      emailVerified: emailVerified ?? this.emailVerified,
      fcmToken: fcmToken ?? this.fcmToken, // Добавляем в copyWith
    );
  }
}
