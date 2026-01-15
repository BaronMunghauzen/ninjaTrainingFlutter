import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/search_service.dart';
import '../../services/api_service.dart';
import '../../widgets/textured_background.dart';
import '../../widgets/metal_back_button.dart';
import '../../widgets/metal_search_bar.dart';
import '../../widgets/metal_list_item.dart';
import '../../widgets/metal_button.dart';
import '../../widgets/metal_modal.dart';
import '../../widgets/metal_message.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/video_player_widget.dart';
import '../../design/ninja_spacing.dart';
import '../../design/ninja_typography.dart';
import '../../models/search_result_model.dart' as search_models;
import '../../services/user_training_service.dart';

class UserExerciseSelectorScreen extends StatefulWidget {
  const UserExerciseSelectorScreen({Key? key}) : super(key: key);

  @override
  State<UserExerciseSelectorScreen> createState() =>
      _UserExerciseSelectorScreenState();
}

class _UserExerciseSelectorScreenState
    extends State<UserExerciseSelectorScreen> {
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

  // Выбранное упражнение
  search_models.ExerciseReference? _selectedExercise;

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
    setState(() => isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userUuid = authProvider.userUuid;

      if (userUuid == null) {
        setState(() => isLoading = false);
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
      setState(() => isLoading = false);
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
      print('Error searching exercises: $e');
      setState(() {
        searchResults.clear();
        isSearching = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
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

  void _selectExercise(dynamic exercise) {
    // Преобразуем в ExerciseReference если нужно
    search_models.ExerciseReference exerciseRef;

    if (exercise is search_models.ExerciseReference) {
      exerciseRef = exercise;
    } else if (exercise is Map<String, dynamic>) {
      exerciseRef = search_models.ExerciseReference.fromJson(exercise);
    } else {
      return; // Неизвестный тип
    }

    setState(() {
      _selectedExercise = exerciseRef;
    });
  }

  void _confirmSelection() {
    if (_selectedExercise != null) {
      Navigator.of(context).pop(_selectedExercise);
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });

      if (hasSearched) {
        _performSearch(_searchController.text);
      } else {
        _loadUserExercises();
      }
    }
  }

  void _changePageSize(int newSize) {
    setState(() {
      pageSize = newSize;
      currentPage = 1;
    });

    if (hasSearched) {
      _performSearch(_searchController.text);
    } else {
      _loadUserExercises();
    }
  }

  Future<void> _toggleFavorite(dynamic exercise) async {
    try {
      final exerciseUuid = _getExerciseUuid(exercise);
      if (exerciseUuid.isEmpty) return;

      final isFavorite = _getExerciseIsFavorite(exercise);
      bool success = false;

      if (isFavorite) {
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
          MetalMessage.show(
            context: context,
            message: 'Ошибка при изменении статуса избранного',
            type: MetalMessageType.error,
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        MetalMessage.show(
          context: context,
          message: 'Ошибка: $e',
          type: MetalMessageType.error,
        );
      }
    }
  }

  void _showExerciseDetail(dynamic exercise) {
    // Преобразуем в ExerciseReference если нужно
    search_models.ExerciseReference exerciseRef;

    if (exercise is search_models.ExerciseReference) {
      exerciseRef = exercise;
    } else if (exercise is Map<String, dynamic>) {
      exerciseRef = search_models.ExerciseReference.fromJson(exercise);
    } else {
      return; // Неизвестный тип
    }

    MetalModal.show(
      context: context,
      title: exerciseRef.caption,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exerciseRef.description.isNotEmpty) ...[
              Text(
                'Описание',
                style: NinjaText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exerciseRef.description,
                style: NinjaText.body,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Мышечная группа',
              style: NinjaText.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              exerciseRef.muscleGroup,
              style: NinjaText.body,
            ),
            const SizedBox(height: 16),
            Text(
              'Оборудование',
              style: NinjaText.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              exerciseRef.equipmentName ?? 'Без оборудования',
              style: NinjaText.body,
            ),
            // Медиа (гифка или картинка)
            if (_buildExerciseMediaForModal(exerciseRef) != null) ...[
              const SizedBox(height: 16),
              Center(child: _buildExerciseMediaForModal(exerciseRef)),
            ],
            if (exerciseRef.techniqueDescription != null &&
                exerciseRef.techniqueDescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Техника выполнения',
                style: NinjaText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exerciseRef.techniqueDescription!,
                style: NinjaText.body,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseMedia(dynamic exercise) {
    // Приоритет: гиф -> картинка (видео не показываем на списке)
    String? gifUuid;
    String? imageUuid;

    // Извлекаем UUID гифки
    final dynamic gif = exercise is search_models.ExerciseReference
        ? exercise.gif
        : exercise['gif_uuid'];
    if (gif != null) {
      if (gif is String && gif.isNotEmpty) {
        gifUuid = gif;
      } else if (gif is Map<String, dynamic>) {
        gifUuid = gif['uuid'] as String?;
      }
    }

    // Извлекаем UUID картинки
    final dynamic image = exercise is search_models.ExerciseReference
        ? exercise.image
        : exercise['image_uuid'];
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AuthImageWidget(
          imageUuid: imageUuid,
          height: 60,
          width: 60,
          fit: BoxFit.cover,
        ),
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

  Widget? _buildExerciseMediaForModal(
    search_models.ExerciseReference exercise,
  ) {
    // Приоритет: видео -> гиф -> картинка
    final String? videoUuid = exercise.video;
    final String? gifUuid = exercise.gif;
    final String? imageUuid = exercise.image;

    if (videoUuid != null) {
      return VideoPlayerWidget(
        videoUuid: videoUuid,
        imageUuid: imageUuid,
        height: 200,
        width: double.infinity,
        showControls: true,
        autoInitialize: true,
      );
    } else if (gifUuid != null) {
      return GifWidget(gifUuid: gifUuid, height: 200, width: 200);
    } else if (imageUuid != null) {
      return AuthImageWidget(imageUuid: imageUuid, height: 200, width: 200);
    } else {
      return Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Colors.grey, size: 48),
      );
    }
  }

  // Универсальные методы для получения данных упражнения
  String _getExerciseUuid(dynamic exercise) {
    if (exercise is search_models.ExerciseReference) {
      return exercise.uuid;
    } else if (exercise is Map<String, dynamic>) {
      return exercise['uuid'] ?? '';
    }
    return '';
  }

  bool _getExerciseIsFavorite(dynamic exercise) {
    if (exercise is search_models.ExerciseReference) {
      return exercise.isFavorite;
    } else if (exercise is Map<String, dynamic>) {
      return exercise['is_favorite'] ?? false;
    }
    return false;
  }

  List<dynamic> get _displayedExercises {
    final result = hasSearched ? searchResults : userExercises;
    return result;
  }

  Widget _buildPaginationControls() {
    // Показываем элементы пагинации всегда, когда есть элементы
    if (_displayedExercises.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Первая строка: выбор размера страницы и навигация по страницам
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Выбор размера страницы (слева)
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
                    _changePageSize(newSize);
                  }
                },
              ),
              const SizedBox(width: 16),
              // Навигация по страницам (справа, показываем только если есть несколько страниц)
              if (totalPages > 1)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: currentPage > 1
                            ? () => _goToPage(currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Flexible(
                        child: Text(
                          'Страница $currentPage из $totalPages',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: currentPage < totalPages
                            ? () => _goToPage(currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Вторая строка: всего элементов
          Text('Всего элементов: $totalItems'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхний раздел с кнопкой назад
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text(
                        'Выбрать упражнение',
                        style: NinjaText.title,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: NinjaSpacing.md),
                    const SizedBox(width: 48), // Для симметрии
                  ],
                ),
              ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: MetalSearchBar(
                  controller: _searchController,
                  hint: 'Поиск упражнений...',
                  onChanged: _onSearchChanged,
                ),
              ),
              // Фильтры - Группы мышц
              if (_availableMuscleGroups.isNotEmpty)
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Builder(
                    builder: (context) {
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: _availableMuscleGroups.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final muscleGroup = entry.value;
                          final isSelected = _selectedMuscleGroups.contains(
                            muscleGroup,
                          );
                          final isFirst = index == 0;
                          final isLast =
                              index == _availableMuscleGroups.length - 1;

                          return MetalButton(
                            label: muscleGroup,
                            onPressed: () {
                              _toggleMuscleGroupFilter(muscleGroup);
                            },
                            height: 36,
                            fontSize: 13,
                            isSelected: isSelected,
                            position: isFirst
                                ? MetalButtonPosition.first
                                : isLast
                                ? MetalButtonPosition.last
                                : MetalButtonPosition.middle,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              // Фильтры - Оборудование
              if (_availableEquipmentNames.isNotEmpty)
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Builder(
                    builder: (context) {
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: _availableEquipmentNames.asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final equipmentName = entry.value;
                          final isSelected = _selectedEquipmentNames.contains(
                            equipmentName,
                          );
                          final isFirst = index == 0;
                          final isLast =
                              index == _availableEquipmentNames.length - 1;

                          return MetalButton(
                            label: equipmentName,
                            onPressed: () {
                              _toggleEquipmentFilter(equipmentName);
                            },
                            height: 36,
                            fontSize: 13,
                            isSelected: isSelected,
                            position: isFirst
                                ? MetalButtonPosition.first
                                : isLast
                                ? MetalButtonPosition.last
                                : MetalButtonPosition.middle,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
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
                              hasSearched
                                  ? Icons.search_off
                                  : Icons.fitness_center,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasSearched
                                  ? 'По вашему запросу ничего не найдено'
                                  : 'Упражнения не найдены',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _displayedExercises.length + 1,
                        itemBuilder: (context, index) {
                          // Если это последний элемент, показываем пагинацию
                          if (index == _displayedExercises.length) {
                            return _buildPaginationControls();
                          }

                          final exercise = _displayedExercises[index];
                          final isSelected =
                              _selectedExercise != null &&
                              _selectedExercise!.uuid ==
                                  _getExerciseUuid(exercise);
                          final isFirst = index == 0;
                          final isLast = index == _displayedExercises.length - 1;

                          // Преобразуем в ExerciseReference для получения данных
                          search_models.ExerciseReference exerciseRef;
                          if (exercise is search_models.ExerciseReference) {
                            exerciseRef = exercise;
                          } else if (exercise is Map<String, dynamic>) {
                            exerciseRef =
                                search_models.ExerciseReference.fromJson(
                              exercise,
                            );
                          } else {
                            return const SizedBox.shrink();
                          }

                          return Stack(
                            children: [
                              MetalListItem(
                                leading: _buildExerciseMedia(exercise),
                                title: Text(
                                  exerciseRef.caption,
                                  style: NinjaText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.buttonPrimary
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  exerciseRef.muscleGroup,
                                  style: NinjaText.caption,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () =>
                                          _showExerciseDetail(exercise),
                                      tooltip: 'Детали упражнения',
                                      color: AppColors.textSecondary,
                                      iconSize: 20,
                                    ),
                                    _FavoriteButton(
                                      isFavorite: exerciseRef.isFavorite,
                                      onPressed: () async {
                                        await _toggleFavorite(exercise);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () => _selectExercise(exercise),
                                isFirst: isFirst,
                                isLast: isLast,
                                removeSpacing: true,
                              ),
                              // Индикатор выбора
                              if (isSelected)
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // Кнопка выбора
      bottomNavigationBar: _selectedExercise != null
          ? Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Градиент (нижний слой) - занимает всю область
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2E2E2E), Color(0xFF1E1E1E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.65),
                            offset: const Offset(0, 14),
                            blurRadius: 34,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.07),
                            offset: const Offset(0, -1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Текстура
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Image.asset(
                          'assets/textures/graphite_noise.png',
                          fit: BoxFit.cover,
                          color: Colors.white.withOpacity(0.04),
                          colorBlendMode: BlendMode.softLight,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                  // Внутренняя светотень по вертикали
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.12),
                                Colors.white.withOpacity(0.07),
                                Colors.black.withOpacity(0.20),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Градиентная обводка сверху
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFD3D3C6).withOpacity(0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.15],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Внутренняя светотень по горизонтали
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.50),
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Контент
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Выбрано:',
                                      style: NinjaText.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedExercise!.caption,
                                      style: NinjaText.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedExercise = null;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                color: AppColors.textSecondary,
                                tooltip: 'Отменить выбор',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MetalButton(
                            label: 'Выбрать',
                            onPressed: _confirmSelection,
                            height: 56,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
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
    return ScaleTransition(
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
    );
  }
}

