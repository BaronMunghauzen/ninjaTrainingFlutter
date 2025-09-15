import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminExerciseReferenceEditScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const AdminExerciseReferenceEditScreen({Key? key, required this.exercise})
    : super(key: key);

  @override
  State<AdminExerciseReferenceEditScreen> createState() =>
      _AdminExerciseReferenceEditScreenState();
}

class _AdminExerciseReferenceEditScreenState
    extends State<AdminExerciseReferenceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _captionController;
  late TextEditingController _descriptionController;
  late TextEditingController _muscleGroupController;
  late TextEditingController _techniqueDescriptionController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _captionController = TextEditingController(text: e['caption'] ?? '');
    _descriptionController = TextEditingController(
      text: e['description'] ?? '',
    );
    _muscleGroupController = TextEditingController(
      text: e['muscle_group'] ?? '',
    );
    _techniqueDescriptionController = TextEditingController(
      text: e['technique_description'] ?? '',
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    _techniqueDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final body = {
      'caption': _captionController.text,
      'description': _descriptionController.text,
      'muscle_group': _muscleGroupController.text,
      'technique_description': _techniqueDescriptionController.text.isEmpty
          ? null
          : _techniqueDescriptionController.text,
    };
    final response = await ApiService.put(
      '/exercise_reference/update/${widget.exercise['uuid']}',
      body: body,
    );
    setState(() => isLoading = false);
    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении упражнения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать упражнение')),
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
                controller: _muscleGroupController,
                decoration: const InputDecoration(labelText: 'Мышечная группа'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите мышечную группу' : null,
              ),
              TextFormField(
                controller: _techniqueDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Техника выполнения (необязательно)',
                ),
                maxLines: 3,
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
