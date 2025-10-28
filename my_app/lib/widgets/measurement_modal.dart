import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MeasurementModal extends StatefulWidget {
  final String title;
  final String? initialDate;
  final double? initialValue;
  final Function(String date, double value) onSave;

  const MeasurementModal({
    super.key,
    required this.title,
    this.initialDate,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<MeasurementModal> createState() => _MeasurementModalState();
}

class _MeasurementModalState extends State<MeasurementModal> {
  late TextEditingController _dateController;
  late TextEditingController _valueController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.initialDate ?? '');
    _valueController = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );

    if (widget.initialDate != null) {
      _selectedDate = DateTime.parse(widget.initialDate!);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _save() {
    final date = _dateController.text.trim();
    final valueText = _valueController.text.trim();

    if (date.isEmpty || valueText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    // Заменяем запятую на точку для корректного парсинга десятичных чисел
    final normalizedValueText = valueText.replaceAll(',', '.');
    final value = double.tryParse(normalizedValueText);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректное значение')),
      );
      return;
    }

    widget.onSave(date, value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: 'Дата',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(labelText: 'Значение'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class MeasurementListModal extends StatefulWidget {
  final List<dynamic> measurements;
  final String measurementTypeCaption;
  final Function(dynamic measurement) onEdit;
  final Function(String measurementUuid) onDelete;

  const MeasurementListModal({
    super.key,
    required this.measurements,
    required this.measurementTypeCaption,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<MeasurementListModal> createState() => _MeasurementListModalState();
}

class _MeasurementListModalState extends State<MeasurementListModal> {
  List<dynamic> _measurements = [];

  @override
  void initState() {
    super.initState();
    _measurements = List.from(widget.measurements);
  }

  @override
  void didUpdateWidget(MeasurementListModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.measurements != oldWidget.measurements) {
      setState(() {
        _measurements = List.from(widget.measurements);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Список измерений - ${widget.measurementTypeCaption}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _measurements.isEmpty
            ? const Center(child: Text('Нет данных для отображения'))
            : ListView.builder(
                itemCount: _measurements.length,
                itemBuilder: (context, index) {
                  final measurement = _measurements[index];
                  final date = DateTime.parse(measurement.measurementDate);

                  return ListTile(
                    title: Text('${measurement.value.toStringAsFixed(1)}'),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => widget.onEdit(measurement),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => widget.onDelete(measurement.uuid),
                        ),
                      ],
                    ),
                  );
                },
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
