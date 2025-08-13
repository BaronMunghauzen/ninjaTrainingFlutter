import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_training_service.dart';
import '../../services/search_service.dart';
import 'user_exercise_reference_create_screen.dart';
import 'user_exercise_reference_detail_screen.dart';
import 'user_exercise_reference_edit_screen.dart';

class UserExerciseReferenceListScreen extends StatefulWidget {
  const UserExerciseReferenceListScreen({Key? key}) : super(key: key);

  @override
  State<UserExerciseReferenceListScreen> createState() =>
      _UserExerciseReferenceListScreenState();
}

class _UserExerciseReferenceListScreenState
    extends State<UserExerciseReferenceListScreen> {
  List<ExerciseReference> userExercises = [];
  List<ExerciseReference> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  bool hasSearched = false;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      );
      setState(() {
        userExercises = exercises;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user exercises: $e');
      setState(() {
        isLoading = false;
      });
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
      );
      setState(() {
        searchResults = results;
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
    _searchDebounce = Timer(const Duration(seconds: 1), () {
      _performSearch(query);
    });
  }

  List<ExerciseReference> get _displayedExercises {
    if (hasSearched) {
      return searchResults;
    }
    return userExercises;
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
                          });
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _displayedExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = _displayedExercises[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.fitness_center,
                            color: AppColors.textPrimary,
                          ),
                          title: Text(
                            exercise.caption,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: exercise.exerciseType == 'user'
                                          ? AppColors.buttonPrimary
                                          : AppColors.textSecondary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      exercise.exerciseType == 'user'
                                          ? 'Пользовательская'
                                          : 'Системная',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
                            ],
                          ),
                          trailing: exercise.exerciseType == 'user'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result =
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UserExerciseReferenceEditScreen(
                                                      exercise: exercise,
                                                    ),
                                              ),
                                            );
                                        if (result == true) {
                                          _loadUserExercises();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Удаление упражнения',
                                            ),
                                            content: const Text(
                                              'Вы уверены, что хотите удалить это упражнение?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: const Text('Отмена'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                child: const Text('Удалить'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          final success =
                                              await UserTrainingService.deleteExerciseReference(
                                                exercise.uuid,
                                              );
                                          if (success) {
                                            _loadUserExercises();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Упражнение удалено',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : null,
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
                      );
                    },
                  ),
          ),
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
