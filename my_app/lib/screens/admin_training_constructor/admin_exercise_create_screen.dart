import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'widgets.dart';

class AdminExerciseCreateScreen extends StatefulWidget {
  final String exerciseGroupUuid;
  const AdminExerciseCreateScreen({Key? key, required this.exerciseGroupUuid})
    : super(key: key);

  @override
  State<AdminExerciseCreateScreen> createState() =>
      _AdminExerciseCreateScreenState();
}

class _AdminExerciseCreateScreenState extends State<AdminExerciseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _selectedExerciseRef;
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _orderController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _restTimeController = TextEditingController();
  final _weightController = TextEditingController();
  bool _withWeight = false;
  bool isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _difficultyController.dispose();
    _orderController.dispose();
    _muscleGroupController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restTimeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

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
    if (!_formKey.currentState!.validate() || _selectedExerciseRef == null)
      return;
    setState(() => isLoading = true);
    final body = {
      'exercise_type': 'system',
      'caption': _captionController.text,
      'description': _descriptionController.text,
      'difficulty_level': int.tryParse(_difficultyController.text) ?? 1,
      'order': int.tryParse(_orderController.text) ?? 0,
      'muscle_group': _muscleGroupController.text,
      'sets_count': int.tryParse(_setsController.text) ?? 0,
      'reps_count': int.tryParse(_repsController.text) ?? 0,
      'rest_time': int.tryParse(_restTimeController.text) ?? 0,
      'with_weight': _withWeight,
      'weight': double.tryParse(_weightController.text) ?? 0.0,
      'exercise_reference_uuid': _selectedExerciseRef!['uuid'],
      'exercise_group_uuid': widget.exerciseGroupUuid,
    };
    final resp = await ApiService.post('/exercises/add/', body: body);
    if ((resp.statusCode == 201 || resp.statusCode == 200) &&
        resp.body.isNotEmpty) {
      // Получить uuid созданного упражнения
      final data = ApiService.decodeJson(resp.body);
      final exerciseUuid = data['uuid'] ?? data['exercise_uuid'];
      if (exerciseUuid != null) {
        await ApiService.post(
          '/exercise-groups/${widget.exerciseGroupUuid}/add-exercise',
          body: {'exercise_uuid': exerciseUuid},
        );
      }
      setState(() => isLoading = false);
      Navigator.pop(context, true);
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при создании упражнения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить упражнение в группу')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ExerciseReferenceSelector(
                onSelected: _onExerciseSelected,
                label: 'Выбрать упражнение',
                buildQueryParams: (search) => {
                  'caption': search,
                  'exercise_type': 'system',
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _captionController,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите название' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите описание' : null,
              ),
              TextFormField(
                controller: _difficultyController,
                decoration: const InputDecoration(
                  labelText: 'Сложность (число)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите сложность' : null,
              ),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'Порядок/сортировка',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите порядок' : null,
              ),
              TextFormField(
                controller: _muscleGroupController,
                decoration: const InputDecoration(labelText: 'Мышечная группа'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите мышечную группу' : null,
              ),
              TextFormField(
                controller: _setsController,
                decoration: const InputDecoration(labelText: 'Подходы'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? 'Введите количество подходов'
                    : null,
              ),
              TextFormField(
                controller: _repsController,
                decoration: const InputDecoration(labelText: 'Повторения'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? 'Введите количество повторений'
                    : null,
              ),
              TextFormField(
                controller: _restTimeController,
                decoration: const InputDecoration(labelText: 'Отдых (секунд)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите время отдыха' : null,
              ),
              SwitchListTile(
                value: _withWeight,
                onChanged: (v) => setState(() => _withWeight = v),
                title: const Text('С отягощением'),
              ),
              if (_withWeight)
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Вес'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Введите вес' : null,
                ),
              const SizedBox(height: 24),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Добавить'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
