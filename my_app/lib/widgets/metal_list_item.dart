import 'package:flutter/material.dart';

class MetalListItem extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const MetalListItem({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  State<MetalListItem> createState() => _MetalListItemState();
}

class _MetalListItemState extends State<MetalListItem> {
  bool _pressed = false;

  void _handleTap() async {
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _pressed = false);
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _decoration(),
        child: Transform.translate(
          offset: _pressed ? const Offset(0, 1) : Offset.zero,
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.title,
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _pressed
            ? const [
                Color(0xFF1F1F1F),
                Color(0xFF2A2A2A),
              ]
            : const [
                Color(0xFF2A2A2A),
                Color(0xFF1F1F1F),
              ],
      ),
      boxShadow: _pressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ]
          : [
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
    );
  }
}
