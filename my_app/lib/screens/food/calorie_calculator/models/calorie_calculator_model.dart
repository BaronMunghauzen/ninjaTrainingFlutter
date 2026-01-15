class CalorieCalculation {
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool actual;
  final String userUuid;
  final String goal;
  final String gender;
  final double weight;
  final double height;
  final int age;
  final String activityCoefficient;
  final double bmr;
  final double tdee;
  final MacroValues? caloriesForWeightLoss;
  final MacroValues? caloriesForGain;
  final MacroValues? caloriesForMaintenance;

  CalorieCalculation({
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.actual,
    required this.userUuid,
    required this.goal,
    required this.gender,
    required this.weight,
    required this.height,
    required this.age,
    required this.activityCoefficient,
    required this.bmr,
    required this.tdee,
    this.caloriesForWeightLoss,
    this.caloriesForGain,
    this.caloriesForMaintenance,
  });

  factory CalorieCalculation.fromJson(Map<String, dynamic> json) {
    return CalorieCalculation(
      uuid: json['uuid'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      actual: json['actual'] as bool,
      userUuid: json['user_uuid'] as String,
      goal: json['goal'] as String,
      gender: json['gender'] as String,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      age: json['age'] as int,
      activityCoefficient: json['activity_coefficient'] as String,
      bmr: (json['bmr'] as num).toDouble(),
      tdee: (json['tdee'] as num).toDouble(),
      caloriesForWeightLoss: json['calories_for_weight_loss'] != null
          ? MacroValues.fromJson(
              json['calories_for_weight_loss'] as Map<String, dynamic>,
            )
          : null,
      caloriesForGain: json['calories_for_gain'] != null
          ? MacroValues.fromJson(
              json['calories_for_gain'] as Map<String, dynamic>,
            )
          : null,
      caloriesForMaintenance: json['calories_for_maintenance'] != null
          ? MacroValues.fromJson(
              json['calories_for_maintenance'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String getGoalDisplayName() {
    switch (goal) {
      case 'weight_loss':
        return 'Похудение';
      case 'muscle_gain':
        return 'Набор массы';
      case 'maintenance':
        return 'Поддержание веса';
      default:
        return goal;
    }
  }

  String getGenderDisplayName() {
    switch (gender) {
      case 'male':
        return 'Мужской';
      case 'female':
        return 'Женский';
      default:
        return gender;
    }
  }

  String getActivityDisplayName() {
    switch (activityCoefficient) {
      case '1.2':
        return 'Сидячий';
      case '1.375':
        return 'Слабая';
      case '1.55':
        return 'Средняя';
      case '1.725':
        return 'Высокая';
      case '1.9':
        return 'Экстремальная';
      default:
        return activityCoefficient;
    }
  }

  MacroValues? getMacrosForGoal() {
    switch (goal) {
      case 'weight_loss':
        return caloriesForWeightLoss;
      case 'muscle_gain':
        return caloriesForGain;
      case 'maintenance':
        return caloriesForMaintenance;
      default:
        return null;
    }
  }
}

class MacroValues {
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  MacroValues({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  factory MacroValues.fromJson(Map<String, dynamic> json) {
    return MacroValues(
      calories: (json['calories'] as num).toDouble(),
      proteins: (json['proteins'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }
}

