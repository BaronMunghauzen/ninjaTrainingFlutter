import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_achievement_type_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/user_achievement_service.dart';
import '../../../services/api_service.dart';
import '../../../widgets/metal_card.dart';
import '../../../widgets/metal_message.dart';
import '../../../widgets/textured_background.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';

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
        MetalMessage.show(
          context: context,
          message: 'Пользователь не найден',
          type: MetalMessageType.error,
        );
        return;
      }

      final achievements = await UserAchievementService.getUserAchievements(
        userUuid,
      );

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
      MetalMessage.show(
        context: context,
        message: 'Ошибка загрузки данных: $e',
        type: MetalMessageType.error,
      );
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

  Map<String, List<UserAchievementType>> _groupByCategory(
    List<UserAchievementType> achievements,
  ) {
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

  void _showAchievementDetail(UserAchievementType achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          child: _buildAchievementDetailModal(achievement),
        ),
      ),
    );
  }

  Widget _buildAchievementDetailModal(UserAchievementType achievement) {
    final isEarned = achievement.isEarned;
    final imageUuid = achievement.imageUuid;
    final hasImage =
        isEarned &&
        imageUuid != null &&
        imageUuid.isNotEmpty &&
        _imageCache.containsKey(imageUuid) &&
        _imageCache[imageUuid] != null;

    // Загружаем картинку если еще не загружена
    if (isEarned &&
        imageUuid != null &&
        imageUuid.isNotEmpty &&
        !_imageCache.containsKey(imageUuid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImage(imageUuid);
      });
    }

    return MetalCard(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Картинка или знак вопроса
          if (hasImage)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: _imageCache[imageUuid]!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildQuestionMark(size: 70);
                  },
                ),
              ),
            )
          else
            _buildQuestionMark(size: 70),
          const SizedBox(height: 12),
          // Название
          Center(
            child: Text(
              achievement.name,
              style: NinjaText.title.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Описание
          Center(
            child: Text(
              achievement.description,
              style: NinjaText.body.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // Очки
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NinjaColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: NinjaColors.accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+ ${achievement.points}',
                    style: NinjaText.section.copyWith(
                      color: NinjaColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      child: Icon(Icons.help_outline, size: size * 0.6, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NinjaColors.accent),
                ),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: NinjaText.body.copyWith(color: NinjaColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NinjaColors.metalMid,
                        foregroundColor: NinjaColors.textPrimary,
                      ),
                      child: Text('Повторить', style: NinjaText.body),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: NinjaColors.accent,
                child: CustomScrollView(
                  slivers: [
                    // Заголовок с очками
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: MetalCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: NinjaColors.accent,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Заработано очков: ${_userScore ?? 0}',
                                style: NinjaText.section.copyWith(
                                  color: NinjaColors.textPrimary,
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
    final hasImage =
        isEarned &&
        imageUuid != null &&
        imageUuid.isNotEmpty &&
        _imageCache.containsKey(imageUuid) &&
        _imageCache[imageUuid] != null;

    // Загружаем картинку если еще не загружена
    if (isEarned &&
        imageUuid != null &&
        imageUuid.isNotEmpty &&
        !_imageCache.containsKey(imageUuid)) {
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
              style: NinjaText.caption.copyWith(
                color: isEarned
                    ? NinjaColors.textPrimary
                    : NinjaColors.textMuted,
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
