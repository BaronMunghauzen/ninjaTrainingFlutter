import 'package:flutter/material.dart';

class MetalToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String trueLabel;
  final String falseLabel;

  const MetalToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.trueLabel = 'Да',
    this.falseLabel = 'Нет',
  });

  @override
  State<MetalToggleSwitch> createState() => _MetalToggleSwitchState();
}

class _MetalToggleSwitchState extends State<MetalToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = widget.value ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(MetalToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animationController.animateTo(widget.value ? 1.0 : 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    final newValue = index == 1;
    if (newValue != widget.value) {
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // Фон как metal_button в нажатом состоянии
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF3E3E3E)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final tabWidth = containerWidth / 2;

          return Stack(
            children: [
              // Текстура графита
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/textures/graphite_noise.png',
                      fit: BoxFit.cover,
                      color: Colors.white.withOpacity(0.10),
                      colorBlendMode: BlendMode.softLight,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
              // Ползунок (активная вкладка)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final sliderLeft = _animation.value * (containerWidth - tabWidth);

                  return Positioned(
                    left: sliderLeft + 2, // 2 = margin
                    top: 2,
                    bottom: 2,
                    width: tabWidth - 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        // Ползунок как metal_button в idle состоянии
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
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
                          // Текстура графита для ползунка
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
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
                          // Легкое свечение сверху
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.topCenter,
                                      radius: 1.7,
                                      colors: [
                                        const Color(0xFFC5D09D)
                                            .withOpacity(0.32),
                                        const Color(0xFFC5D09D).withOpacity(0.0),
                                      ],
                                      stops: const [0.0, 0.6],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Градиентная обводка сверху
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 2,
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFFC5D09D)
                                            .withOpacity(0.5),
                                        const Color(0xFFC5D09D),
                                        const Color(0xFFC5D09D)
                                            .withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
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
                                borderRadius: BorderRadius.circular(10),
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
                          // Inner highlight
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
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
                          // Inner shadow
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Вкладки
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTap(0),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          widget.falseLabel,
                          style: TextStyle(
                            color: !widget.value
                                ? const Color(0xFFEDEDED)
                                : const Color(0xFFEDEDED).withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTap(1),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          widget.trueLabel,
                          style: TextStyle(
                            color: widget.value
                                ? const Color(0xFFEDEDED)
                                : const Color(0xFFEDEDED).withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}


