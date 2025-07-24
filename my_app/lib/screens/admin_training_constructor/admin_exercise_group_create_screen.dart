import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminExerciseGroupCreateScreen extends StatefulWidget {
  final String trainingUuid;
  const AdminExerciseGroupCreateScreen({Key? key, required this.trainingUuid})
    : super(key: key);

  @override
  State<AdminExerciseGroupCreateScreen> createState() =>
      _AdminExerciseGroupCreateScreenState();
}

class _AdminExerciseGroupCreateScreenState
    extends State<AdminExerciseGroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final body = {
      'training_uuid': widget.trainingUuid,
      'caption': _captionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'order': int.tryParse(_orderController.text.trim()) ?? 0,
    };
    final response = await ApiService.post('/exercise-groups/add/', body: body);
    setState(() => isLoading = false);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания группы: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать группу упражнений')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Название'),
                controller: _captionController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Описание'),
                controller: _descriptionController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите описание' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Порядок/сортировка (от 0)',
                ),
                controller: _orderController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Введите порядок' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Создать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
