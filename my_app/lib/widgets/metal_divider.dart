import 'package:flutter/material.dart';

/// Разделитель контента в металлическом стиле
/// Горизонтальная линия с осветляющим градиентом сверху
class MetalDivider extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const MetalDivider({super.key, this.height, this.margin});

  @override
  Widget build(BuildContext context) {
    final dividerHeight = height ?? 15.0;
    final dividerMargin =
        margin ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 0);

    return Container(
      margin: dividerMargin,
      width: double.infinity,
      height: dividerHeight,
      child: Stack(
        children: [
          // Тень
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
          // Основной контент с прозрачностью
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                // Плавный переход в прозрачный сверху, видимый снизу
                return LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFFFFFFF), // Полностью видимый снизу
                    const Color(0xCCFFFFFF), // Чуть прозрачнее
                    const Color(0x66FFFFFF), // Более прозрачный
                    const Color(0x00FFFFFF), // Полностью прозрачный сверху
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Stack(
                children: [
                  // Вертикальная светотень (темнее снизу)
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

                  // Горизонтальная светотень (тени слева/справа)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent, // слева
                              Colors.transparent, // центр
                              Colors.transparent, // справа
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Осветление снизу цветом #B2B2A7
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent, // Прозрачный сверху
                            Colors.transparent, // Прозрачный в центре
                            const Color(
                              0xFFB2B2A7,
                            ).withOpacity(0.2), // Еле заметное осветление снизу
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Радиальный градиент снизу из центра
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        gradient: RadialGradient(
                          center: Alignment.bottomCenter,
                          radius: 4,
                          colors: [
                            const Color(
                              0xFFB2B2A7,
                            ).withOpacity(0.5), // Видимый в центре снизу
                            Colors.transparent, // Прозрачный к краям
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Светлая грань снизу для эффекта выступа с плавным переходом по бокам
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 1.0,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        // Горизонтальный градиент для прозрачности по бокам
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0x00FFFFFF), // Прозрачный слева
                            const Color(0x00FFFFFF), // Прозрачный
                            const Color(0xFFFFFFFF), // Видимый в центре
                            const Color(0x00FFFFFF), // Прозрачный справа
                          ],
                          stops: const [0.0, 0.45, 0.55, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(
                                0xFFB2B2A7,
                              ).withOpacity(0.3), // Светлая грань
                              const Color(
                                0xFFB2B2A7,
                              ).withOpacity(0.6), // Плавный переход
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Дополнительное осветление снизу для объема
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 1.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFFB2B2A7).withOpacity(0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
