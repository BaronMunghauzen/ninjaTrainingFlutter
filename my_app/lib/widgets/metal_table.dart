import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MetalTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<List<Widget>>? widgetRows;
  final double? cellHeight;
  final double? fontSize;
  final double? cellWidth;
  final bool? isScrollable;

  const MetalTable({
    super.key,
    required this.headers,
    this.rows = const [],
    this.widgetRows,
    this.cellHeight,
    this.fontSize,
    this.cellWidth,
    this.isScrollable,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = rows.isNotEmpty || (widgetRows != null && widgetRows!.isNotEmpty);
    
    if (!hasData) {
      return Container(
        height: 100,
        child: const Center(
          child: Text(
            'Нет данных для отображения',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final dataRows = widgetRows ?? rows.map((row) => row.map((cell) => Text(cell)).toList()).toList();
    final isLastRowIndex = (widgetRows ?? rows).length - 1;
    
    // Определяем, нужно ли использовать фиксированную ширину ячеек
    final shouldUseFixedWidth = isScrollable == true;
    final defaultCellWidth = shouldUseFixedWidth ? (cellWidth ?? 120.0) : null;

    Widget tableContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовки (стиль активной кнопки)
        Row(
          children: List.generate(
            headers.length,
            (index) => defaultCellWidth != null
                ? SizedBox(
                    width: defaultCellWidth,
                    child: _MetalTableCell(
                      text: headers[index],
                      isHeader: true,
                      isFirst: index == 0,
                      isLast: index == headers.length - 1,
                      isFirstRow: true,
                      isLastRow: dataRows.isEmpty,
                      height: cellHeight ?? 50,
                      fontSize: fontSize ?? 14,
                    ),
                  )
                : Expanded(
                    child: _MetalTableCell(
                      text: headers[index],
                      isHeader: true,
                      isFirst: index == 0,
                      isLast: index == headers.length - 1,
                      isFirstRow: true,
                      isLastRow: dataRows.isEmpty,
                      height: cellHeight ?? 50,
                      fontSize: fontSize ?? 14,
                    ),
                  ),
          ),
        ),
        // Строки данных (стиль неактивной кнопки)
        ...(widgetRows != null
            ? widgetRows!.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                final isLastRow = rowIndex == isLastRowIndex;
                return Row(
                  children: List.generate(
                    row.length,
                    (index) => defaultCellWidth != null
                        ? SizedBox(
                            width: defaultCellWidth,
                            child: _MetalTableCellWidget(
                              child: row[index],
                              isHeader: false,
                              isFirst: index == 0,
                              isLast: index == row.length - 1,
                              isFirstRow: false,
                              isLastRow: isLastRow,
                              height: cellHeight ?? 50,
                            ),
                          )
                        : Expanded(
                            child: _MetalTableCellWidget(
                              child: row[index],
                              isHeader: false,
                              isFirst: index == 0,
                              isLast: index == row.length - 1,
                              isFirstRow: false,
                              isLastRow: isLastRow,
                              height: cellHeight ?? 50,
                            ),
                          ),
                  ),
                );
              })
            : rows.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                final isLastRow = rowIndex == rows.length - 1;
                return Row(
                  children: List.generate(
                    row.length,
                    (index) => defaultCellWidth != null
                        ? SizedBox(
                            width: defaultCellWidth,
                            child: _MetalTableCell(
                              text: row[index],
                              isHeader: false,
                              isFirst: index == 0,
                              isLast: index == row.length - 1,
                              isFirstRow: false,
                              isLastRow: isLastRow,
                              height: cellHeight ?? 50,
                              fontSize: fontSize ?? 14,
                            ),
                          )
                        : Expanded(
                            child: _MetalTableCell(
                              text: row[index],
                              isHeader: false,
                              isFirst: index == 0,
                              isLast: index == row.length - 1,
                              isFirstRow: false,
                              isLastRow: isLastRow,
                              height: cellHeight ?? 50,
                              fontSize: fontSize ?? 14,
                            ),
                          ),
                  ),
                );
              })),
      ],
    );

    // Если таблица скроллируемая, добавляем горизонтальную прокрутку
    if (shouldUseFixedWidth) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: tableContent,
        ),
      );
    } else {
      // Если таблица не скроллируемая, она занимает всю ширину, только вертикальная прокрутка
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: tableContent,
      );
    }
  }
}

class _MetalTableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isFirst;
  final bool isLast;
  final bool isFirstRow;
  final bool isLastRow;
  final double height;
  final double fontSize;

  const _MetalTableCell({
    required this.text,
    required this.isHeader,
    required this.isFirst,
    required this.isLast,
    required this.isFirstRow,
    required this.isLastRow,
    required this.height,
    required this.fontSize,
  });

  BorderRadius _getBorderRadius() {
    const radius = 16.0;
    
    // Верхний левый угол
    if (isFirst && isFirstRow) {
      if (isLast && isLastRow) {
        // Единственная ячейка
        return BorderRadius.circular(radius);
      }
      // Первая ячейка первой строки
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
      );
    }
    
    // Верхний правый угол
    if (isLast && isFirstRow) {
      return const BorderRadius.only(
        topRight: Radius.circular(radius),
      );
    }
    
    // Нижний левый угол
    if (isFirst && isLastRow) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(radius),
      );
    }
    
    // Нижний правый угол
    if (isLast && isLastRow) {
      return const BorderRadius.only(
        bottomRight: Radius.circular(radius),
      );
    }
    
    // Без закругления
    return BorderRadius.zero;
  }

  Border _getBorder() {
    final borderColor = Colors.white.withOpacity(0.15);
    final width = 1.0;

    if (isFirst && isLast) {
      return Border.all(color: borderColor, width: width);
    } else if (isFirst) {
      return Border(
        left: BorderSide(color: borderColor, width: width),
        top: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    } else if (isLast) {
      return Border(
        right: BorderSide(color: borderColor, width: width),
        top: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    } else {
      return Border(
        top: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    }
  }

  LinearGradient _getGradient() {
    if (isHeader) {
      // Активная кнопка (idle state)
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5E5E5E), // светлый верх
          Color(0xFF3E3E3E),
          Color(0xFF272727),
          Color(0xFF161616), // тёмный низ
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      );
    } else {
      // Неактивная кнопка (disabled state)
      return const LinearGradient(
        colors: [Color(0xFF2B2B2B), Color(0xFF2B2B2B)],
      );
    }
  }

  Color _getTextColor() {
    // Убираем прозрачность для всех ячеек
    return const Color(0xFFEDEDED);
  }

  double _getTextureOpacity() {
    if (isHeader) {
      return 0.05;
    } else {
      return 0.04;
    }
  }

  List<BoxShadow> _getShadows() {
    if (isHeader) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          offset: const Offset(0, 6),
          blurRadius: 14,
        ),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: _getBorderRadius(),
        border: _getBorder(),
        boxShadow: _getShadows(),
      ),
      child: Stack(
        children: [
          // Основной градиент
          Positioned.fill(
            child: ClipRRect(
              borderRadius: _getBorderRadius(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: _getBorderRadius(),
                  gradient: _getGradient(),
                ),
              ),
            ),
          ),

          // Текстура
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: _getBorderRadius(),
                child: Image.asset(
                  'assets/textures/graphite_noise.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(_getTextureOpacity()),
                  colorBlendMode: BlendMode.softLight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // Свечение сверху для заголовков
          if (isHeader)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.7,
                        colors: [
                          const Color(0xFFC5D09D).withOpacity(0.32),
                          const Color(0xFFC5D09D).withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Градиентная обводка сверху для заголовков
          if (isHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: _getBorderRadius().topLeft,
                    topRight: _getBorderRadius().topRight,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC5D09D).withOpacity(0.5),
                          const Color(0xFFC5D09D),
                          const Color(0xFFC5D09D).withOpacity(0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Затемнение снизу
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: _getBorderRadius(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Inner highlight для заголовков
          if (isHeader)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          offset: const Offset(0, -1),
                          blurRadius: 2,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Inner shadow для заголовков
          if (isHeader)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Текст
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                text,
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: fontSize,
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalTableCellWidget extends StatelessWidget {
  final Widget child;
  final bool isHeader;
  final bool isFirst;
  final bool isLast;
  final bool isFirstRow;
  final bool isLastRow;
  final double height;

  const _MetalTableCellWidget({
    required this.child,
    required this.isHeader,
    required this.isFirst,
    required this.isLast,
    required this.isFirstRow,
    required this.isLastRow,
    required this.height,
  });

  BorderRadius _getBorderRadius() {
    const radius = 16.0;
    
    // Верхний левый угол
    if (isFirst && isFirstRow) {
      if (isLast && isLastRow) {
        // Единственная ячейка
        return BorderRadius.circular(radius);
      }
      // Первая ячейка первой строки
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
      );
    }
    
    // Верхний правый угол
    if (isLast && isFirstRow) {
      return const BorderRadius.only(
        topRight: Radius.circular(radius),
      );
    }
    
    // Нижний левый угол
    if (isFirst && isLastRow) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(radius),
      );
    }
    
    // Нижний правый угол
    if (isLast && isLastRow) {
      return const BorderRadius.only(
        bottomRight: Radius.circular(radius),
      );
    }
    
    // Без закругления
    return BorderRadius.zero;
  }

  Border _getBorder() {
    final borderColor = Colors.white.withOpacity(0.15);
    final width = 1.0;

    if (isFirst && isLast) {
      return Border.all(color: borderColor, width: width);
    } else if (isFirst) {
      return Border(
        left: BorderSide(color: borderColor, width: width),
        top: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    } else if (isLast) {
      return Border(
        right: BorderSide(color: borderColor, width: width),
        top: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    } else {
      return Border(
        top: BorderSide(color: borderColor, width: width),
        bottom: BorderSide(color: borderColor, width: width),
      );
    }
  }

  LinearGradient _getGradient() {
    if (isHeader) {
      // Активная кнопка (idle state)
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5E5E5E), // светлый верх
          Color(0xFF3E3E3E),
          Color(0xFF272727),
          Color(0xFF161616), // тёмный низ
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      );
    } else {
      // Неактивная кнопка (disabled state)
      return const LinearGradient(
        colors: [Color(0xFF2B2B2B), Color(0xFF2B2B2B)],
      );
    }
  }

  double _getTextureOpacity() {
    if (isHeader) {
      return 0.05;
    } else {
      return 0.04;
    }
  }

  List<BoxShadow> _getShadows() {
    if (isHeader) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          offset: const Offset(0, 6),
          blurRadius: 14,
        ),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: _getBorderRadius(),
        border: _getBorder(),
        boxShadow: _getShadows(),
      ),
      child: Stack(
        children: [
          // Основной градиент
          Positioned.fill(
            child: ClipRRect(
              borderRadius: _getBorderRadius(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: _getBorderRadius(),
                  gradient: _getGradient(),
                ),
              ),
            ),
          ),

          // Текстура
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: _getBorderRadius(),
                child: Image.asset(
                  'assets/textures/graphite_noise.png',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(_getTextureOpacity()),
                  colorBlendMode: BlendMode.softLight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // Свечение сверху для заголовков
          if (isHeader)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.7,
                        colors: [
                          const Color(0xFFC5D09D).withOpacity(0.32),
                          const Color(0xFFC5D09D).withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Градиентная обводка сверху для заголовков
          if (isHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: _getBorderRadius().topLeft,
                    topRight: _getBorderRadius().topRight,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC5D09D).withOpacity(0.5),
                          const Color(0xFFC5D09D),
                          const Color(0xFFC5D09D).withOpacity(0.5),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Затемнение снизу
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: _getBorderRadius(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Inner highlight для заголовков
          if (isHeader)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.08),
                          offset: const Offset(0, -1),
                          blurRadius: 2,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Inner shadow для заголовков
          if (isHeader)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: _getBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Виджет
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

