import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/search_service.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/exercise_filter_modal.dart';
import '../../models/search_result_model.dart' as search_models;

class AdminExerciseSelectorScreen extends StatefulWidget {
  const AdminExerciseSelectorScreen({Key? key}) : super(key: key);

  @override
  State<AdminExerciseSelectorScreen> createState() =>
      _AdminExerciseSelectorScreenState();
}

class _AdminExerciseSelectorScreenState
    extends State<AdminExerciseSelectorScreen> {
  List<Map<String, dynamic>> exercises = [];
  List<dynamic> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool hasSearched = false;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  // Фильтры
  List<String> _selectedMuscleGroups = [];
  List<String> _selectedEquipmentNames = [];

  // Пагинация
  int currentPage = 1;
  int pageSize = 10;
  int totalItems = 0;
  int totalPages = 0;
  final List<int> availablePageSizes = [10, 20, 50, 75];

  // Выбранное упражнение
  Map<String, dynamic>? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(
        '/exercise_reference/?exercise_type=system&page=$currentPage&size=$pageSize',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          exercises = List<Map<String, dynamic>>.from(data['items'] ?? []);
          totalItems = data['total'] ?? 0;
          totalPages = data['pages'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, List<String>>> _loadFilters() async {
    try {
      print('DEBUG: Admin - Loading filters...');
      final response = await ApiService.get(
        '/exercise_reference/system/filters',
      );
      print('DEBUG: Admin - Filters response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        print('DEBUG: Admin - Filters data: $data');
        final result = {
          'muscle_groups': List<String>.from(data['muscle_groups'] ?? []),
          'equipment_names': List<String>.from(data['equipment_names'] ?? []),
        };
        print('DEBUG: Admin - Parsed filters: $result');
        return result;
      }
      print('DEBUG: Admin - Filters response not 200, returning empty');
      return {'muscle_groups': [], 'equipment_names': []};
    } catch (e) {
      print('Error loading filters: $e');
      return {'muscle_groups': [], 'equipment_names': []};
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

    print('DEBUG: Admin - Performing search with query: "$query"');
    print('DEBUG: Admin - Selected muscle groups: $_selectedMuscleGroups');
    print('DEBUG: Admin - Selected equipment names: $_selectedEquipmentNames');

    try {
      final results =
          await SearchService.searchAdminExerciseReferencesByCaption(
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

  Future<void> _openFilterModal() async {
    print('DEBUG: Admin - Opening filter modal...');
    final filters = await _loadFilters();
    print('DEBUG: Admin - Filters loaded: $filters');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => ExerciseFilterModal(
        muscleGroups: filters['muscle_groups'] ?? [],
        equipmentNames: filters['equipment_names'] ?? [],
        initialSelectedMuscleGroups: _selectedMuscleGroups,
        initialSelectedEquipmentNames: _selectedEquipmentNames,
        onApplyFilters: (selectedMuscleGroups, selectedEquipmentNames) {
          print('DEBUG: Admin - onApplyFilters called');
          print('DEBUG: Admin - muscle groups: $selectedMuscleGroups');
          print('DEBUG: Admin - equipment names: $selectedEquipmentNames');
          setState(() {
            _selectedMuscleGroups = selectedMuscleGroups;
            _selectedEquipmentNames = selectedEquipmentNames;
          });

          // Применяем фильтры к текущему поиску
          if (_searchController.text.isNotEmpty) {
            print('DEBUG: Admin - performing search with filters');
            _performSearch(_searchController.text);
          } else {
            print(
              'DEBUG: Admin - performing search with empty text and filters',
            );
            _performSearch('');
          }
        },
      ),
    );
  }

  void _selectExercise(dynamic exercise) {
    // Преобразуем в Map если нужно
    Map<String, dynamic> exerciseMap;

    if (exercise is search_models.ExerciseReference) {
      exerciseMap = {
        'uuid': exercise.uuid,
        'caption': exercise.caption,
        'description': exercise.description,
        'muscle_group': exercise.muscleGroup,
        'equipment_name': exercise.equipmentName,
        'auxiliary_muscle_groups': exercise.auxiliaryMuscleGroups,
        'technique_description': exercise.techniqueDescription,
        'gif_uuid': exercise.gif,
        'image_uuid': exercise.image,
        'video_uuid': exercise.video,
      };
    } else if (exercise is Map<String, dynamic>) {
      exerciseMap = exercise;
    } else {
      return; // Неизвестный тип
    }

    setState(() {
      _selectedExercise = exerciseMap;
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
        _fetchExercises();
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
      _fetchExercises();
    }
  }

  void _showExerciseDetail(dynamic exercise) {
    // Преобразуем в Map если нужно
    Map<String, dynamic> exerciseMap;

    if (exercise is search_models.ExerciseReference) {
      exerciseMap = {
        'uuid': exercise.uuid,
        'caption': exercise.caption,
        'description': exercise.description,
        'muscle_group': exercise.muscleGroup,
        'equipment_name': exercise.equipmentName,
        'auxiliary_muscle_groups': exercise.auxiliaryMuscleGroups,
        'technique_description': exercise.techniqueDescription,
        'gif_uuid': exercise.gif,
        'image_uuid': exercise.image,
        'video_uuid': exercise.video,
      };
    } else if (exercise is Map<String, dynamic>) {
      exerciseMap = exercise;
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
                        'Название: ${exerciseMap['caption'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Описание: ${exerciseMap['description'] ?? ''}'),
                      const SizedBox(height: 8),
                      Text(
                        'Мышечная группа: ${exerciseMap['muscle_group'] ?? ''}',
                      ),
                      // Вспомогательные группы мышц (только для админских упражнений)
                      if (exerciseMap['auxiliary_muscle_groups'] != null &&
                          exerciseMap['auxiliary_muscle_groups']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Вспомогательные группы мышц: ${exerciseMap['auxiliary_muscle_groups']}',
                        ),
                      ],
                      // Оборудование
                      if (exerciseMap['equipment_name'] != null &&
                          exerciseMap['equipment_name']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Оборудование: ${exerciseMap['equipment_name']}'),
                      ],
                      if (exerciseMap['technique_description'] != null &&
                          exerciseMap['technique_description']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Техника выполнения:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(exerciseMap['technique_description']),
                      ],
                      const SizedBox(height: 24),
                      // Гифка (отображаем только если есть gif_uuid)
                      if (exerciseMap['gif_uuid'] != null) ...[
                        GifWidget(
                          gifUuid: exerciseMap['gif_uuid'],
                          height: 250,
                        ),
                        const SizedBox(height: 24),
                      ],
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
    // Приоритет: сначала гифка, потом картинка
    String? gifUuid;
    String? imageUuid;

    if (exercise is search_models.ExerciseReference) {
      gifUuid = exercise.gif;
      imageUuid = exercise.image;
    } else if (exercise is Map<String, dynamic>) {
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

  List<dynamic> get _displayedExercises {
    final result = hasSearched ? searchResults : exercises;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбрать упражнение'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar and Filter Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _openFilterModal,
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list),
                      if (_selectedMuscleGroups.isNotEmpty ||
                          _selectedEquipmentNames.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        (_selectedMuscleGroups.isNotEmpty ||
                            _selectedEquipmentNames.isNotEmpty)
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
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
                          _selectedExercise!['uuid'] ==
                              _getExerciseUuid(exercise);

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
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getExerciseDescription(exercise),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Группа мышц: ${_getExerciseMuscleGroup(exercise)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () => _selectExercise(exercise),
                            ),
                            // Кнопка информации
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => _showExerciseDetail(exercise),
                                tooltip: 'Детали упражнения',
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
      // Пагинация
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalItems > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
                            _selectedExercise!['caption'] ?? '',
                            style: TextStyle(
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
                            backgroundColor: Colors.blue,
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
