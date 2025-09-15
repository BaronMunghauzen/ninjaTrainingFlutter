import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/search_result_model.dart' as search_models;
import '../../widgets/gif_widget.dart';
import 'user_exercise_reference_edit_screen.dart';

class UserExerciseReferenceDetailScreen extends StatefulWidget {
  final search_models.ExerciseReference exercise;

  const UserExerciseReferenceDetailScreen({super.key, required this.exercise});

  @override
  State<UserExerciseReferenceDetailScreen> createState() =>
      _UserExerciseReferenceDetailScreenState();
}

class _UserExerciseReferenceDetailScreenState
    extends State<UserExerciseReferenceDetailScreen> {
  search_models.ExerciseReference? _exercise;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercise();
  }

  Future<void> _fetchExercise() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        '/exercise_reference/${widget.exercise.uuid}',
      );
      if (response.statusCode == 200) {
        final data = ApiService.decodeJson(response.body);
        setState(() {
          _exercise = search_models.ExerciseReference.fromJson(data);
          _isLoading = false;
        });
      } else {
        // Если запрос не удался, используем переданные данные
        setState(() {
          _exercise = widget.exercise;
          _isLoading = false;
        });
      }
    } catch (e) {
      // В случае ошибки используем переданные данные
      setState(() {
        _exercise = widget.exercise;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.exercise.caption,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final exercise = _exercise ?? widget.exercise;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.caption,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (exercise.exerciseType == 'user') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserExerciseReferenceEditScreen(exercise: exercise),
                  ),
                );

                // Если упражнение было обновлено, обновляем экран
                if (result == true) {
                  _fetchExercise();
                }
              },
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название упражнения и индикатор типа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.caption,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exercise.exerciseType == 'user' ? 'Мое' : 'Системное',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Описание
            Text(
              'Описание:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // Гифка (только для системных упражнений)
            if (exercise.exerciseType == 'system')
              Builder(
                builder: (context) {
                  String? gifUuid;
                  final dynamic gif = exercise.gif;

                  // API может возвращать gif_uuid как строку или как объект
                  if (gif is String && gif.isNotEmpty) {
                    gifUuid = gif;
                  } else if (gif is Map<String, dynamic>) {
                    gifUuid = gif['uuid'] as String?;
                  }

                  if (gifUuid == null || gifUuid.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return GifWidget(
                    gifUuid: gifUuid,
                    height: 250,
                    width: double.infinity,
                  );
                },
              ),
            const SizedBox(height: 24),

            // Техника выполнения (если есть)
            if (exercise.techniqueDescription != null &&
                exercise.techniqueDescription!.isNotEmpty) ...[
              Text(
                'Техника выполнения:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.techniqueDescription!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Группа мышц
            Text(
              'Группа мышц:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.muscleGroup,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
