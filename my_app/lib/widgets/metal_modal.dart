import 'package:flutter/material.dart';
import '../design/ninja_colors.dart';
import '../design/ninja_typography.dart';
import '../design/ninja_spacing.dart';

class MetalModal extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onClose;

  const MetalModal({
    super.key,
    required this.title,
    required this.children,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    VoidCallback? onClose,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => MetalModal(
        title: title,
        children: children,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: NinjaSpacing.lg,
        vertical: NinjaSpacing.xl,
      ),
      child: Stack(
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

                  // Дополнительное затемнение посередине по горизонтали
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.18), // небольшое затемнение слева
                              Colors.black.withOpacity(0.60), // центр затемнён
                              Colors.black.withOpacity(0.18), // небольшое затемнение справа
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
            padding: const EdgeInsets.all(NinjaSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Заголовок и кнопка закрытия
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: NinjaText.title,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            if (onClose != null) {
                              onClose!();
                            }
                            Navigator.of(context).pop();
                          },
                          color: NinjaColors.textSecondary,
                          iconSize: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: NinjaSpacing.md),
                    // Дочерние виджеты
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

