import 'package:flutter/material.dart';
import '../models/exercise_statistics_model.dart';
import '../services/api_service.dart';
import '../constants/app_colors.dart';
import '../widgets/gif_widget.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/exercise_statistics_table.dart';
import '../widgets/metal_modal.dart';
import '../widgets/metal_card.dart';

class ExerciseInfoModal {
  static Future<void> show({
    required BuildContext context,
    required String exerciseReferenceUuid,
    required String userUuid,
    String? exerciseName,
  }) {
    return MetalModal.show(
      context: context,
      title: exerciseName ?? 'Информация об упражнении',
      children: [
        _ExerciseInfoContent(
          exerciseReferenceUuid: exerciseReferenceUuid,
          userUuid: userUuid,
          hideExerciseName: exerciseName != null,
        ),
      ],
    );
  }
}

class _ExerciseInfoContent extends StatefulWidget {
  final String exerciseReferenceUuid;
  final String userUuid;
  final bool hideExerciseName;

  const _ExerciseInfoContent({
    required this.exerciseReferenceUuid,
    required this.userUuid,
    this.hideExerciseName = false,
  });

  @override
  State<_ExerciseInfoContent> createState() => _ExerciseInfoContentState();
}

class _ExerciseInfoContentState extends State<_ExerciseInfoContent> {
  Map<String, dynamic>? exerciseReference;
  ExerciseStatisticsModel? statistics;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    print('🔍 Загрузка данных в модальном окне:');
    print('  exerciseReferenceUuid: ${widget.exerciseReferenceUuid}');
    print('  userUuid: ${widget.userUuid}');

    try {
      // Загружаем данные справочника упражнения
      print('📥 Загружаем справочник упражнения...');
      final referenceData = await ApiService.getExerciseReference(
        widget.exerciseReferenceUuid,
      );
      print('📥 Результат загрузки справочника: $referenceData');

      // Загружаем статистику упражнения
      print('📊 Загружаем статистику упражнения...');
      final statisticsData = await ApiService.getExerciseStatistics(
        widget.exerciseReferenceUuid,
        widget.userUuid,
      );
      print('📊 Результат загрузки статистики: $statisticsData');

      if (mounted) {
        setState(() {
          exerciseReference = referenceData;
          if (statisticsData != null) {
            statistics = ExerciseStatisticsModel.fromJson(statisticsData);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ошибка в _loadData: $e');
      if (mounted) {
        setState(() {
          error = 'Ошибка загрузки данных: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Собираем список виджетов для MetalModal
    List<Widget> children = [];

    if (isLoading) {
      children.add(
        const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (error != null) {
      children.add(
        SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Название упражнения (показываем только если не скрыто)
      if (!widget.hideExerciseName && exerciseReference?['caption'] != null) {
        children.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  exerciseReference!['caption'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 16));
      }

      // Описание
      if (exerciseReference?['description'] != null) {
        children.add(
          const Text(
            'Описание:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
        children.add(const SizedBox(height: 8));
        children.add(
          Text(
            exerciseReference!['description'],
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        );
        children.add(const SizedBox(height: 16));
      }

      // Мышечная группа
      if (exerciseReference?['muscle_group'] != null) {
        children.add(
          const Text(
            'Мышечная группа:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
        children.add(const SizedBox(height: 8));
        children.add(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.inputBorder.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exerciseReference!['muscle_group'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
        children.add(const SizedBox(height: 16));
      }

      // Медиа: приоритет видео, затем гифка
      if (exerciseReference?['video_uuid'] != null) {
        children.add(
          SizedBox(
            height: 200,
            child: VideoPlayerWidget(
              videoUuid: exerciseReference!['video_uuid'],
              imageUuid: exerciseReference!['image_uuid'],
              width: double.infinity,
              height: 200,
              showControls: true,
              autoInitialize: true,
            ),
          ),
        );
        children.add(const SizedBox(height: 16));
      } else if (exerciseReference?['gif_uuid'] != null) {
        children.add(
          SizedBox(
            height: 200,
            child: GifWidget(
              gifUuid: exerciseReference!['gif_uuid'],
              width: double.infinity,
              height: 200,
            ),
          ),
        );
        children.add(const SizedBox(height: 16));
      }

      // Техника выполнения (только если есть)
      if (exerciseReference?['technique'] != null &&
          exerciseReference!['technique'].toString().isNotEmpty) {
        children.add(
          const Text(
            'Техника выполнения:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
        children.add(const SizedBox(height: 8));
        children.add(
          Text(
            exerciseReference!['technique'],
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        );
        children.add(const SizedBox(height: 16));
      }

      // История выполнения
      if (statistics != null) {
        children.add(
          const Text(
            'Дневник:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
        children.add(const SizedBox(height: 8));
        children.add(
          MetalCard(
            child: ExerciseStatisticsTable(statistics: statistics!),
          ),
        );
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.95,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
