import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/search_service.dart';
import '../../services/user_training_service.dart';
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
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

    try {
      final results =
          await SearchService.searchAdminExerciseReferencesByCaption(
            query,
            page: currentPage,
            size: pageSize,
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

  Future<ImageProvider?> _loadExerciseImage(String? imageUuid) async {
    if (imageUuid == null || imageUuid.isEmpty) return null;
    try {
      final response = await ApiService.get('/files/file/$imageUuid');
      if (response.statusCode == 200) {
        return MemoryImage(response.bodyBytes);
      }
      return null;
    } catch (e) {
      print('[API] exception: $e');
      return null;
    }
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
                            searchResults.clear();
                            isSearching = false;
                            hasSearched = false;
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
                      final description = hasSearched
                          ? exercise.description
                          : exercise['description'] ?? '';
                      final uuid = hasSearched
                          ? exercise.uuid
                          : exercise['uuid'];

                      return ListTile(
                        leading: FutureBuilder<ImageProvider?>(
                          future: _loadExerciseImage(
                            hasSearched
                                ? exercise.imageId
                                      ?.toString() // Используем imageId вместо imageUuid
                                : exercise['image_uuid'],
                          ),
                          builder: (context, snapshot) {
                            final image = snapshot.data;
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[400]!,
                                  width: 1,
                                ),
                                image: image != null
                                    ? DecorationImage(
                                        image: image,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: image == null
                                  ? const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 20,
                                    )
                                  : null,
                            );
                          },
                        ),
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
