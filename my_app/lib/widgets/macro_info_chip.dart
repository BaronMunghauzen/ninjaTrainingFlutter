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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B1B1B),
            Color(0xFF262626),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.6),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.05),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
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
              fontSize: size * 0.34,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

