import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/measurement_model.dart';

class MeasurementChart extends StatelessWidget {
  final List<MeasurementModel> measurements;
  final String measurementTypeCaption;
  final VoidCallback onAddMeasurement;
  final VoidCallback onViewList;
  final bool transparentBackground;

  const MeasurementChart({
    super.key,
    required this.measurements,
    required this.measurementTypeCaption,
    required this.onAddMeasurement,
    required this.onViewList,
    this.transparentBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final transparent = transparentBackground;
    return Container(
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: transparent
            ? Border.all(color: Colors.transparent, width: 0)
            : Border.all(
                color: AppColors.textSecondary.withOpacity(0.3),
                width: 1,
              ),
      ),
      child: Column(
        children: [
          // Заголовок с кнопками
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  measurementTypeCaption,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onViewList,
                      icon: Icon(Icons.list, color: AppColors.textPrimary),
                      tooltip: 'Список измерений',
                    ),
                    IconButton(
                      onPressed: onAddMeasurement,
                      icon: Icon(Icons.add, color: AppColors.textPrimary),
                      tooltip: 'Добавить измерение',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // График
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            child: measurements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Нет данных для отображения',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: SimpleLineChartPainter(measurements),
                  ),
          ),
        ],
      ),
    );
  }
}

class SimpleLineChartPainter extends CustomPainter {
  final List<MeasurementModel> measurements;

  SimpleLineChartPainter(this.measurements);

  @override
  void paint(Canvas canvas, Size size) {
    if (measurements.isEmpty) return;

    // Определяем диапазон дат
    final dates = measurements
        .map((m) => DateTime.parse(m.measurementDate))
        .toList();
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

    // Определяем диапазон значений
    final values = measurements.map((m) => m.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    // Добавляем небольшой отступ к значениям
    final valueRange = maxValue - minValue;
    final paddingValue = valueRange * 0.1;
    final adjustedMinValue = minValue - paddingValue;
    final adjustedMaxValue = maxValue + paddingValue;

    // Проверяем, есть ли диапазон значений
    final adjustedValueRange = adjustedMaxValue - adjustedMinValue;

    // Подготавливаем данные для графика
    final chartData = measurements.map((measurement) {
      final date = DateTime.parse(measurement.measurementDate);
      return {'date': date, 'value': measurement.value};
    }).toList();

    // Сортируем по дате
    chartData.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.3)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Рисуем сетку
    final gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = (size.height - 60) * i / gridLines + 30;
      canvas.drawLine(Offset(50, y), Offset(size.width - 20, y), gridPaint);
    }

    // Рисуем линию и точки
    bool isFirstPoint = true;
    double prevX = 0.0;
    double prevY = 0.0;
    for (final item in chartData) {
      final date = item['date'] as DateTime;
      final value = item['value'] as double;

      final daysDiff = date.difference(minDate).inDays.toDouble();
      final totalDays = maxDate.difference(minDate).inDays.toDouble();
      final x = totalDays > 0
          ? 50 + (size.width - 70) * daysDiff / totalDays
          : 50.0;

      // Исправляем ось Y - значения от меньшего к большему снизу вверх
      final y = adjustedValueRange > 0
          ? 30 +
                (size.height - 90) *
                    (adjustedMaxValue - value) /
                    adjustedValueRange
          : 30 +
                (size.height - 90) /
                    2; // Центрируем если все значения одинаковые

      if (isFirstPoint) {
        isFirstPoint = false;
      } else {
        // Рисуем линию к предыдущей точке
        canvas.drawLine(Offset(prevX, prevY), Offset(x, y), linePaint);
      }

      // Рисуем точку
      canvas.drawCircle(Offset(x, y), 4, pointPaint);

      // Рисуем подпись значения на точке
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(fontSize: 9, color: Colors.white),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 15));

      prevX = x;
      prevY = y;
    }

    // Рисуем подписи значений на оси Y (инвертированно)
    for (int i = 0; i <= gridLines; i++) {
      final value = adjustedValueRange > 0
          ? adjustedMaxValue - adjustedValueRange * i / gridLines
          : adjustedMinValue; // Если все значения одинаковые, показываем одно значение
      final y = (size.height - 60) * i / gridLines + 30;

      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // Рисуем подписи дат на оси X
    final step = (chartData.length / 5).ceil();
    for (int i = 0; i < chartData.length; i += step) {
      final item = chartData[i];
      final date = item['date'] as DateTime;

      final daysDiff = date.difference(minDate).inDays.toDouble();
      final totalDays = maxDate.difference(minDate).inDays.toDouble();
      final x = totalDays > 0
          ? 50 + (size.width - 70) * daysDiff / totalDays
          : 50.0;

      textPainter.text = TextSpan(
        text: '${date.day}/${date.month}',
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 25),
      );
    }
  }

  double prevX = 0;
  double prevY = 0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
