import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../services/search_service.dart';
import '../../services/api_service.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
// import '../../widgets/video_player_widget.dart';
import 'user_exercise_reference_create_screen.dart';
import 'user_exercise_reference_detail_screen.dart';

class UserExerciseReferenceListScreen extends StatefulWidget {
  const UserExerciseReferenceListScreen({Key? key}) : super(key: key);

  @override
  State<UserExerciseReferenceListScreen> createState() =>
      _UserExerciseReferenceListScreenState();
}

class _UserExerciseReferenceListScreenState
    extends State<UserExerciseReferenceListScreen> {
  List<dynamic> userExercises = [];
  List<dynamic> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool hasSearched = false;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  // Фильтры
  List<String> _selectedMuscleGroups = [];
  List<String> _selectedEquipmentNames = [];
  List<String> _availableMuscleGroups = [];
  List<String> _availableEquipmentNames = [];

  // Пагинация
  int currentPage = 1;
  int pageSize = 10;
  int totalItems = 0;
  int totalPages = 0;
  final List<int> availablePageSizes = [10, 20, 50, 75];

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadUserExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserExercises() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final exercises = await UserTrainingService.getUserExerciseReferences(
        userUuid,
        page: currentPage,
        size: pageSize,
      );
      setState(() {
        userExercises = exercises.items;
        totalItems = exercises.total;
        totalPages = exercises.pages;
        currentPage = exercises.page;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user exercises: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(dynamic exercise) async {
    try {
      final exerciseUuid = exercise.uuid;
      bool success = false;

      if (exercise.isFavorite) {
        success = await UserTrainingService.removeFromFavorites(exerciseUuid);
      } else {
        success = await UserTrainingService.addToFavorites(exerciseUuid);
      }

      if (success) {
        // Перезагружаем список
        if (hasSearched) {
          await _performSearch(_searchController.text);
        } else {
          await _loadUserExercises();
        }
      } else {
        // Показываем сообщение об ошибке
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при изменении статуса избранного'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadFilters() async {
    try {
      print('DEBUG: User - Loading filters...');
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;
      print('DEBUG: User - User UUID: $userUuid');

      if (userUuid == null) {
        print('DEBUG: User - No user UUID, returning empty filters');
        setState(() {
          _availableMuscleGroups = [];
          _availableEquipmentNames = [];
        });
        return;
      }

      final response = await ApiService.get(
        '/exercise_reference/filters/$userUuid',
      );
      print('DEBUG: User - Filters response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        print('DEBUG: User - Filters data: $data');
        setState(() {
          _availableMuscleGroups = List<String>.from(
            data['muscle_groups'] ?? [],
          );
          _availableEquipmentNames = List<String>.from(
            data['equipment_names'] ?? [],
          );
        });
        print(
          'DEBUG: User - Loaded filters: muscle_groups=${_availableMuscleGroups.length}, equipment_names=${_availableEquipmentNames.length}',
        );
      } else {
        print('DEBUG: User - Filters response not 200, returning empty');
        setState(() {
          _availableMuscleGroups = [];
          _availableEquipmentNames = [];
        });
      }
    } catch (e) {
      print('Error loading filters: $e');
      setState(() {
        _availableMuscleGroups = [];
        _availableEquipmentNames = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    // Если запрос пустой И нет активных фильтров, очищаем результаты
    if (query.trim().isEmpty &&
        _selectedMuscleGroups.isEmpty &&
        _selectedEquipmentNames.isEmpty) {
      setState(() {
        searchResults.clear();
        isSearching = false;
        hasSearched = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      hasSearched = true;
    });

    print('DEBUG: User - Performing search with query: "$query"');
    print('DEBUG: User - Selected muscle groups: $_selectedMuscleGroups');
    print('DEBUG: User - Selected equipment names: $_selectedEquipmentNames');

    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() {
          searchResults.clear();
          isSearching = false;
        });
        return;
      }

      final results = await SearchService.searchExerciseReferencesByCaption(
        userUuid,
        query,
        page: currentPage,
        size: pageSize,
        muscleGroups: _selectedMuscleGroups,
        equipmentNames: _selectedEquipmentNames,
      );
      setState(() {
        searchResults = results.items;
        totalItems = results.total;
        totalPages = results.pages;
        currentPage = results.page;
        isSearching = false;
      });
    } catch (e) {
      print('Error searching user exercises: $e');
      setState(() {
        searchResults.clear();
        isSearching = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(seconds: 1), () {
      currentPage = 1; // Сброс на первую страницу при поиске
      _performSearch(query);
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      currentPage = page;
    });
    if (hasSearched) {
      _performSearch(_searchController.text);
    } else {
      _loadUserExercises();
    }
  }

  void _onPageSizeChanged(int newSize) {
    setState(() {
      pageSize = newSize;
      currentPage = 1; // Сброс на первую страницу при изменении размера
    });
    if (hasSearched) {
      _performSearch(_searchController.text);
    } else {
      _loadUserExercises();
    }
  }

  Widget _buildPaginationControls() {
    // Показываем элементы пагинации всегда, когда есть элементы
    if (_displayedExercises.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Выбор размера страницы
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Элементов на странице: '),
              DropdownButton<int>(
                value: pageSize,
                items: availablePageSizes.map((size) {
                  return DropdownMenuItem<int>(
                    value: size,
                    child: Text('$size'),
                  );
                }).toList(),
                onChanged: (newSize) {
                  if (newSize != null) {
                    _onPageSizeChanged(newSize);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Навигация по страницам (показываем только если есть несколько страниц)
          if (totalPages > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentPage > 1
                      ? () => _onPageChanged(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Страница $currentPage из $totalPages'),
                IconButton(
                  onPressed: currentPage < totalPages
                      ? () => _onPageChanged(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text('Всего элементов: $totalItems'),
        ],
      ),
    );
  }

  List<dynamic> get _displayedExercises {
    final result = hasSearched ? searchResults : userExercises;
    return result;
  }

  void _toggleMuscleGroupFilter(String muscleGroup) {
    setState(() {
      if (_selectedMuscleGroups.contains(muscleGroup)) {
        _selectedMuscleGroups.remove(muscleGroup);
      } else {
        _selectedMuscleGroups.add(muscleGroup);
      }
    });

    // Немедленно обновляем список
    setState(() {
      currentPage = 1; // Сброс на первую страницу
    });

    if (_searchController.text.isNotEmpty ||
        _selectedMuscleGroups.isNotEmpty ||
        _selectedEquipmentNames.isNotEmpty) {
      _performSearch(_searchController.text);
    } else {
      // Сбрасываем флаг поиска и загружаем обычный список
      setState(() {
        hasSearched = false;
        searchResults.clear();
      });
      _loadUserExercises();
    }
  }

  void _toggleEquipmentFilter(String equipmentName) {
    setState(() {
      if (_selectedEquipmentNames.contains(equipmentName)) {
        _selectedEquipmentNames.remove(equipmentName);
      } else {
        _selectedEquipmentNames.add(equipmentName);
      }
    });

    // Немедленно обновляем список
    setState(() {
      currentPage = 1; // Сброс на первую страницу
    });

    if (_searchController.text.isNotEmpty ||
        _selectedMuscleGroups.isNotEmpty ||
        _selectedEquipmentNames.isNotEmpty) {
      _performSearch(_searchController.text);
    } else {
      // Сбрасываем флаг поиска и загружаем обычный список
      setState(() {
        hasSearched = false;
        searchResults.clear();
      });
      _loadUserExercises();
    }
  }

  Widget? _buildExerciseMedia(dynamic exercise) {
    // Приоритет: видео -> гиф -> картинка
    String? videoUuid;
    String? gifUuid;
    String? imageUuid;

    // Извлекаем UUID видео
    final dynamic video = exercise.video;
    if (video != null) {
      if (video is String && video.isNotEmpty) {
        videoUuid = video;
      } else if (video is Map<String, dynamic>) {
        videoUuid = video['uuid'] as String?;
      }
    }

    // Извлекаем UUID гифки
    final dynamic gif = exercise.gif;
    if (gif != null) {
      if (gif is String && gif.isNotEmpty) {
        gifUuid = gif;
      } else if (gif is Map<String, dynamic>) {
        gifUuid = gif['uuid'] as String?;
      }
    }

    // Извлекаем UUID картинки
    final dynamic image = exercise.image;
    if (image != null) {
      if (image is String && image.isNotEmpty) {
        imageUuid = image;
      } else if (image is Map<String, dynamic>) {
        imageUuid = image['uuid'] as String?;
      }
    }

    // На списке видео не показываем — используем гифку, затем картинку
    if (gifUuid != null && gifUuid.isNotEmpty) {
      return SizedBox(
        width: 60,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GifWidget(gifUuid: gifUuid, height: 60, width: 60),
        ),
      );
    }

    if (imageUuid != null && imageUuid.isNotEmpty) {
      return AuthImageWidget(
        imageUuid: imageUuid,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
      );
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Поиск упражнений...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchResults = [];
                            isSearching = false;
                            hasSearched = false;
                            _selectedMuscleGroups.clear();
                            _selectedEquipmentNames.clear();
                          });
                          currentPage = 1;
                          _loadUserExercises();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.inputBorder.withOpacity(0.1),
              ),
            ),
          ),
          // Фильтры - Группы мышц
          if (_availableMuscleGroups.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _availableMuscleGroups.map((muscleGroup) {
                  final isSelected = _selectedMuscleGroups.contains(
                    muscleGroup,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(muscleGroup),
                      selected: isSelected,
                      onSelected: (selected) {
                        _toggleMuscleGroupFilter(muscleGroup);
                      },
                      selectedColor: AppColors.buttonPrimary.withOpacity(0.3),
                      checkmarkColor: AppColors.buttonPrimary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? const Color.fromARGB(255, 155, 155, 155)
                            : AppColors.inputBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Фильтры - Оборудование
          if (_availableEquipmentNames.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _availableEquipmentNames.map((equipmentName) {
                  final isSelected = _selectedEquipmentNames.contains(
                    equipmentName,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(equipmentName),
                      selected: isSelected,
                      onSelected: (selected) {
                        _toggleEquipmentFilter(equipmentName);
                      },
                      selectedColor: AppColors.buttonPrimary.withOpacity(0.3),
                      checkmarkColor: AppColors.buttonPrimary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? const Color.fromARGB(255, 155, 155, 155)
                            : AppColors.inputBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                    ),
                  )
                : _displayedExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasSearched ? Icons.search_off : Icons.fitness_center,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasSearched
                              ? 'По вашему запросу ничего не найдено'
                              : 'У вас пока нет упражнений',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        _displayedExercises.length +
                        1, // +1 для элементов пагинации
                    separatorBuilder: (context, index) {
                      // Не показываем разделитель перед элементами пагинации
                      if (index == _displayedExercises.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return const SizedBox(
                        height: 12,
                      ); // Заменяем Card margin на separator
                    },
                    itemBuilder: (context, index) {
                      // Если это последний элемент, показываем пагинацию
                      if (index == _displayedExercises.length) {
                        return _buildPaginationControls();
                      }

                      final exercise = _displayedExercises[index];
                      return Card(
                        margin: EdgeInsets
                            .zero, // Убираем margin, так как используем separator
                        child: Stack(
                          children: [
                            ListTile(
                              leading: _buildExerciseMedia(exercise),
                              title: Padding(
                                padding: const EdgeInsets.only(right: 80),
                                child: Text(
                                  exercise.caption,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.description,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Группа мышц: ${exercise.muscleGroup}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserExerciseReferenceDetailScreen(
                                          exercise: exercise,
                                        ),
                                  ),
                                );
                              },
                            ),
                            // Кнопка избранного (сердечко)
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 8,
                              child: _FavoriteButton(
                                isFavorite: exercise.isFavorite,
                                onPressed: () async {
                                  await _toggleFavorite(exercise);
                                },
                              ),
                            ),
                            // Метка в правом верхнем углу
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.5,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  exercise.exerciseType == 'user'
                                      ? 'Мое'
                                      : 'Системное',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Элементы управления пагинацией
          // _buildPaginationControls(), // Перемещен в конец списка
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UserExerciseReferenceCreateScreen(),
            ),
          );
          if (result == true) {
            _loadUserExercises();
          }
        },
        backgroundColor: AppColors.buttonPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey<bool>(widget.isFavorite),
              color: widget.isFavorite ? Colors.red : AppColors.textSecondary,
              size: 24,
            ),
          ),
          iconSize: 24,
          onPressed: _handleTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}
