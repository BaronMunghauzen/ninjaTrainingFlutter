import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/training_service.dart';
import 'system_exercise_group_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ActiveSystemTrainingScreen extends StatefulWidget {
  final Map<String, dynamic> userTraining;
  const ActiveSystemTrainingScreen({Key? key, required this.userTraining})
    : super(key: key);

  @override
  State<ActiveSystemTrainingScreen> createState() =>
      _ActiveSystemTrainingScreenState();
}

class _ActiveSystemTrainingScreenState
    extends State<ActiveSystemTrainingScreen> {
  List<Map<String, dynamic>> _exerciseGroups = [];
  bool _isLoadingGroups = false;
  bool _showCongrats = false;

  @override
  void initState() {
    super.initState();
    _loadExerciseGroups();
  }

  Future<void> _loadExerciseGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });
    try {
      final groups = await TrainingService.getExerciseGroups(
        widget.userTraining['training']['uuid'],
      );
      setState(() {
        _exerciseGroups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _skipTraining() async {
    try {
      final response = await TrainingService.skipUserTrainingWithResponse(
        widget.userTraining['uuid'],
      );
      if (response['success'] == true) {
        setState(() {
          _showCongrats = response['next_stage_created'] == true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка пропущена')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка пропуска тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _passTraining() async {
    try {
      final response = await TrainingService.passUserTrainingWithResponse(
        widget.userTraining['uuid'],
      );
      if (response['success'] == true) {
        setState(() {
          _showCongrats = response['next_stage_created'] == true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тренировка завершена')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка завершения тренировки')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.userTraining['training'] ?? {};
    final isRestDay = widget.userTraining['is_rest_day'] ?? false;
    final status =
        widget.userTraining['status']?.toString()?.toLowerCase() ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Активная тренировка')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              training['caption'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isRestDay)
              Column(
                children: [
                  Icon(Icons.bedtime, size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 20),
                  const Text(
                    'День отдыха',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Сегодня можно отдохнуть и восстановиться',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _passTraining,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Завершить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              )
            else ...[
              Expanded(
                child: _isLoadingGroups
                    ? const Center(child: CircularProgressIndicator())
                    : _exerciseGroups.isEmpty
                    ? const Center(child: Text('Нет групп упражнений'))
                    : ListView.separated(
                        itemCount: _exerciseGroups.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final group = _exerciseGroups[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SystemExerciseGroupScreen(
                                        exerciseGroupUuid: group['uuid'],
                                        userTraining: widget.userTraining,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        group['caption'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              if (status == 'active')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipTraining,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Пропустить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _passTraining,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Завершить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (status == 'passed')
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Тренировка завершена',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (status == 'skipped')
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Тренировка пропущена',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
