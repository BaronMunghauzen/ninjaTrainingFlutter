import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/search_service.dart';
import '../../services/api_service.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/video_player_widget.dart';
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
  String? _activeVideoUuid;
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
      _activeVideoUuid = exerciseRef.video;
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

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Заголовок с кнопкой закрытия
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Детали упражнения',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Контент
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Название: ${exerciseRef.caption}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Описание: ${exerciseRef.description}'),
                      const SizedBox(height: 8),
                      Text('Мышечная группа: ${exerciseRef.muscleGroup}'),
                      // Оборудование
                      const SizedBox(height: 8),
                      Text(
                        'Оборудование: ${exerciseRef.equipmentName ?? 'Без оборудования'}',
                      ),
                      // Медиа (гифка или картинка)
                      const SizedBox(height: 16),
                      Center(child: _buildExerciseMediaForModal(exerciseRef)),
                      if (exerciseRef.techniqueDescription != null &&
                          exerciseRef.techniqueDescription!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Техника выполнения:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(exerciseRef.techniqueDescription!),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildExerciseMedia(dynamic exercise) {
    // Приоритет: видео -> гиф -> картинка
    String? videoUuid;
    String? gifUuid;
    String? imageUuid;

    if (exercise is search_models.ExerciseReference) {
      videoUuid = exercise.video;
      gifUuid = exercise.gif;
      imageUuid = exercise.image;
    } else if (exercise is Map<String, dynamic>) {
      videoUuid = exercise['video_uuid'];
      gifUuid = exercise['gif_uuid'];
      imageUuid = exercise['image_uuid'];
    }

    if (gifUuid != null) {
      return GifWidget(gifUuid: gifUuid, height: 60, width: 60);
    } else if (imageUuid != null) {
      return AuthImageWidget(imageUuid: imageUuid, height: 60, width: 60);
    } else {
      return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, color: Colors.grey, size: 24),
      );
    }
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
  String _getExerciseCaption(dynamic exercise) {
    if (exercise is search_models.ExerciseReference) {
      return exercise.caption;
    } else if (exercise is Map<String, dynamic>) {
      return exercise['caption'] ?? '';
    }
    return '';
  }

  String _getExerciseDescription(dynamic exercise) {
    if (exercise is search_models.ExerciseReference) {
      return exercise.description;
    } else if (exercise is Map<String, dynamic>) {
      return exercise['description'] ?? '';
    }
    return '';
  }

  String _getExerciseMuscleGroup(dynamic exercise) {
    if (exercise is search_models.ExerciseReference) {
      return exercise.muscleGroup;
    } else if (exercise is Map<String, dynamic>) {
      return exercise['muscle_group'] ?? '';
    }
    return '';
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Выбрать упражнение',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                ? const Center(
                    child: Text(
                      'Упражнения не найдены',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _displayedExercises.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final exercise = _displayedExercises[index];
                      final isSelected =
                          _selectedExercise != null &&
                          _selectedExercise!.uuid == _getExerciseUuid(exercise);

                      return Card(
                        margin: EdgeInsets.zero,
                        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                            width: isSelected ? 2 : 0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            ListTile(
                              leading: _buildExerciseMedia(exercise),
                              title: Padding(
                                padding: const EdgeInsets.only(right: 120),
                                child: Text(
                                  _getExerciseCaption(exercise),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getExerciseDescription(exercise),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Группа мышц: ${_getExerciseMuscleGroup(exercise)}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _selectExercise(exercise),
                            ),
                            // Кнопка информации
                            Positioned(
                              right: 40,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => _showExerciseDetail(exercise),
                                tooltip: 'Детали упражнения',
                              ),
                            ),
                            // Кнопка избранного (сердечко)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: _FavoriteButton(
                                isFavorite: _getExerciseIsFavorite(exercise),
                                onPressed: () async {
                                  await _toggleFavorite(exercise);
                                },
                              ),
                            ),
                            // Индикатор выбора
                            if (isSelected)
                              const Positioned(
                                right: 8,
                                bottom: 8,
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Пагинация и кнопка выбора
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalItems > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                border: Border(
                  top: BorderSide(
                    color: AppColors.inputBorder.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Размер страницы
                  Row(
                    children: [
                      Text(
                        'Показать:',
                        style: TextStyle(color: Colors.grey[200]),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: pageSize,
                        items: availablePageSizes.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(
                              size.toString(),
                              style: TextStyle(color: Colors.grey[200]),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _changePageSize(value);
                          }
                        },
                      ),
                    ],
                  ),
                  // Навигация по страницам
                  Row(
                    children: [
                      IconButton(
                        onPressed: currentPage > 1
                            ? () => _goToPage(currentPage - 1)
                            : null,
                        icon: Icon(Icons.chevron_left, color: Colors.grey[200]),
                      ),
                      Text(
                        '${currentPage} из ${totalPages}',
                        style: TextStyle(color: Colors.grey[200]),
                      ),
                      IconButton(
                        onPressed: currentPage < totalPages
                            ? () => _goToPage(currentPage + 1)
                            : null,
                        icon: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Кнопка выбора
          if (_selectedExercise != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Выбрано:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[300],
                            ),
                          ),
                          Text(
                            _selectedExercise!.caption,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedExercise = null;
                            });
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Отменить выбор',
                        ),
                        ElevatedButton(
                          onPressed: _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Выбрать',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
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
