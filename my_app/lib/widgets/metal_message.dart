import 'package:flutter/material.dart';

enum MetalMessageType { success, warning, error, info }

class MetalMessage extends StatelessWidget {
  final String message;
  final MetalMessageType type;
  final String? title;
  final String? description;
  final VoidCallback? onClose;

  const MetalMessage({
    super.key,
    required this.message,
    required this.type,
    this.title,
    this.description,
    this.onClose,
  });

  static void show({
    required BuildContext context,
    required String message,
    required MetalMessageType type,
    String? title,
    String? description,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;
    bool isRemoved = false;

    void removeOverlay() {
      if (!isRemoved) {
        try {
          overlayEntry?.remove();
          isRemoved = true;
        } catch (e) {
          // Overlay уже удален или не был добавлен
          isRemoved = true;
        }
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: MetalMessage(
              message: message,
              type: type,
              title: title,
              description: description,
              onClose: removeOverlay,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      removeOverlay();
    });
  }

  Color _getBottomColor() {
    switch (type) {
      case MetalMessageType.success:
        return Colors.green;
      case MetalMessageType.warning:
        return Colors.orange;
      case MetalMessageType.error:
        return Colors.red;
      case MetalMessageType.info:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case MetalMessageType.success:
        return Icons.check_circle;
      case MetalMessageType.warning:
        return Icons.warning;
      case MetalMessageType.error:
        return Icons.error;
      case MetalMessageType.info:
        return Icons.info;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case MetalMessageType.success:
        return Colors.green;
      case MetalMessageType.warning:
        return Colors.orange;
      case MetalMessageType.error:
        return Colors.red;
      case MetalMessageType.info:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomColor = _getBottomColor();

    return Stack(
      children: [
          // Фон в стиле MetalCardList (градиент + текстура + затемнение)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Базовый фон — ровный затемнённый слой
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF202020),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),

                  // Текстура графита поверх фона
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

                  // Светлое осветление сверху
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.15), // светлое осветление сверху
                              Colors.transparent, // прозрачный центр
                              Colors.transparent, // прозрачный центр
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Цветное осветление снизу (зеленый/оранжевый/красный)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              bottomColor.withOpacity(0.3), // цветное осветление снизу
                              bottomColor.withOpacity(0.5), // более интенсивное внизу
                            ],
                            stops: const [0.5, 0.85, 1.0],
                          ),
                        ),
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
                ],
              ),
            ),
          ),

          // Внешняя тень
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
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
                ),
              ),
            ),
          ),

          // Контент
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _getIcon(),
                              color: _getIconColor(),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _getIcon(),
                              color: _getIconColor(),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                  ],
                ),
                if (title != null && (description != null || message.isNotEmpty))
                  const SizedBox(height: 8),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: description != null
                        ? Text(
                            description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : Text(
                            message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ],
    );
  }
}

