import 'package:flutter/material.dart';

class MetalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const MetalCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Stack(
      children: [
        // Градиент (нижний слой)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E2E2E),
                  Color(0xFF1E1E1E),
                ],
              ),
              boxShadow: [
                // Нижняя глубокая тень (объём)
                BoxShadow(
                  color: Colors.black.withOpacity(0.65),
                  offset: const Offset(0, 14),
                  blurRadius: 34,
                ),
                // Верхний свет — «контур»
                BoxShadow(
                  color: Colors.white.withOpacity(0.07),
                  offset: const Offset(0, -1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),

        // Текстура (поверх градиента, покрывает всю карточку)
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/textures/graphite_noise.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                color: Colors.white.withOpacity(0.04),
                colorBlendMode: BlendMode.softLight,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),

        // Контент (поверх всего)
        Container(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
