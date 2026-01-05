import 'package:flutter/material.dart';
import 'ninja_colors.dart';

class NinjaGradients {
  static const metalVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      NinjaColors.metalLight,
      NinjaColors.metalMid,
      NinjaColors.metalDark,
    ],
  );

  static const metalSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E2E2E),
      Color(0xFF1C1C1C),
    ],
  );

  static const highlightTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x22FFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  static const bgDepth = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.2,
    colors: [
      Color(0x2200FF88),
      Colors.transparent,
    ],
  );

  // Графит градиент для карточек
  static const graphiteRadial = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      Color(0xFF2A2A2A),
      Color(0xFF1A1A1A),
      Color(0xFF0D0D0E),
    ],
  );
}

