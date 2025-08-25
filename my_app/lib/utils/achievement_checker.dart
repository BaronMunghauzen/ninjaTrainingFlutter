import '../models/achievement_model.dart';
import '../services/achievement_service.dart';

class AchievementChecker {
  // Проверить достижения после завершения тренировки
  static Future<List<AchievementModel>> checkAfterTraining({
    required int trainingDuration,
    required int exercisesCount,
    required DateTime trainingTime,
  }) async {
    try {
      // Здесь можно добавить логику проверки достижений
      // Например, проверка на "Первая тренировка", "Утренняя тренировка" и т.д.
      
      // Пока что просто возвращаем пустой список
      // В реальном приложении здесь будет API вызов для проверки достижений
      return [];
    } catch (e) {
      print('Error checking achievements after training: $e');
      return [];
    }
  }

  // Проверить достижения после выполнения упражнения
  static Future<List<AchievementModel>> checkAfterExercise({
    required String exerciseType,
    required int reps,
    required double weight,
    required int duration,
  }) async {
    try {
      // Логика проверки достижений за упражнения
      // Например, "100 отжиманий", "10 минут планки" и т.д.
      
      return [];
    } catch (e) {
      print('Error checking achievements after exercise: $e');
      return [];
    }
  }

  // Проверить достижения за серию тренировок
  static Future<List<AchievementModel>> checkStreakAchievements({
    required int currentStreak,
    required int longestStreak,
  }) async {
    try {
      // Проверка достижений за серии: "7 дней подряд", "30 дней" и т.д.
      
      return [];
    } catch (e) {
      print('Error checking streak achievements: $e');
      return [];
    }
  }

  // Проверить достижения за время тренировок
  static Future<List<AchievementModel>> checkTimeAchievements({
    required int totalTrainingHours,
    required int monthlyTrainingHours,
  }) async {
    try {
      // Проверка достижений за время: "100 часов в зале", "50 часов в месяц" и т.д.
      
      return [];
    } catch (e) {
      print('Error checking time achievements: $e');
      return [];
    }
  }

  // Проверить социальные достижения
  static Future<List<AchievementModel>> checkSocialAchievements({
    required int sharedWorkouts,
    required int receivedLikes,
    required int friendsCount,
  }) async {
    try {
      // Проверка социальных достижений: "Поделиться 20 тренировками", "100 лайков" и т.д.
      
      return [];
    } catch (e) {
      print('Error checking social achievements: $e');
      return [];
    }
  }

  // Общая проверка всех достижений
  static Future<List<AchievementModel>> checkAllAchievements({
    Map<String, dynamic>? trainingData,
    Map<String, dynamic>? exerciseData,
    Map<String, dynamic>? socialData,
  }) async {
    try {
      final List<AchievementModel> newAchievements = [];

      // Проверяем различные типы достижений
      if (trainingData != null) {
        final trainingAchievements = await checkAfterTraining(
          trainingDuration: trainingData['duration'] ?? 0,
          exercisesCount: trainingData['exercisesCount'] ?? 0,
          trainingTime: trainingData['time'] ?? DateTime.now(),
        );
        newAchievements.addAll(trainingAchievements);
      }

      if (exerciseData != null) {
        final exerciseAchievements = await checkAfterExercise(
          exerciseType: exerciseData['type'] ?? '',
          reps: exerciseData['reps'] ?? 0,
          weight: exerciseData['weight'] ?? 0.0,
          duration: exerciseData['duration'] ?? 0,
        );
        newAchievements.addAll(exerciseAchievements);
      }

      // Убираем дубликаты
      final uniqueAchievements = <String, AchievementModel>{};
      for (final achievement in newAchievements) {
        uniqueAchievements[achievement.uuid] = achievement;
      }

      return uniqueAchievements.values.toList();
    } catch (e) {
      print('Error checking all achievements: $e');
      return [];
    }
  }

  // Проверить, нужно ли показать уведомление о достижении
  static bool shouldShowAchievementNotification(AchievementModel achievement) {
    // Показываем уведомление только для недавно разблокированных достижений
    if (!achievement.isUnlocked || achievement.unlockedAt == null) {
      return false;
    }

    final now = DateTime.now();
    final unlockedTime = achievement.unlockedAt!;
    final difference = now.difference(unlockedTime);

    // Показываем уведомление в течение 24 часов после разблокировки
    return difference.inHours < 24;
  }

  // Получить текст уведомления о достижении
  static String getAchievementNotificationText(AchievementModel achievement) {
    return '🎉 Поздравляем! Вы получили достижение "${achievement.title}"!';
  }
}





