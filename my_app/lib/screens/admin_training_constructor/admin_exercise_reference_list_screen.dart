import 'dart:async';
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
  List<ExerciseReference> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool hasSearched = false;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

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
      queryParams: {'exercise_type': 'system'},
    );
    if (response.statusCode == 200) {
      final data = ApiService.decodeJson(response.body);
      setState(() {
        exercises = List<Map<String, dynamic>>.from(data);
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
          await SearchService.searchAdminExerciseReferencesByCaption(query);
      setState(() {
        searchResults = results;
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
      _performSearch(query);
    });
  }

  List<dynamic> get _displayedExercises {
    if (hasSearched) {
      return searchResults;
    }
    return exercises;
  }

  Future<void> _deleteExercise(String uuid) async {
    try {
      final response = await ApiService.delete(
        '/exercise_reference/delete/$uuid',
      );
      if (response.statusCode == 200) {
        setState(() {
          exercises.removeWhere((exercise) => exercise['uuid'] == uuid);
          searchResults.removeWhere((exercise) => exercise.uuid == uuid);
        });
      }
    } catch (e) {
      print('Error deleting exercise: $e');
    }
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
                    itemCount: _displayedExercises.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
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
                        title: Text(caption),
                        subtitle: Text(description),
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
