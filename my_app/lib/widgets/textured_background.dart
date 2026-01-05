import 'package:flutter/material.dart';

class TexturedBackground extends StatelessWidget {
  final Widget child;

  const TexturedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // 1. Базовый цвет + большой радиальный градиент
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [
                  Color(0xFF1B1B1D), // Center
                  Color(0xFF0B0B0C), // Edge
                ],
              ),
            ),
          ),

          // 2. Микротекстура (очень слабая)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/textures/graphite_noise.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
                color: Colors.grey,
                colorBlendMode: BlendMode.softLight,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

          // 3. Контент
          child,
        ],
      ),
    );
  }
}
