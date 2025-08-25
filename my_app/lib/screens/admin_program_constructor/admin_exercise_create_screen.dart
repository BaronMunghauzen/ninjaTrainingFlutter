import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/program_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import '../admin_training_constructor/widgets.dart';

class ExerciseCreateScreen extends StatefulWidget {
  final String exerciseGroupUuid;

  const ExerciseCreateScreen({Key? key, required this.exerciseGroupUuid})
    : super(key: key);

  @override
  State<ExerciseCreateScreen> createState() => _ExerciseCreateScreenState();
}

class _ExerciseCreateScreenState extends State<ExerciseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _selectedExerciseRef;
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

  void _onExerciseSelected(Map<String, dynamic>? ex) {
    setState(() {
      _selectedExerciseRef = ex;
      if (ex != null) {
        _captionController.text = ex['caption'] ?? '';
        _descriptionController.text = ex['description'] ?? '';
        _muscleGroupController.text = ex['muscle_group'] ?? '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedExerciseRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите упражнение из справочника'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        'rest_time': int.tryParse(_durationController.text.trim()) ?? 1,
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'muscle_group': _muscleGroupController.text.trim(),
        'reps_count': int.tryParse(_repsController.text.trim()) ?? 10,
        'sets_count': int.tryParse(_setsController.text.trim()) ?? 3,
        'exercise_type': 'system',
        'exercise_reference_uuid': _selectedExerciseRef!['uuid'],
        'with_weight': _withWeight,
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
              ExerciseReferenceSelector(
                onSelected: _onExerciseSelected,
                label: 'Выбрать упражнение из справочника',
                buildQueryParams: (search) => {
                  'caption': search,
                  'exercise_type': 'system',
                },
              ),
              const SizedBox(height: 16),
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
