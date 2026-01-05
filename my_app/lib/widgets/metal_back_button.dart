import 'package:flutter/material.dart';

class MetalBackButton extends StatefulWidget {
  final VoidCallback? onTap;

  const MetalBackButton({super.key, this.onTap});

  @override
  State<MetalBackButton> createState() => _MetalBackButtonState();
}

class _MetalBackButtonState extends State<MetalBackButton> {
  bool _pressed = false;

  void _handleTap() async {
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _pressed = false);
      if (widget.onTap != null) {
        widget.onTap!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        decoration: _pressed
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2A2A2A),
                    Color(0xFF1F1F1F),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              )
            : null,
        child: Transform.translate(
          offset: _pressed ? const Offset(0, 1) : Offset.zero,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

