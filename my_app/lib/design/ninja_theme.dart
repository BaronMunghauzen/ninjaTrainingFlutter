import 'package:flutter/material.dart';
import 'ninja_colors.dart';

class NinjaTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NinjaColors.bgPrimary,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: NinjaColors.accent,
        background: NinjaColors.bgPrimary,
        surface: NinjaColors.bgElevated,
      ),
    );
  }
}

