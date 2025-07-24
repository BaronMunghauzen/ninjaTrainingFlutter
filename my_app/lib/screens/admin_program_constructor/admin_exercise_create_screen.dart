import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class ExerciseCreateScreen extends StatefulWidget {
  final String exerciseGroupUuid;

  const ExerciseCreateScreen({Key? key, required this.exerciseGroupUuid})
    : super(key: key);

  @override
  State<ExerciseCreateScreen> createState() => _ExerciseCreateScreenState();
}

class _ExerciseCreateScreenState extends State<ExerciseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _durationController = TextEditingController();
  final _orderController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final body = {
        'exercise_group_uuid': widget.exerciseGroupUuid,
        'caption': _captionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'difficulty_level':
            int.tryParse(_difficultyController.text.trim()) ?? 1,
        'duration': int.tryParse(_durationController.text.trim()) ?? 1,
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'muscle_group': _muscleGroupController.text.trim(),
        'reps': int.tryParse(_repsController.text.trim()) ?? 10,
        'sets': int.tryParse(_setsController.text.trim()) ?? 3,
        'exercise_type': 'system',
      };

      final response = await ApiService.post('/exercises/add/', body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          final data = ApiService.decodeJson(response.body);
          final uuid = data['uuid']?.toString();
          Navigator.of(context).pop(uuid);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания упражнения: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _difficultyController.dispose();
    _durationController.dispose();
    _orderController.dispose();
    _muscleGroupController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать упражнение'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Название',
                controller: _captionController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Описание',
                controller: _descriptionController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите описание' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Уровень сложности (от 1)',
                controller: _difficultyController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите уровень сложности' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Продолжительность (в минутах)',
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите продолжительность' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Порядок/сортировка (от 0)',
                controller: _orderController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите порядок' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Группа мышц',
                controller: _muscleGroupController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите группу мышц' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Количество повторений',
                controller: _repsController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? 'Введите количество повторений'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Количество подходов',
                controller: _setsController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? 'Введите количество подходов'
                    : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Создать',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
