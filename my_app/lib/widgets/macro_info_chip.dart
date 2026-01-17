import 'package:flutter/material.dart';

class MacroInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final double size;

  const MacroInfoChip({
    super.key,
    required this.label,
    required this.value,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = size * 0.28;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.0),
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
      child: Stack(
        children: [
          // Основной градиент (как в metal_button)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF5E5E5E), // светлый верх
                      Color(0xFF3E3E3E),
                      Color(0xFF272727),
                      Color(0xFF161616), // тёмный низ
                    ],
                    stops: [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Текстура графита
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
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
          ),

          // Легкое свечение сверху по центру (цвет #C5D09D) - уменьшенная интенсивность
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        const Color(
                          0xFFC5D09D,
                        ).withOpacity(0.18), // Уменьшено с 0.32
                        const Color(0xFFC5D09D).withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Градиентная обводка сверху (цвет #C5D09D) - уменьшенная интенсивность
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 2,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        const Color(
                          0xFFC5D09D,
                        ).withOpacity(0.50), // Уменьшено с 0x80 (~0.5)
                        const Color(
                          0xFFC5D09D,
                        ).withOpacity(0.70), // Уменьшено с 1.0
                        const Color(
                          0xFFC5D09D,
                        ).withOpacity(0.50), // Уменьшено с 0x80 (~0.5)
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.40, 0.5, 0.60, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Дополнительное затемнение снизу
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
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

          // Inner highlight (верхний свет)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
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

          // Inner shadow (нижняя тень)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
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

          // Контент
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.27,
                    color: Colors.white.withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: size * 0.27,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
