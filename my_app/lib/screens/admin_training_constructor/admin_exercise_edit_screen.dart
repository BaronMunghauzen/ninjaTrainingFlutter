import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'widgets.dart';

class AdminExerciseEditScreen extends StatefulWidget {
  final String exerciseUuid;
  const AdminExerciseEditScreen({Key? key, required this.exerciseUuid})
    : super(key: key);

  @override
  State<AdminExerciseEditScreen> createState() =>
      _AdminExerciseEditScreenState();
}

class _AdminExerciseEditScreenState extends State<AdminExerciseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _exercise;
  Map<String, dynamic>? _exerciseReference;
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _orderController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _restTimeController = TextEditingController();
  bool _withWeight = false;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchExercise();
  }

  Future<void> _fetchExercise() async {
    setState(() => isLoading = true);
    final resp = await ApiService.get('/exercises/${widget.exerciseUuid}');
    if (resp.statusCode == 200) {
      final ex = ApiService.decodeJson(resp.body);
      setState(() {
        _exercise = ex;
        _captionController.text = ex['caption'] ?? '';
        _descriptionController.text = ex['description'] ?? '';
        _difficultyController.text = ex['difficulty_level']?.toString() ?? '';
        _orderController.text = ex['order']?.toString() ?? '';
        _muscleGroupController.text = ex['muscle_group'] ?? '';
        _setsController.text = ex['sets_count']?.toString() ?? '';
        _repsController.text = ex['reps_count']?.toString() ?? '';
        _restTimeController.text = ex['rest_time']?.toString() ?? '';
        _withWeight = ex['with_weight'] ?? false;
      });
      // Загрузить справочник упражнения
      if (ex['exercise_reference_uuid'] != null) {
        final refResp = await ApiService.get(
          '/exercise_reference/${ex['exercise_reference_uuid']}',
        );
        if (refResp.statusCode == 200) {
          setState(() {
            _exerciseReference = ApiService.decodeJson(refResp.body);
          });
        }
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    final body = {
      'caption': _captionController.text,
      'description': _descriptionController.text,
      'difficulty_level': int.tryParse(_difficultyController.text) ?? 1,
      'order': int.tryParse(_orderController.text) ?? 0,
      'muscle_group': _muscleGroupController.text,
      'sets_count': int.tryParse(_setsController.text) ?? 0,
      'reps_count': int.tryParse(_repsController.text) ?? 0,
      'rest_time': int.tryParse(_restTimeController.text) ?? 0,
      'with_weight': _withWeight,
    };
    final resp = await ApiService.put(
      '/exercises/update/${widget.exerciseUuid}',
      body: body,
    );
    setState(() => isSaving = false);
    if (resp.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении упражнения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать упражнение в группе')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    ExerciseReferenceSelector(
                      onSelected: (_) {},
                      label: 'Упражнение (справочник)',
                      initialCaption: _exerciseReference?['caption'],
                      initialValue: _exerciseReference,
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
                      decoration: const InputDecoration(
                        labelText: 'Мышечная группа',
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Введите мышечную группу'
                          : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Повторения',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Введите количество повторений'
                          : null,
                    ),
                    TextFormField(
                      controller: _restTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Отдых (секунд)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Введите время отдыха'
                          : null,
                    ),
                    SwitchListTile(
                      value: _withWeight,
                      onChanged: (v) => setState(() => _withWeight = v),
                      title: const Text('С отягощением'),
                    ),
                    const SizedBox(height: 24),
                    isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Сохранить'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
