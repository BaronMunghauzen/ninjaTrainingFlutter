import 'package:flutter/material.dart';

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? leftText;
  final String? rightText;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.leftText,
    this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (label != null) ...[
            Expanded(
              child: Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (leftText != null) ...[
            Text(
              leftText!,
              style: TextStyle(
                color: !value ? const Color(0xFF1F2121) : Colors.grey[400],
                fontSize: 14,
                fontWeight: !value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF1F2121) : Colors.grey[600],
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          if (rightText != null) ...[
            const SizedBox(width: 12),
            Text(
              rightText!,
              style: TextStyle(
                color: value ? const Color(0xFF1F2121) : Colors.grey[400],
                fontSize: 14,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
