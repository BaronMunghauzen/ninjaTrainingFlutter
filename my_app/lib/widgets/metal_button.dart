import 'package:flutter/material.dart';

enum MetalButtonState { idle, pressed, disabled }

class MetalButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double? height;
  final bool isLoading;

  const MetalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height,
    this.isLoading = false,
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
    if (_pressed) {
      return MetalButtonState.pressed;
    }
    return MetalButtonState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? 56.0;
    final s = state;

    return GestureDetector(
      onTapDown: s == MetalButtonState.idle
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: s == MetalButtonState.pressed
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
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
              // Edge gradient (микроконтраст по краю) - только для idle
              if (s == MetalButtonState.idle)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.transparent,
                            Colors.black.withOpacity(0.25),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

              // Micro texture layer
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/textures/metal_textures.png',
                      repeat: ImageRepeat.repeat,
                      fit: BoxFit.none,
                      color: Colors.white.withOpacity(_textureOpacityFor(s)),
                      colorBlendMode: BlendMode.overlay,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),

              // Inner highlight (верхний свет) - только для idle
              if (s == MetalButtonState.idle)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          Icon(widget.icon, size: 20, color: _iconColorFor(s)),
                        ],
                        if (widget.icon != null || widget.isLoading)
                          const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: _textColorFor(s),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
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
      borderRadius: BorderRadius.circular(16),
      gradient: _gradientFor(s),
      boxShadow: _outerShadowsFor(s),
    );
  }

  LinearGradient _gradientFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.pressed:
        // Инвертированный градиент (свет снизу)
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C1C), Color(0xFF2A2A2A), Color(0xFF3A3A3A)],
        );

      case MetalButtonState.disabled:
        // Плоский градиент
        return const LinearGradient(
          colors: [Color(0xFF2B2B2B), Color(0xFF2B2B2B)],
        );

      case MetalButtonState.idle:
        // Свет сверху
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3A3A), Color(0xFF2A2A2A), Color(0xFF1C1C1C)],
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
        return 0.08;
    }
  }

  Color _textColorFor(MetalButtonState s) {
    switch (s) {
      case MetalButtonState.disabled:
        return const Color(0xFFEDEDED).withOpacity(0.4);
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
