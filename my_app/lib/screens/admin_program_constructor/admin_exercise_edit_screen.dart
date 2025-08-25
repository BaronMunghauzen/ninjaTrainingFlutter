import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class AdminExerciseEditScreen extends StatefulWidget {
  final String exerciseUuid;
  final Map<String, dynamic> initialData;

  const AdminExerciseEditScreen({
    Key? key,
    required this.exerciseUuid,
    required this.initialData,
  }) : super(key: key);

  @override
  State<AdminExerciseEditScreen> createState() =>
      _AdminExerciseEditScreenState();
}

class _AdminExerciseEditScreenState extends State<AdminExerciseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _durationController = TextEditingController();
  final _orderController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  bool _withWeight = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _captionController.text = widget.initialData['caption'] ?? '';
    _descriptionController.text = widget.initialData['description'] ?? '';
    _difficultyController.text = (widget.initialData['difficulty_level'] ?? 1)
        .toString();
    _durationController.text = (widget.initialData['rest_time'] ?? 1)
        .toString();
    _orderController.text = (widget.initialData['order'] ?? 0).toString();
    _muscleGroupController.text = widget.initialData['muscle_group'] ?? '';
    _repsController.text = (widget.initialData['reps_count'] ?? 10).toString();
    _setsController.text = (widget.initialData['sets_count'] ?? 3).toString();
    _withWeight = widget.initialData['with_weight'] ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final body = {
        'caption': _captionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'difficulty_level':
            int.tryParse(_difficultyController.text.trim()) ?? 1,
        'rest_time': int.tryParse(_durationController.text.trim()) ?? 1,
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'muscle_group': _muscleGroupController.text.trim(),
        'reps_count': int.tryParse(_repsController.text.trim()) ?? 10,
        'sets_count': int.tryParse(_setsController.text.trim()) ?? 3,
        'with_weight': _withWeight,
      };

      final response = await ApiService.put(
        '/exercises/update/${widget.exerciseUuid}',
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка обновления упражнения: ${response.statusCode}',
            ),
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
        title: const Text('Редактировать упражнение'),
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
                label: 'Время отдыха (в секундах)',
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
              const SizedBox(height: 16),
              SwitchListTile(
                value: _withWeight,
                onChanged: (v) => setState(() => _withWeight = v),
                title: const Text('С отягощением'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Сохранить',
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
