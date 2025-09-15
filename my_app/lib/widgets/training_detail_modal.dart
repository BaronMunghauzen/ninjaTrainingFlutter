import 'package:flutter/material.dart';
import '../models/user_training_model.dart';
import '../constants/app_colors.dart';

class TrainingDetailModal extends StatefulWidget {
  final DateTime selectedDate;
  final List<UserTrainingModel> trainings;

  const TrainingDetailModal({
    super.key,
    required this.selectedDate,
    required this.trainings,
  });

  @override
  State<TrainingDetailModal> createState() => _TrainingDetailModalState();
}

class _TrainingDetailModalState extends State<TrainingDetailModal> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Тренировки ${_formatDate(widget.selectedDate)}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация о тренировках
              ...widget.trainings.map(
                (training) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        training.training.caption,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Длительность: ${training.training.duration} мин',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Группа мышц: ${training.training.muscleGroup}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (training.program.caption.isNotEmpty)
                        Text(
                          'Программа: ${training.program.caption}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Закрыть', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
