import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminTrainingEditScreen extends StatefulWidget {
  final Map<String, dynamic> training;
  const AdminTrainingEditScreen({Key? key, required this.training})
    : super(key: key);

  @override
  State<AdminTrainingEditScreen> createState() =>
      _AdminTrainingEditScreenState();
}

class _AdminTrainingEditScreenState extends State<AdminTrainingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _captionController;
  late TextEditingController _descriptionController;
  late TextEditingController _difficultyController;
  late TextEditingController _durationController;
  late TextEditingController _orderController;
  late TextEditingController _muscleGroupController;
  bool isLoading = false;
  bool _actual = false;

  @override
  void initState() {
    super.initState();
    final t = widget.training;
    _captionController = TextEditingController(text: t['caption'] ?? '');
    _descriptionController = TextEditingController(
      text: t['description'] ?? '',
    );
    _difficultyController = TextEditingController(
      text: t['difficulty_level']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: t['duration']?.toString() ?? '',
    );
    _orderController = TextEditingController(
      text: t['order']?.toString() ?? '',
    );
    _muscleGroupController = TextEditingController(
      text: t['muscle_group'] ?? '',
    );
    _actual = t['actual'] ?? false;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _difficultyController.dispose();
    _durationController.dispose();
    _orderController.dispose();
    _muscleGroupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final body = {
      'caption': _captionController.text,
      'description': _descriptionController.text,
      'difficulty_level': int.tryParse(_difficultyController.text) ?? 1,
      'duration': int.tryParse(_durationController.text) ?? 1,
      'order': int.tryParse(_orderController.text) ?? 0,
      'muscle_group': _muscleGroupController.text,
      'actual': _actual,
    };
    final response = await ApiService.put(
      '/trainings/update/${widget.training['uuid']}',
      body: body,
    );
    setState(() => isLoading = false);
    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении тренировки')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать тренировку')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Продолжительность (мин)',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите продолжительность' : null,
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
              SwitchListTile(
                value: _actual,
                onChanged: (v) => setState(() => _actual = v),
                title: const Text('Актуальная'),
              ),
              const SizedBox(height: 24),
              isLoading
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
