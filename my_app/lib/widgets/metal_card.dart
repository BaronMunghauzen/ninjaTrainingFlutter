import 'package:flutter/material.dart';

class MetalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const MetalCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Stack(
      children: [
        // Градиент (нижний слой — общий тон и внешняя тень карточки)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E2E2E), Color(0xFF1E1E1E)],
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

        // Текстура (поверх градиента, масштабируется под размер карточки)
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/textures/graphite_noise.png',
                // Масштабируем картинку так, чтобы она заполняла всю карточку
                // (по большей стороне), при необходимости обрезая лишнее
                fit: BoxFit.cover,
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

        // Внутренняя «светотень» по вертикали — свет чуть выше центра карточки
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // Лёгкая тень у верхнего края, как будто грань
                      Colors.black.withOpacity(0.12),
                      // Максимальный свет чуть выше центра
                      Colors.white.withOpacity(0.07),
                      // Более глубокая тень внизу
                      Colors.black.withOpacity(0.20),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Градиентная обводка сверху (акцент по центру, цвет #D3D3C6, слегка мягче)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 2,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Color(0x66D3D3C6), // мягкие края света (чуть слабее)
                      Color(0xE0D3D3C6), // пик в центре, немного менее яркий
                      Color(0x66D3D3C6),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Внутренняя «светотень» по горизонтали — лёгкая тень по краям,
        // чтобы металл выглядел объёмным и слева/справа
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.50), // тень слева
                      Colors.transparent, // нейтральная зона в центре
                      Colors.black.withOpacity(0.55), // тень справа
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Контент (поверх всего)
        Container(padding: padding ?? const EdgeInsets.all(16), child: child),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
