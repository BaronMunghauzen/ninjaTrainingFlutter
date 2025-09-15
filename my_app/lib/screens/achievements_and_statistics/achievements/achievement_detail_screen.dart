import 'package:flutter/material.dart';
import '../../../models/achievement_model.dart';
import '../../../constants/app_colors.dart';

class AchievementDetailScreen extends StatelessWidget {
  final AchievementModel achievement;

  const AchievementDetailScreen({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Детали достижения',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: achievement.isUnlocked
                          ? AppColors.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: achievement.isUnlocked
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      achievement.isUnlocked
                          ? 'Разблокировано'
                          : 'Заблокировано',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Описание
            _buildInfoSection(
              'Описание',
              achievement.description,
              Icons.info_outline,
            ),

            // Категория
            _buildInfoSection(
              'Категория',
              achievement.category,
              Icons.category,
            ),

            // Тип
            _buildInfoSection(
              'Тип',
              _getAchievementTypeName(achievement.type),
              Icons.star,
            ),

            // Прогресс
            _buildProgressSection(),

            // Награда
            if (achievement.rewardDescription != null)
              _buildInfoSection(
                'Награда',
                achievement.rewardDescription!,
                Icons.card_giftcard,
              ),

            // Даты
            if (achievement.createdAt != null)
              _buildInfoSection(
                'Создано',
                _formatDate(achievement.createdAt!),
                Icons.calendar_today,
              ),

            if (achievement.isUnlocked && achievement.unlockedAt != null)
              _buildInfoSection(
                'Разблокировано',
                _formatDate(achievement.unlockedAt!),
                Icons.lock_open,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = achievement.progressPercentage;
    final isCompleted = achievement.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              const Text(
                'Прогресс',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '${achievement.currentValue}/${achievement.targetValue}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : AppColors.primary,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% выполнено',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getAchievementTypeName(AchievementType type) {
    switch (type) {
      case AchievementType.general:
        return 'Общие';
      case AchievementType.training:
        return 'Тренировки';
      case AchievementType.exercise:
        return 'Упражнения';
      case AchievementType.streak:
        return 'Серии';
      case AchievementType.time:
        return 'Время';
      case AchievementType.social:
        return 'Социальные';
      case AchievementType.weight:
        return 'Вес';
      case AchievementType.distance:
        return 'Дистанция';
      case AchievementType.calories:
        return 'Калории';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
