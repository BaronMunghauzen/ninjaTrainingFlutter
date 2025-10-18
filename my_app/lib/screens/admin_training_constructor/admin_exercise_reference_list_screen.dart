import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/search_service.dart';
import '../../widgets/gif_widget.dart';
import '../../widgets/auth_image_widget.dart';
import '../../widgets/exercise_filter_modal.dart';
import 'admin_exercise_reference_create_screen.dart';
import 'admin_exercise_reference_detail_screen.dart';

class AdminExerciseReferenceListScreen extends StatefulWidget {
  const AdminExerciseReferenceListScreen({Key? key}) : super(key: key);

  @override
  State<AdminExerciseReferenceListScreen> createState() =>
      _AdminExerciseReferenceListScreenState();
}

class _AdminExerciseReferenceListScreenState
    extends State<AdminExerciseReferenceListScreen> {
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
    final response = await ApiService.get(
      '/exercise_reference/',
      queryParams: {
        'exercise_type': 'system',
        'page': currentPage,
        'size': pageSize,
      },
    );
    if (response.statusCode == 200) {
      final data = ApiService.decodeJson(response.body);
      setState(() {
        exercises = List<Map<String, dynamic>>.from(data['items'] ?? []);
        totalItems = data['total'] ?? 0;
        totalPages = data['pages'] ?? 0;
        currentPage = data['page'] ?? 1;
        isLoading = false;
      });
    } else {
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
      _fetchExercises();
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
      _fetchExercises();
    }
  }

  List<dynamic> get _displayedExercises {
    final result = hasSearched ? searchResults : exercises;
    return result;
  }

  Widget _buildExerciseMedia(dynamic exercise) {
    // Приоритет: сначала гифка, потом картинка
    String? gifUuid;
    String? imageUuid;

    // Извлекаем UUID гифки
    final dynamic gif = hasSearched ? exercise.gif : exercise['gif_uuid'];
    if (gif != null) {
      if (gif is String && gif.isNotEmpty) {
        gifUuid = gif;
      } else if (gif is Map<String, dynamic>) {
        gifUuid = gif['uuid'] as String?;
      }
    }

    // Извлекаем UUID картинки
    final dynamic image = hasSearched ? exercise.image : exercise['image_uuid'];
    if (image != null) {
      if (image is String && image.isNotEmpty) {
        imageUuid = image;
      } else if (image is Map<String, dynamic>) {
        imageUuid = image['uuid'] as String?;
      }
    }

    // Если есть гифка, показываем её
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

    // Если нет гифки, но есть картинка, показываем её
    if (imageUuid != null && imageUuid.isNotEmpty) {
      return AuthImageWidget(
        imageUuid: imageUuid,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
      );
    }

    // Если нет ни гифки, ни картинки, показываем пустое место
    return SizedBox(
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Icon(Icons.image, color: Colors.grey, size: 24),
      ),
    );
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

  Future<void> _deleteExercise(String uuid) async {
    try {
      final response = await ApiService.delete(
        '/exercise_reference/delete/$uuid',
      );
      if (response.statusCode == 200) {
        setState(() {
          exercises.removeWhere((exercise) => exercise['uuid'] == uuid);
          // Для searchResults используем правильное поле uuid
          if (hasSearched) {
            searchResults.removeWhere((exercise) => exercise.uuid == uuid);
          }
        });
      }
    } catch (e) {
      print('Error deleting exercise: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                  searchResults.clear();
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
                ? const Center(child: CircularProgressIndicator())
                : _displayedExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasSearched ? Icons.search_off : Icons.fitness_center,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasSearched
                              ? 'По вашему запросу ничего не найдено'
                              : 'Нет упражнений',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount:
                        _displayedExercises.length +
                        1, // +1 для элементов пагинации
                    separatorBuilder: (context, index) {
                      // Не показываем разделитель перед элементами пагинации
                      if (index == _displayedExercises.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return const Divider();
                    },
                    itemBuilder: (context, i) {
                      // Если это последний элемент, показываем пагинацию
                      if (i == _displayedExercises.length) {
                        return _buildPaginationControls();
                      }

                      final exercise = _displayedExercises[i];

                      final caption = hasSearched
                          ? exercise.caption
                          : exercise['caption'] ?? '';
                      final uuid = hasSearched
                          ? exercise.uuid
                          : exercise['uuid'];

                      return ListTile(
                        leading: _buildExerciseMedia(exercise),
                        title: Text(caption),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminExerciseReferenceDetailScreen(
                              exerciseReferenceUuid: uuid,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _deleteExercise(uuid),
                        ),
                      );
                    },
                  ),
          ),
          // Элементы управления пагинацией
          // _buildPaginationControls(), // Moved to the end of the ListView
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminExerciseReferenceCreateScreen(),
            ),
          );
          _fetchExercises();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
