import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/achievement_provider.dart';
import '../../../models/achievement_model.dart';
import '../../../constants/app_colors.dart';
import 'achievement_detail_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Загружаем достижения при инициализации экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAchievements();
    });
  }

  Future<void> _loadAchievements() async {
    final provider = context.read<AchievementProvider>();

    // Пытаемся загрузить из API, если не получится - используем mock
    await provider.loadAchievementsFromTypesTable();

    // Проверяем, что у нас есть достижения
    if (provider.achievements.isEmpty) {
      await provider.loadMockAchievements();
    }

    // Загружаем достижения пользователя (используем временный UUID для демонстрации)
    // В реальном приложении здесь должен быть UUID текущего пользователя
    const String demoUserUuid = 'demo-user-123';
    await provider.loadUserAchievementsByUuid(demoUserUuid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadAchievements(),
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              const String demoUserUuid = 'demo-user-123';
              context.read<AchievementProvider>().loadUserAchievementsByUuid(
                demoUserUuid,
              );
            },
            tooltip: 'Загрузить достижения пользователя',
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            onPressed: () =>
                context.read<AchievementProvider>().loadMockAchievements(),
            tooltip: 'Mock данные',
          ),
        ],
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1F2121)),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ошибка загрузки: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshAchievements(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.achievements.isEmpty) {
            return const Center(
              child: Text(
                'Достижения не найдены',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              // Вкладки для фильтрации по категориям
              _buildCategoryTabs(provider.achievements),
              // Список достижений
              Expanded(
                child: _buildAchievementsGrid(
                  _selectedCategory != null
                      ? provider.achievements
                            .where((a) => a.category == _selectedCategory)
                            .toList()
                      : provider.achievements,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementsGrid(List<AchievementModel> achievements) {
    // Группируем достижения по категориям
    final Map<String, List<AchievementModel>> groupedAchievements = {};

    for (final achievement in achievements) {
      final category = achievement.category;
      if (!groupedAchievements.containsKey(category)) {
        groupedAchievements[category] = [];
      }
      groupedAchievements[category]!.add(achievement);
    }

    // Сортируем категории в логичном порядке
    final List<String> sortedCategories = groupedAchievements.keys.toList()
      ..sort((a, b) {
        // Приоритетные категории идут первыми
        final priorityOrder = {
          'Общие': 1,
          'Тренировки': 2,
          'Упражнения': 3,
          'Стреж': 4,
          'Время': 5,
          'Социальные': 6,
          'Вес': 7,
          'Дистанция': 8,
          'Калории': 9,
        };

        final aPriority = priorityOrder[a] ?? 999;
        final bPriority = priorityOrder[b] ?? 999;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        // Если приоритет одинаковый, сортируем по алфавиту
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryAchievements = groupedAchievements[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок категории с количеством достижений
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Row(
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${categoryAchievements.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Сетка достижений для этой категории
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: categoryAchievements.length,
              itemBuilder: (context, index) {
                final achievement = categoryAchievements[index];
                return _buildAchievementItem(achievement);
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildAchievementItem(AchievementModel achievement) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AchievementDetailScreen(achievement: achievement),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: achievement.isUnlocked ? AppColors.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.isUnlocked
                ? AppColors.primary
                : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Иконка достижения
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Название достижения
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked
                      ? Colors.white
                      : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Статус разблокировки
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: achievement.isUnlocked ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                achievement.isUnlocked ? 'Разблокировано' : 'Заблокировано',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<AchievementModel> achievements) {
    // Получаем уникальные категории
    final categories = achievements.map((a) => a.category).toSet().toList()
      ..sort((a, b) {
        final priorityOrder = {
          'Общие': 1,
          'Тренировки': 2,
          'Упражнения': 3,
          'Стреж': 4,
          'Время': 5,
          'Социальные': 6,
          'Вес': 7,
          'Дистанция': 8,
          'Калории': 9,
        };

        final aPriority = priorityOrder[a] ?? 999;
        final bPriority = priorityOrder[b] ?? 999;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return a.compareTo(b);
      });

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 для кнопки "Все"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Кнопка "Все"
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedCategory == null
                        ? AppColors.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Все',
                    style: TextStyle(
                      color: _selectedCategory == null
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final category = categories[index - 1];
          final isSelected = _selectedCategory == category;
          final count = achievements
              .where((a) => a.category == category)
              .length;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
