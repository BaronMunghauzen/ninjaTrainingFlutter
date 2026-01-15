import 'package:flutter/material.dart';

class MetalListItem extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool removeSpacing;

  const MetalListItem({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
    this.removeSpacing = false,
  });

  @override
  State<MetalListItem> createState() => _MetalListItemState();
}

class _MetalListItemState extends State<MetalListItem> {
  bool _pressed = false;

  void _handleTap() async {
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _pressed = false);
      widget.onTap();
    }
  }

  BorderRadius _getBorderRadius() {
    // Если оба true - один элемент в списке, закругление со всех сторон
    if (widget.isFirst && widget.isLast) {
      return BorderRadius.circular(16);
    }
    // Первый элемент - закругление только сверху
    if (widget.isFirst) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      );
    }
    // Последний элемент - закругление только снизу
    if (widget.isLast) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );
    }
    // Если removeSpacing = true, это список, и средние элементы без закругления
    if (widget.removeSpacing) {
      return BorderRadius.zero;
    }
    // Если оба false и removeSpacing = false, это одиночный элемент, закругление со всех сторон
    return BorderRadius.circular(16);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        margin: widget.removeSpacing
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: _decoration(),
        child: Stack(
          children: [
            // Фон в стиле MetalCard (градиент + текстура + усиленное затемнение)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: _getBorderRadius(),
                child: Stack(
                  children: [
                    // Базовый фон — ровный затемнённый слой без градиента
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _pressed
                              ? const Color(0xFF1C1C1C)
                              : const Color(0xFF202020),
                        ),
                      ),
                    ),

                    // Текстура графита поверх градиента
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Image.asset(
                          'assets/textures/graphite_noise.png',
                          fit: BoxFit.cover,
                          color: Colors.white.withOpacity(0.05),
                          colorBlendMode: BlendMode.softLight,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),

                    // Усиленная вертикальная светотень (темнее снизу)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.16), // верхняя грань
                                Colors.transparent, // центр
                                Colors.black.withOpacity(0.32), // низ темнее
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Усиленная горизонтальная светотень (тени слева/справа)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.55), // слева
                                Colors.transparent, // центр
                                Colors.black.withOpacity(0.60), // справа
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Дополнительное затемнение посередине по горизонтали (для выравнивания с картинкой)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(
                                  0.18,
                                ), // небольшое затемнение слева
                                Colors.black.withOpacity(
                                  0.60,
                                ), // центр затемнён
                                Colors.black.withOpacity(
                                  0.18,
                                ), // небольшое затемнение справа
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Контент списка поверх фона
            Transform.translate(
              offset: _pressed ? const Offset(0, 1) : Offset.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    widget.leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.title,
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            widget.subtitle!,
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 12),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      borderRadius: _getBorderRadius(),
      // Внешний слой тоже без градиента — ровный тёмный фон
      color: _pressed ? const Color(0xFF1F1F1F) : const Color(0xFF222222),
      boxShadow: _pressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                offset: const Offset(0, 6),
                blurRadius: 14,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                offset: const Offset(0, -1),
                blurRadius: 1,
              ),
            ],
    );
  }
}
