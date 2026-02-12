import 'package:flutter/material.dart';

class MetalNavItem {
  final String iconPath;
  final String? label; // Опционально, но по умолчанию не используется

  MetalNavItem({required this.iconPath, this.label});
}

class MetalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MetalNavItem> items;

  const MetalBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121212), Color(0xFF181818), Color(0xFF101010)],
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
      child: Stack(
        children: [
          // Текстура графита (покрывает весь элемент)
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/textures/graphite_noise.png',
                fit: BoxFit.cover,
                width: double.infinity,
                color: Colors.white.withOpacity(0.05),
                colorBlendMode: BlendMode.softLight,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Затемнение сверху и снизу
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4), // Затемнение сверху
                      Colors.transparent, // Прозрачный в центре
                      Colors.black.withOpacity(0.6), // Затемнение снизу
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Затемнение слева и справа
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.3), // Затемнение слева
                      Colors.transparent, // Прозрачный в центре
                      Colors.black.withOpacity(0.3), // Затемнение справа
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Легкое свечение сверху по центру (цвет #C5D09D)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 7,
                    colors: [
                      const Color(
                        0xFFC5D09D,
                      ).withOpacity(0.15), // Более яркое свечение
                      const Color(0xFFC5D09D).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
              ),
            ),
          ),
          // Градиентная обводка сверху (цвет #C5D09D)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Color(0x80C5D09D), // мягкие края света
                      Color(0xFFC5D09D), // пик в центре
                      Color(0x80C5D09D),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Контент с padding
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(items.length, (index) {
                  final selected = index == currentIndex;
                  return Expanded(
                    child: _NavItem(
                      item: items[index],
                      selected: selected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final MetalNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = widget.selected ? _scaleAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Transform.translate(
              offset: const Offset(0, 6),
              child: Center(
                child: Image.asset(
                  widget.item.iconPath,
                  width: 30,
                  height: 30,
                  color: Colors.white.withOpacity(
                    widget.selected ? 0.95 : 0.45,
                  ),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
