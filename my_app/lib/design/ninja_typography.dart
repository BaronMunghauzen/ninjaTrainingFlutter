import 'package:flutter/material.dart';
import 'ninja_colors.dart';

class NinjaText {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: NinjaColors.textPrimary,
  );

  static const section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: NinjaColors.textSecondary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: NinjaColors.textPrimary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: NinjaColors.textMuted,
  );

  static const chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

