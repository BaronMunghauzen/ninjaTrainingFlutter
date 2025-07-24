class UserTrainingModel {
  final String uuid;
  final String trainingDate;
  final String status; // ACTIVE, PASSED, SKIPPED, BLOCKED_YET
  final int stage;
  final String? completedAt;
  final String? skippedAt;
  final UserProgramInfo userProgram;
  final ProgramInfo program;
  final TrainingInfo training;
  final UserInfo user;
  final int week;
  final int weekday;
  final bool isRestDay;

  UserTrainingModel({
    required this.uuid,
    required this.trainingDate,
    required this.status,
    required this.stage,
    this.completedAt,
    this.skippedAt,
    required this.userProgram,
    required this.program,
    required this.training,
    required this.user,
    required this.week,
    required this.weekday,
    required this.isRestDay,
  });

  factory UserTrainingModel.fromJson(Map<String, dynamic> json) {
    return UserTrainingModel(
      uuid: json['uuid'] ?? '',
      trainingDate: json['training_date'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      stage: json['stage'] ?? 1,
      completedAt: json['completed_at'],
      skippedAt: json['skipped_at'],
      userProgram: UserProgramInfo.fromJson(json['user_program'] ?? {}),
      program: ProgramInfo.fromJson(json['program'] ?? {}),
      training: TrainingInfo.fromJson(json['training'] ?? {}),
      user: UserInfo.fromJson(json['user'] ?? {}),
      week: json['week'] ?? 1,
      weekday: json['weekday'] ?? 1,
      isRestDay: json['is_rest_day'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'training_date': trainingDate,
      'status': status,
      'stage': stage,
      'completed_at': completedAt,
      'skipped_at': skippedAt,
      'user_program': userProgram.toJson(),
      'program': program.toJson(),
      'training': training.toJson(),
      'user': user.toJson(),
      'week': week,
      'weekday': weekday,
      'is_rest_day': isRestDay,
    };
  }

  // Вспомогательные методы для определения статуса
  bool get isActive => status.toLowerCase() == 'active';

  bool get isPassed => status.toLowerCase() == 'passed';
  bool get isSkipped => status.toLowerCase() == 'skipped';
  bool get isBlockedYet => status.toLowerCase() == 'blocked_yet';
  bool get isCompleted => isPassed || isSkipped;
  bool get isAvailable => isActive || isCompleted;
}

class UserProgramInfo {
  final String uuid;
  final int programId;
  final int userId;
  final String caption;
  final String status;
  final String? stoppedAt;
  final int stage;
  final String scheduleType;
  final String? trainingDays;
  final String? startDate;

  UserProgramInfo({
    required this.uuid,
    required this.programId,
    required this.userId,
    required this.caption,
    required this.status,
    this.stoppedAt,
    required this.stage,
    required this.scheduleType,
    this.trainingDays,
    this.startDate,
  });

  factory UserProgramInfo.fromJson(Map<String, dynamic> json) {
    return UserProgramInfo(
      uuid: json['uuid'] ?? '',
      programId: json['program_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      caption: json['caption'] ?? '',
      status: json['status'] ?? '',
      stoppedAt: json['stopped_at'],
      stage: json['stage'] ?? 1,
      scheduleType: json['schedule_type'] ?? '',
      trainingDays: json['training_days'],
      startDate: json['start_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'program_id': programId,
      'user_id': userId,
      'caption': caption,
      'status': status,
      'stopped_at': stoppedAt,
      'stage': stage,
      'schedule_type': scheduleType,
      'training_days': trainingDays,
      'start_date': startDate,
    };
  }
}

class ProgramInfo {
  final String uuid;
  final bool actual;
  final String programType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final int order;
  final String scheduleType;
  final String? trainingDays;

  ProgramInfo({
    required this.uuid,
    required this.actual,
    required this.programType,
    required this.caption,
    required this.description,
    required this.difficultyLevel,
    required this.order,
    required this.scheduleType,
    this.trainingDays,
  });

  factory ProgramInfo.fromJson(Map<String, dynamic> json) {
    return ProgramInfo(
      uuid: json['uuid'] ?? '',
      actual: json['actual'] ?? false,
      programType: json['program_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 1,
      order: json['order'] ?? 0,
      scheduleType: json['schedule_type'] ?? '',
      trainingDays: json['training_days'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'actual': actual,
      'program_type': programType,
      'caption': caption,
      'description': description,
      'difficulty_level': difficultyLevel,
      'order': order,
      'schedule_type': scheduleType,
      'training_days': trainingDays,
    };
  }
}

class TrainingInfo {
  final String uuid;
  final String trainingType;
  final String caption;
  final String description;
  final int difficultyLevel;
  final int duration;
  final int order;
  final String muscleGroup;
  final int stage;

  TrainingInfo({
    required this.uuid,
    required this.trainingType,
    required this.caption,
    required this.description,
    required this.difficultyLevel,
    required this.duration,
    required this.order,
    required this.muscleGroup,
    required this.stage,
  });

  factory TrainingInfo.fromJson(Map<String, dynamic> json) {
    return TrainingInfo(
      uuid: json['uuid'] ?? '',
      trainingType: json['training_type'] ?? '',
      caption: json['caption'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficulty_level'] ?? 1,
      duration: json['duration'] ?? 60,
      order: json['order'] ?? 0,
      muscleGroup: json['muscle_group'] ?? '',
      stage: json['stage'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'training_type': trainingType,
      'caption': caption,
      'description': description,
      'difficulty_level': difficultyLevel,
      'duration': duration,
      'order': order,
      'muscle_group': muscleGroup,
      'stage': stage,
    };
  }
}

class UserInfo {
  final String uuid;
  final String login;
  final String? phoneNumber;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? gender;
  final String? description;
  final String email;
  final String password;
  final bool isUser;
  final bool isAdmin;
  final String subscriptionStatus;
  final String? subscriptionUntil;
  final String theme;
  final String? avatarUuid;

  UserInfo({
    required this.uuid,
    required this.login,
    this.phoneNumber,
    this.firstName,
    this.middleName,
    this.lastName,
    this.gender,
    this.description,
    required this.email,
    required this.password,
    required this.isUser,
    required this.isAdmin,
    required this.subscriptionStatus,
    this.subscriptionUntil,
    required this.theme,
    this.avatarUuid,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      uuid: json['uuid'] ?? '',
      login: json['login'] ?? '',
      phoneNumber: json['phone_number'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      gender: json['gender'],
      description: json['description'],
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      isUser: json['is_user'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      subscriptionStatus: json['subscription_status'] ?? '',
      subscriptionUntil: json['subscription_until'],
      theme: json['theme'] ?? 'dark',
      avatarUuid: json['avatar_uuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'login': login,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'gender': gender,
      'description': description,
      'email': email,
      'password': password,
      'is_user': isUser,
      'is_admin': isAdmin,
      'subscription_status': subscriptionStatus,
      'subscription_until': subscriptionUntil,
      'theme': theme,
      'avatar_uuid': avatarUuid,
    };
  }
}
