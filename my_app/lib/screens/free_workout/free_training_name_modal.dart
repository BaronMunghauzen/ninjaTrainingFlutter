import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class FreeTrainingNameModal extends StatefulWidget {
  const FreeTrainingNameModal({super.key});

  @override
  State<FreeTrainingNameModal> createState() => _FreeTrainingNameModalState();
}

class _FreeTrainingNameModalState extends State<FreeTrainingNameModal> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCreate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название тренировки')),
      );
      return;
    }
    Navigator.of(context).pop(name);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Новая тренировка',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Название тренировки',
          hintText: 'Например: Тренировка ног',
        ),
        style: const TextStyle(color: AppColors.textPrimary),
        maxLength: 50,
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _onCancel,
          child: const Text(
            'Отмена',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _onCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Создать'),
        ),
      ],
    );
  }
}
