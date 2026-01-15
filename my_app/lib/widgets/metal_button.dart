import 'package:flutter/material.dart';

enum MetalButtonState { idle, pressed, disabled }

enum MetalButtonPosition { single, first, middle, last }

class MetalButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double? height;
  final bool isLoading;
  final double? fontSize;
  final MetalButtonPosition position;
  final bool isSelected;
  final Color? topColor;
  final bool forceOpaqueText;

  const MetalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height,
    this.isLoading = false,
    this.fontSize,
    this.position = MetalButtonPosition.single,
    this.isSelected = false,
    this.topColor,
    this.forceOpaqueText = false,
  });

  @override
  State<MetalButton> createState() => _MetalButtonState();
}

class _MetalButtonState extends State<MetalButton> {
  bool _pressed = false;

  MetalButtonState get state {
    if (widget.onPressed == null || widget.isLoading) {
      return MetalButtonState.disabled;
    }
    if (widget.isSelected || _pressed) {
      return MetalButtonState.pressed;
    }
    return MetalButtonState.idle;
  }

  BorderRadius _getBorderRadius() {
    const radius = 16.0;
    switch (widget.position) {
      case MetalButtonPosition.single:
        return BorderRadius.circular(radius);
      case MetalButtonPosition.first:
        return const BorderRadius.only(
          topLeft: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
        );
      case MetalButtonPosition.middle:
        return BorderRadius.zero;
      case MetalButtonPosition.last:
        return const BorderRadius.only(
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? 56.0;
    final s = state;

    return GestureDetector(
      onTapDown: s == MetalButtonState.idle
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: (_) {
        // Не сбрасываем здесь, пусть onTap это сделает
      },
      onTapCancel: () {
        if (_pressed) {
          setState(() => _pressed = false);
        }
      },
      onTap: s != MetalButtonState.disabled
          ? () {
              // Вызываем callback сразу
              widget.onPressed?.call();
              // Сбрасываем состояние с задержкой, чтобы анимация успела проиграться
              Future.delayed(const Duration(milliseconds: 120), () {
                if (mounted) {
                  setState(() => _pressed = false);
                }
              });
            }
          : null,
      child: AnimatedScale(
        scale: s == MetalButtonState.pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: buttonHeight,
          decoration: _decorationFor(s),
          child: Stack(
            children: [
              // Основной градиент (первый слой)
                Positioned.fill(
                  child: ClipRRect(
                  borderRadius: _getBorderRadius(),
                    child: Container(
                      decoration: BoxDecoration(
                      borderRadius: _getBorderRadius(),
                      gradient: _gradientFor(s),
                      ),
                    ),
                  ),
                ),

              // Micro texture layer — аккуратная графитовая текстура поверх градиента
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: _getBorderRadius(),
                    child: Image.asset(
                      'assets/textures/graphite_noise.png',
                      fit: BoxFit.cover,
                      // Лёгкая текстура, чтобы не «убивать» градиент
                      color: Colors.white.withOpacity(_textureOpacityFor(s)),
                      colorBlendMode: BlendMode.softLight,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),

              // Легкое свечение сверху по центру кнопки (цвет #C5D09D)
              if (s == MetalButtonState.idle)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: _getBorderRadius(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            // Чуть шире зона свечения
                            radius: 1.7,
                            colors: [
                              (widget.topColor ?? const Color(0xFFC5D09D))
                                  .withOpacity(0.32), // Более яркое свечение
                              (widget.topColor ?? const Color(0xFFC5D09D))
                                  .withOpacity(0.0),
                            ],
                            // Свет занимает большую часть верхней половины
                            stops: const [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Градиентная обводка сверху (цвет #C5D09D на краю, с более широкой зоной света)
              if (s == MetalButtonState.idle)
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
                              (widget.topColor ?? const Color(0xFFC5D09D))
                                  .withOpacity(0.5), // мягкие края света
                              widget.topColor ?? const Color(0xFFC5D09D), // пик в центре
                              (widget.topColor ?? const Color(0xFFC5D09D))
                                  .withOpacity(0.5),
                              Colors.transparent,
                            ],
                            // Шире распределяем свет вдоль верхнего края
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Дополнительное затемнение снизу — явная тень в нижней части кнопки
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
                            Colors.black.withOpacity(0.7), // Усилено затемнение
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Inner highlight (верхний свет) - только для idle
              if (s == MetalButtonState.idle)
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

              // Inner shadow (нижняя тень) - для idle и pressed
              if (s == MetalButtonState.idle || s == MetalButtonState.pressed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: _getBorderRadius(),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: _getBorderRadius(),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                s == MetalButtonState.pressed ? 0.6 : 0.3,
                              ),
                              offset: const Offset(0, 2),
                              blurRadius: s == MetalButtonState.pressed ? 6 : 5,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Content
              Center(
                child: Transform.translate(
                  offset: s == MetalButtonState.pressed
                      ? const Offset(0, 1)
                      : Offset.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (widget.label.isEmpty && widget.icon != null)
                          ? (widget.height != null && widget.height! <= 40) ? 6.0 : 8.0
                          : 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD0D0D0),
                              ),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: (widget.label.isEmpty && widget.height != null && widget.height! <= 40)
                                ? 18.0
                                : 20.0,
                            color: _iconColorFor(s),
                          ),
                        ],
                        if ((widget.icon != null || widget.isLoading) &&
                            widget.label.isNotEmpty)
                          const SizedBox(width: 10),
                        if (widget.label.isNotEmpty)
                          Flexible(
                            child: Text(
                          widget.label,
                          style: TextStyle(
                            color: _textColorFor(s),
                                fontSize: widget.fontSize ?? 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decorationFor(MetalButtonState s) {
    return BoxDecoration(
      borderRadius: _getBorderRadius(),
      // Убрали color, чтобы градиент из Stack был виден
      border: _getBorderFor(s),
      boxShadow: _outerShadowsFor(s),
    );
  }

  Border _getBorderFor(MetalButtonState s) {
    final borderColor = Colors.white.withOpacity(0.15);
    final width = 1.0;

    switch (widget.position) {
      case MetalButtonPosition.single:
        // Одна кнопка - обводка со всех сторон
        return Border.all(color: borderColor, width: width);
      case MetalButtonPosition.first:
        // Первая кнопка - обводка слева, сверху, снизу (без правой)
        return Border(
          left: BorderSide(color: borderColor, width: width),
          top: BorderSide(color: borderColor, width: width),
          bottom: BorderSide(color: borderColor, width: width),
        );
      case MetalButtonPosition.middle:
        // Средняя кнопка - обводка только сверху и снизу (без левой и правой)
        return Border(
          top: BorderSide(color: borderColor, width: width),
          bottom: BorderSide(color: borderColor, width: width),
        );
      case MetalButtonPosition.last:
        // Последняя кнопка - обводка справа, сверху, снизу (без левой)
        return Border(
          right: BorderSide(color: borderColor, width: width),
          top: BorderSide(color: borderColor, width: width),
          bottom: BorderSide(color: borderColor, width: width),
        );
    }
  }

  LinearGradient _gradientFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.pressed:
        // Инвертированный градиент (свет снизу при нажатии)
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF3E3E3E)],
        );

      case MetalButtonState.disabled:
        // Плоский градиент
        return const LinearGradient(
          colors: [Color(0xFF2B2B2B), Color(0xFF2B2B2B)],
        );

      case MetalButtonState.idle:
        // Нормальный металлический градиент: светлее сверху, темнее снизу
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
    }
  }

  List<BoxShadow> _outerShadowsFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.pressed:
        // Внешняя тень исчезает
        return [];

      case MetalButtonState.disabled:
        // Без теней
        return [];

      case MetalButtonState.idle:
        // Внешняя тень для объёма
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ];
    }
  }

  double _textureOpacityFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.pressed:
        return 0.10;
      case MetalButtonState.disabled:
        return 0.04;
      case MetalButtonState.idle:
        return 0.05; // Уменьшено, чтобы градиент был заметнее
    }
  }

  Color _textColorFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.disabled:
        return widget.forceOpaqueText
            ? const Color(0xFFEDEDED)
            : const Color(0xFFEDEDED).withOpacity(0.4);
      case MetalButtonState.idle:
      case MetalButtonState.pressed:
        return const Color(0xFFEDEDED);
    }
  }

  Color _iconColorFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.disabled:
        return const Color(0xFFD0D0D0).withOpacity(0.4);
      case MetalButtonState.idle:
      case MetalButtonState.pressed:
        return const Color(0xFFD0D0D0);
    }
  }
}
