import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminExerciseReferenceCreateScreen extends StatefulWidget {
  const AdminExerciseReferenceCreateScreen({Key? key}) : super(key: key);

  @override
  State<AdminExerciseReferenceCreateScreen> createState() =>
      _AdminExerciseReferenceCreateScreenState();
}

class _AdminExerciseReferenceCreateScreenState
    extends State<AdminExerciseReferenceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _techniqueDescriptionController = TextEditingController();
  final _auxiliaryMuscleGroupsController = TextEditingController();
  final _equipmentNameController = TextEditingController();
  bool isLoading = false;
  bool _hasEquipment = false;

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _muscleGroupController.dispose();
    _techniqueDescriptionController.dispose();
    _auxiliaryMuscleGroupsController.dispose();
    _equipmentNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final body = {
      'exercise_type': 'system',
      'caption': _captionController.text,
      'description': _descriptionController.text,
      'muscle_group': _muscleGroupController.text,
      'technique_description': _techniqueDescriptionController.text.isEmpty
          ? null
          : _techniqueDescriptionController.text,
      'auxiliary_muscle_groups': _auxiliaryMuscleGroupsController.text.isEmpty
          ? null
          : _auxiliaryMuscleGroupsController.text,
      'equipment_name': _hasEquipment
          ? _equipmentNameController.text
          : 'Без оборудования',
    };
    final response = await ApiService.post(
      '/exercise_reference/add/',
      body: body,
    );
    setState(() => isLoading = false);
    if (response.statusCode == 201 || response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при создании упражнения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создать упражнение')),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _auxiliaryMuscleGroupsController,
                decoration: const InputDecoration(
                  labelText: 'Вспомогательные группы мышц (необязательно)',
                ),
              ),
              const SizedBox(height: 16),
              // Оборудование
              Row(
                children: [
                  const Text('Используется оборудование:'),
                  const SizedBox(width: 16),
                  Switch(
                    value: _hasEquipment,
                    onChanged: (value) {
                      setState(() {
                        _hasEquipment = value;
                        if (!value) {
                          _equipmentNameController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_hasEquipment) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _equipmentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Название оборудования',
                  ),
                  validator: (v) => _hasEquipment && (v == null || v.isEmpty)
                      ? 'Введите название оборудования'
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Создать'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
