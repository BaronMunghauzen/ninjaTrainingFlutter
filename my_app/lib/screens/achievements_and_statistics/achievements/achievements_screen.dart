import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../models/user_achievement_type_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/user_achievement_service.dart';
import '../../../services/api_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<UserAchievementType> _achievements = [];
  bool _isLoading = true;
  String? _error;
  int? _userScore;
  final Map<String, ImageProvider?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    // Откладываем загрузку данных до завершения фазы сборки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Получаем score из профиля пользователя (используем уже загруженный профиль)
      final authProvider = context.read<AuthProvider>();
      
      // Используем уже загруженный профиль, не вызываем fetchUserProfile() чтобы избежать перестройки
      _userScore = authProvider.userProfile?.score;

      // Загружаем достижения
      final userUuid = authProvider.userUuid ?? authProvider.userProfile?.uuid;
      if (userUuid == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Пользователь не найден';
          _isLoading = false;
        });
        return;
      }

      final achievements = await UserAchievementService.getUserAchievements(userUuid);
      
      if (!mounted) return;
      
      // Фильтруем только активные достижения
      final activeAchievements = achievements.where((a) => a.isActive).toList();
      
      // Предзагружаем картинки для полученных достижений
      for (final achievement in activeAchievements) {
        if (achievement.isEarned && 
            achievement.imageUuid != null && 
            achievement.imageUuid!.isNotEmpty) {
          _loadImage(achievement.imageUuid!);
        }
      }

      if (!mounted) return;
      setState(() {
        _achievements = activeAchievements;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки достижений: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadImage(String imageUuid) async {
    if (_imageCache.containsKey(imageUuid)) {
      return; // Уже загружено
    }

    try {
      final imageProvider = await ApiService.getImageProvider(imageUuid);
      if (mounted && imageProvider != null) {
        setState(() {
          _imageCache[imageUuid] = imageProvider;
        });
      }
    } catch (e) {
      print('Ошибка загрузки картинки $imageUuid: $e');
    }
  }

  Map<String, List<UserAchievementType>> _groupByCategory(List<UserAchievementType> achievements) {
    final Map<String, List<UserAchievementType>> grouped = {};
    for (final achievement in achievements) {
      final category = achievement.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(achievement);
    }
    return grouped;
  }

  String _getCategoryDisplayName(String category) {
    // Преобразуем технические названия категорий в читаемые
    final categoryNames = {
      'training_count': 'Количество тренировок',
      'training_count_in_week': 'Тренировки за неделю',
      'special_day': 'Особые дни',
      'time_less_than': 'Ранние тренировки',
      'time_more_than': 'Поздние тренировки',
    };
    return categoryNames[category] ?? category;
  }

  void _showAchievementDetail(UserAchievementType achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAchievementDetailModal(achievement),
    );
  }

  Widget _buildAchievementDetailModal(UserAchievementType achievement) {
    final isEarned = achievement.isEarned;
    final imageUuid = achievement.imageUuid;
    final hasImage = isEarned && 
                     imageUuid != null && 
                     imageUuid.isNotEmpty &&
                     _imageCache.containsKey(imageUuid) &&
                     _imageCache[imageUuid] != null;

    // Загружаем картинку если еще не загружена
    if (isEarned && imageUuid != null && imageUuid.isNotEmpty && !_imageCache.containsKey(imageUuid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImage(imageUuid);
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Картинка или знак вопроса
          if (hasImage)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: _imageCache[imageUuid]!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildQuestionMark(size: 100);
                  },
                ),
              ),
            )
          else
            _buildQuestionMark(size: 100),
          const SizedBox(height: 24),
          // Название
          Text(
            achievement.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Описание
          Text(
            achievement.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Очки
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '+ ${achievement.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuestionMark({double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.help_outline,
        size: size * 0.6,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1F2121)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.buttonPrimary,
                  child: CustomScrollView(
                    slivers: [
                      // Заголовок с очками
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: AppColors.buttonPrimary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Заработано очков: ${_userScore ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Список достижений по категориям
                      ..._buildAchievementGroups(),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildAchievementGroups() {
    final grouped = _groupByCategory(_achievements);
    final categories = grouped.keys.toList()..sort();

    return categories.map((category) {
      final achievements = grouped[category]!;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок категории
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 12),
              //   child: Text(
              //     _getCategoryDisplayName(category),
              //     style: const TextStyle(
              //       color: Colors.white,
              //       fontSize: 20,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              // Сетка достижений (2 в строке)
              _buildAchievementsGrid(achievements),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAchievementsGrid(List<UserAchievementType> achievements) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementItem(achievements[index]);
      },
    );
  }

  Widget _buildAchievementItem(UserAchievementType achievement) {
    final isEarned = achievement.isEarned;
    final imageUuid = achievement.imageUuid;
    final hasImage = isEarned && 
                     imageUuid != null && 
                     imageUuid.isNotEmpty &&
                     _imageCache.containsKey(imageUuid) &&
                     _imageCache[imageUuid] != null;

    // Загружаем картинку если еще не загружена
    if (isEarned && imageUuid != null && imageUuid.isNotEmpty && !_imageCache.containsKey(imageUuid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImage(imageUuid);
      });
    }

    return GestureDetector(
      onTap: () => _showAchievementDetail(achievement),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Картинка или знак вопроса
          if (hasImage)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: _imageCache[imageUuid]!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildQuestionMark();
                    },
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildQuestionMark(),
              ),
            ),
          const SizedBox(height: 8),
          // Название достижения
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              achievement.name,
              style: TextStyle(
                color: isEarned ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
