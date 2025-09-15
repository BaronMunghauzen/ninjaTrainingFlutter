import 'package:flutter/material.dart';
import '../models/exercise_statistics_model.dart';
import '../services/api_service.dart';
import '../constants/app_colors.dart';
import '../widgets/gif_widget.dart';
import '../widgets/exercise_statistics_table.dart';

class ExerciseInfoModal extends StatefulWidget {
  final String exerciseReferenceUuid;
  final String userUuid;

  const ExerciseInfoModal({
    Key? key,
    required this.exerciseReferenceUuid,
    required this.userUuid,
  }) : super(key: key);

  @override
  State<ExerciseInfoModal> createState() => _ExerciseInfoModalState();
}

class _ExerciseInfoModalState extends State<ExerciseInfoModal> {
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
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBorder.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Информация об упражнении',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),

            // Содержимое
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
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
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название упражнения
                          if (exerciseReference?['caption'] != null) ...[
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
                            const SizedBox(height: 16),
                          ],

                          // Описание
                          if (exerciseReference?['description'] != null) ...[
                            const Text(
                              'Описание:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exerciseReference!['description'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Мышечная группа
                          if (exerciseReference?['muscle_group'] != null) ...[
                            const Text(
                              'Мышечная группа:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 16),
                          ],

                          // Гифка
                          if (exerciseReference?['gif_uuid'] != null) ...[
                            GifWidget(
                              gifUuid: exerciseReference!['gif_uuid'],
                              width: double.infinity,
                              height: 200,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Техника выполнения (только если есть)
                          if (exerciseReference?['technique'] != null &&
                              exerciseReference!['technique']
                                  .toString()
                                  .isNotEmpty) ...[
                            const Text(
                              'Техника выполнения:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exerciseReference!['technique'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // История выполнения
                          if (statistics != null) ...[
                            const Text(
                              'Дневник:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ExerciseStatisticsTable(statistics: statistics!),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
