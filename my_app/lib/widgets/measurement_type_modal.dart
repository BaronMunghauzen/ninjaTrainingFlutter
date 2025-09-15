import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MeasurementTypeModal extends StatefulWidget {
  final List<dynamic> measurementTypes;
  final Function(String caption) onAdd;
  final Function(String uuid, String caption) onEdit;
  final Function(String uuid) onDelete;

  const MeasurementTypeModal({
    super.key,
    required this.measurementTypes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<MeasurementTypeModal> createState() => _MeasurementTypeModalState();
}

class _MeasurementTypeModalState extends State<MeasurementTypeModal> {
  final TextEditingController _captionController = TextEditingController();
  List<dynamic> _measurementTypes = [];

  @override
  void initState() {
    super.initState();
    _measurementTypes = List.from(widget.measurementTypes);
  }

  @override
  void didUpdateWidget(MeasurementTypeModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.measurementTypes != oldWidget.measurementTypes) {
      setState(() {
        _measurementTypes = List.from(widget.measurementTypes);
      });
    }
  }

  void _showAddDialog() {
    _captionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить тип измерения'),
        content: TextField(
          controller: _captionController,
          decoration: const InputDecoration(
            labelText: 'Название типа измерения',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final caption = _captionController.text.trim();
              if (caption.isNotEmpty) {
                await widget.onAdd(caption);
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(dynamic measurementType) {
    _captionController.text = measurementType.caption;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать тип измерения'),
        content: TextField(
          controller: _captionController,
          decoration: const InputDecoration(
            labelText: 'Название типа измерения',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final caption = _captionController.text.trim();
              if (caption.isNotEmpty) {
                await widget.onEdit(measurementType.uuid, caption);
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic measurementType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы уверены, что хотите удалить "${measurementType.caption}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.onDelete(measurementType.uuid);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Типы измерений'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Кнопка добавления
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить тип измерения'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Список типов измерений
            Expanded(
              child: _measurementTypes.isEmpty
                  ? const Center(child: Text('Нет типов измерений'))
                  : ListView.builder(
                      itemCount: _measurementTypes.length,
                      itemBuilder: (context, index) {
                        final measurementType = _measurementTypes[index];
                        return ListTile(
                          title: Text(measurementType.caption),
                          subtitle: Text(
                            measurementType.dataType == 'system'
                                ? 'Системный тип'
                                : 'Пользовательский тип',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (measurementType.dataType == 'custom') ...[
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showEditDialog(measurementType),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _confirmDelete(measurementType),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
