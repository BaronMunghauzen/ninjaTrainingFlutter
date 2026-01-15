import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ExerciseGroupListItem extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isActive;
  final VoidCallback onTap;
  final Future<ImageProvider?> Function(String? imageUuid) loadImage;
  final String? Function(Map<String, dynamic> group) getImageUuid;
  final bool isFirst;
  final bool isLast;

  const ExerciseGroupListItem({
    super.key,
    required this.group,
    required this.isActive,
    required this.onTap,
    required this.loadImage,
    required this.getImageUuid,
    this.isFirst = false,
    this.isLast = false,
  });

  BorderRadius _getBorderRadius() {
    // Если оба true - один элемент в списке, закругление со всех сторон
    if (isFirst && isLast) {
      return BorderRadius.circular(16);
    }
    // Первый элемент - закругление только сверху
    if (isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      );
    }
    // Последний элемент - закругление только снизу
    if (isLast) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );
    }
    // Средние элементы без закругления
    return BorderRadius.zero;
  }

  Border _getBorder() {
    final borderColor = Color(0xE6B5BF94).withOpacity(0.3);
    final width = 1.0;

    // Если один элемент - все границы
    if (isFirst && isLast) {
      return Border.all(color: borderColor, width: width);
    }
    // Первый элемент - все границы
    if (isFirst) {
      return Border.all(color: borderColor, width: width);
    }
    // Последний элемент - левая, правая и нижняя границы (верхняя уже есть у предыдущего элемента)
    if (isLast) {
      return Border(
        left: BorderSide(color: borderColor, width: width),
        right: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    }
    // Средние элементы - только левая, правая и нижняя границы (верхняя уже есть у предыдущего элемента)
    return Border(
      left: BorderSide(color: borderColor, width: width),
      right: BorderSide(color: borderColor, width: width),
      bottom: BorderSide(color: borderColor, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: _getBorderRadius(),
          border: _getBorder(),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? Colors.black.withOpacity(0.03)
                  : Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Фото группы упражнений
            Positioned.fill(
              child: FutureBuilder<ImageProvider?>(
                future: loadImage(getImageUuid(group)),
                builder: (context, snapshot) {
                  final image = snapshot.data;
                  final borderRadius = _getBorderRadius();
                  if (image != null) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: borderRadius,
                          child: Image(
                            image: image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Затемнение если тренировка неактивна
                        if (!isActive)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                      ],
                    );
                  } else {
                    // Заглушка если нет изображения
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: borderRadius,
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 48),
                      ),
                    );
                  }
                },
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group['caption'] ?? '',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[300],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
