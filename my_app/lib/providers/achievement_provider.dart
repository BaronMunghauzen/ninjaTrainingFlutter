import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';

class AchievementProvider extends ChangeNotifier {
  List<AchievementModel> _achievements = [];
  List<AchievementModel> _filteredAchievements = [];
  bool _isLoading = false;
  String? _error;
  AchievementType? _selectedType;
  bool _showStats = true;

  // Getters
  List<AchievementModel> get achievements => _achievements;
  List<AchievementModel> get filteredAchievements => _filteredAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AchievementType? get selectedType => _selectedType;
  bool get showStats => _showStats;

  // Загрузить достижения пользователя
  Future<void> loadUserAchievements() async {
    _setLoading(true);
    try {
      _achievements = await AchievementService.getUserAchievements();
      _filteredAchievements = _achievements;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Загрузить все достижения
  Future<void> loadAllAchievements() async {
    _setLoading(true);
    try {
      _achievements = await AchievementService.getAllAchievements();
      _filteredAchievements = _achievements;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Загрузить достижения из таблицы achievement_types
  Future<void> loadAchievementsFromTypesTable() async {
    _setLoading(true);
    try {
      print('Загружаем достижения из таблицы achievement_types...');
      _achievements = await AchievementService.getAchievementsFromTypesTable();
      print('Получено ${_achievements.length} достижений');
      _filteredAchievements = _achievements;
      _error = null;
      
      // Проверяем, что достижения действительно загружены
      if (_achievements.isNotEmpty) {
        print('Достижения успешно загружены:');
        for (final achievement in _achievements) {
          print('- ${achievement.title} (${achievement.icon})');
        }
      } else {
        print('Список достижений пуст!');
      }
      
    } catch (e) {
      print('Ошибка загрузки достижений: $e');
      _error = e.toString();
      // Очищаем список достижений при ошибке
      _achievements = [];
      _filteredAchievements = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Загрузить достижения пользователя по UUID
  Future<void> loadUserAchievementsByUuid(String userUuid) async {
    _setLoading(true);
    try {
      print('Загружаем достижения пользователя $userUuid...');
      final userAchievements = await AchievementService.getUserAchievementsByUuid(userUuid);
      print('Получено ${userAchievements.length} достижений пользователя');
      
      // Обновляем статус разблокировки для достижений
      _updateAchievementsUnlockStatus(userAchievements);
      
      _error = null;
      
    } catch (e) {
      print('Ошибка загрузки достижений пользователя: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Обновить статус разблокировки достижений на основе достижений пользователя
  void _updateAchievementsUnlockStatus(List<AchievementModel> userAchievements) {
    print('Обновляем статус разблокировки для ${userAchievements.length} достижений пользователя');
    print('Всего достижений в системе: ${_achievements.length}');
    
    // Создаем Map для быстрого поиска по UUID достижения
    final Map<String, AchievementModel> userAchievementsMap = {
      for (var achievement in userAchievements) achievement.uuid: achievement
    };
    
    print('UUID достижений пользователя: ${userAchievementsMap.keys.toList()}');
    
    int unlockedCount = 0;
    int lockedCount = 0;
    
    // Обновляем статус разблокировки для всех достижений
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      print('Проверяем достижение: ${achievement.title} (UUID: ${achievement.uuid})');
      
      if (userAchievementsMap.containsKey(achievement.uuid)) {
        // Пользователь получил это достижение
        final userAchievement = userAchievementsMap[achievement.uuid]!;
        _achievements[i] = achievement.copyWith(
          isUnlocked: true,
          currentValue: userAchievement.currentValue,
          unlockedAt: userAchievement.unlockedAt,
        );
        unlockedCount++;
        print('✅ Разблокировано: ${achievement.title}');
      } else {
        // Пользователь не получил это достижение
        _achievements[i] = achievement.copyWith(
          isUnlocked: false,
          currentValue: 0,
          unlockedAt: null,
        );
        lockedCount++;
        print('🔒 Заблокировано: ${achievement.title}');
      }
    }
    
    // Обновляем отфильтрованные достижения
    _filteredAchievements = _achievements;
    
    print('Статус разблокировки обновлен: $unlockedCount разблокировано, $lockedCount заблокировано');
    
    // Уведомляем слушателей об изменении
    notifyListeners();
  }

  // Загрузить достижения по UUID типа достижения
  Future<void> loadAchievementsByTypeUuid(String achievementTypeUuid) async {
    _setLoading(true);
    try {
      print('Загружаем достижения для типа с UUID: $achievementTypeUuid...');
      _achievements = await AchievementService.getAchievementsByTypeUuid(achievementTypeUuid);
      print('Получено ${_achievements.length} достижений для типа $achievementTypeUuid');
      _filteredAchievements = _achievements;
      _error = null;
    } catch (e) {
      print('Ошибка загрузки достижений по UUID типа: $e');
      _error = e.toString();
      // Очищаем список достижений при ошибке
      _achievements = [];
      _filteredAchievements = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Загрузить список типов достижений
  Future<List<Map<String, dynamic>>> loadAchievementTypes() async {
    try {
      print('Загружаем список типов достижений...');
      final types = await AchievementService.getAchievementTypes();
      print('Получено ${types.length} типов достижений');
      return types;
    } catch (e) {
      print('Ошибка загрузки типов достижений: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  

  // Обновить прогресс достижения
  Future<void> updateAchievementProgress(String achievementId, int newValue) async {
    try {
      final updatedAchievement = await AchievementService.updateAchievementProgress(
        achievementId,
        newValue,
      );
      
      final index = _achievements.indexWhere((a) => a.uuid == achievementId);
      if (index != -1) {
        _achievements[index] = updatedAchievement;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Разблокировать достижение
  Future<void> unlockAchievement(String achievementId) async {
    try {
      final unlockedAchievement = await AchievementService.unlockAchievement(achievementId);
      
      final index = _achievements.indexWhere((a) => a.uuid == achievementId);
      if (index != -1) {
        _achievements[index] = unlockedAchievement;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Установить тип фильтра
  void setSelectedType(AchievementType? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  // Переключить отображение статистики
  void toggleStats() {
    _showStats = !_showStats;
    notifyListeners();
  }

  // Применить фильтры
  void _applyFilters() {
    if (_selectedType == null) {
      _filteredAchievements = _achievements;
    } else {
      _filteredAchievements = _achievements
          .where((achievement) => achievement.type == _selectedType)
          .toList();
    }
  }

  // Получить достижения по типу
  List<AchievementModel> getAchievementsByType(AchievementType type) {
    return _achievements.where((achievement) => achievement.type == type).toList();
  }

  // Получить количество достижений по типу
  Map<AchievementType, int> getTypeCounts() {
    final Map<AchievementType, int> counts = {};
    for (final type in AchievementType.values) {
      counts[type] = _achievements.where((a) => a.type == type).length;
    }
    return counts;
  }

  // Получить разблокированные достижения
  List<AchievementModel> getUnlockedAchievements() {
    return _achievements.where((achievement) => achievement.isUnlocked).toList();
  }

  // Получить заблокированные достижения
  List<AchievementModel> getLockedAchievements() {
    return _achievements.where((achievement) => !achievement.isUnlocked).toList();
  }

  // Получить достижения, близкие к завершению
  List<AchievementModel> getNearCompletionAchievements() {
    return _achievements.where((achievement) => achievement.isNearCompletion).toList();
  }

  // Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Установить состояние загрузки
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Обновить достижения
  Future<void> refreshAchievements() async {
    await loadAchievementsFromTypesTable();
  }

  // Загрузить mock достижения для тестирования
  Future<void> loadMockAchievements() async {
    _setLoading(true);
    try {
      print('Загружаем mock достижения...');
      _achievements = [
        // Общие достижения
        AchievementModel(
          uuid: '1',
          title: 'Первые шаги',
          description: 'Начните свой путь к успеху',
          category: 'Общие',
          type: AchievementType.general,
          targetValue: 1,
          currentValue: 0,
          isUnlocked: false,
          rewardDescription: 'Базовый опыт',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '⭐',
        ),
        AchievementModel(
          uuid: '2',
          title: 'Регистрация',
          description: 'Зарегистрируйтесь в приложении',
          category: 'Общие',
          type: AchievementType.general,
          targetValue: 1,
          currentValue: 1,
          isUnlocked: true,
          rewardDescription: 'Доступ к функциям',
          unlockedAt: DateTime.now(),
          createdAt: DateTime.now(),
          icon: '✅',
        ),
        
        // Тренировки
        AchievementModel(
          uuid: '3',
          title: 'Первая тренировка',
          description: 'Завершите первую тренировку',
          category: 'Тренировки',
          type: AchievementType.training,
          targetValue: 1,
          currentValue: 0,
          isUnlocked: false,
          rewardDescription: 'Опыт тренировок',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '💪',
        ),
        AchievementModel(
          uuid: '4',
          title: 'Неделя тренировок',
          description: 'Тренируйтесь 7 дней подряд',
          category: 'Тренировки',
          type: AchievementType.training,
          targetValue: 7,
          currentValue: 3,
          isUnlocked: false,
          rewardDescription: 'Бонус выносливости',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '📅',
        ),
        
        // Упражнения
        AchievementModel(
          uuid: '5',
          title: 'Разнообразие',
          description: 'Выполните 10 различных упражнений',
          category: 'Упражнения',
          type: AchievementType.exercise,
          targetValue: 10,
          currentValue: 6,
          isUnlocked: false,
          rewardDescription: 'Опыт упражнений',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '🏃',
        ),
        AchievementModel(
          uuid: '6',
          title: 'Мастер техники',
          description: 'Выполните 100 повторений',
          category: 'Упражнения',
          type: AchievementType.exercise,
          targetValue: 100,
          currentValue: 75,
          isUnlocked: false,
          rewardDescription: 'Улучшение техники',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '🎯',
        ),
        
        // Стреж
        AchievementModel(
          uuid: '7',
          title: 'Начало пути',
          description: 'Тренируйтесь 3 дня подряд',
          category: 'Стреж',
          type: AchievementType.streak,
          targetValue: 3,
          currentValue: 2,
          isUnlocked: false,
          rewardDescription: 'Бонус мотивации',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '🔥',
        ),
        
        // Время
        AchievementModel(
          uuid: '8',
          title: 'Выносливость',
          description: 'Тренируйтесь 30 минут подряд',
          category: 'Время',
          type: AchievementType.time,
          targetValue: 30,
          currentValue: 25,
          isUnlocked: false,
          rewardDescription: 'Повышение выносливости',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '⏱️',
        ),
        
        // Социальные
        AchievementModel(
          uuid: '9',
          title: 'Команда',
          description: 'Присоединитесь к группе',
          category: 'Социальные',
          type: AchievementType.social,
          targetValue: 1,
          currentValue: 0,
          isUnlocked: false,
          rewardDescription: 'Социальные бонусы',
          unlockedAt: null,
          createdAt: DateTime.now(),
          icon: '👥',
        ),
      ];
      print('Получено ${_achievements.length} mock достижений');
      _filteredAchievements = _achievements;
      _error = null;
      
      // Проверяем, что mock достижения действительно загружены
      if (_achievements.isNotEmpty) {
        print('Mock достижения успешно загружены:');
        for (final achievement in _achievements) {
          print('- ${achievement.title} (${achievement.icon}) - ${achievement.category}');
        }
      } else {
        print('Список mock достижений пуст!');
      }
      
    } catch (e) {
      print('Ошибка загрузки mock достижений: $e');
      _error = e.toString();
      _achievements = [];
      _filteredAchievements = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
}

